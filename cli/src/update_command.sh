REPO="https://github.com/xtheeq/msnap"
manifest="@MANIFEST_PATH@"
binary_path="${BASH_SOURCE[0]}"

nix_managed=false
[[ "$binary_path" == /nix/store/* ]] && nix_managed=true

if [[ "${args[--git]:-}" ]]; then
  use_git=true
  target_version=$(git ls-remote --heads "$REPO" main 2>/dev/null \
    | awk '{print $1}') \
    || { echo "Error: Could not reach GitHub. Check your internet connection." >&2; exit 1; }
  if [[ -z "$target_version" ]]; then
    echo "Error: Could not fetch latest commit from GitHub." >&2
    exit 1
  fi
elif [[ -n "${args[--version]:-}" ]]; then
  target_version="${args[--version]#v}"
else
  target_version=$(git ls-remote --tags --sort=version:refname "$REPO" 2>/dev/null \
    | grep -v '\^{}' \
    | tail -1 \
    | awk -F'refs/tags/v' '{print $2}') \
    || { echo "Error: Could not reach GitHub. Check your internet connection." >&2; exit 1; }
fi

if [[ "${args[--check]:-}" ]]; then
  if [[ "$version" == "$target_version" ]]; then
    echo "msnap is up to date (v${version})."
    exit 0
  else
    echo "Update available: v${version} -> v${target_version}"
    if [[ "$nix_managed" == true ]]; then
      echo "To update your Nix-managed install, run:" >&2
      echo "  nix flake update msnap  (in your system flake directory)" >&2
      echo "  nixos-rebuild switch" >&2
    fi
    exit 1
  fi
fi

if [[ "$nix_managed" == true ]]; then
  echo "Error: 'msnap update' is not supported for Nix-managed installations." >&2
  echo "To update, run:" >&2
  echo "  nix flake update msnap  (in your system flake directory)" >&2
  echo "  nixos-rebuild switch" >&2
  echo "" >&2
  echo "Tip: Use 'msnap update --check' to check for new versions without installing." >&2
  exit 1
fi

if [[ ! -f "$manifest" ]]; then
  echo "Error: No manifest found. Was msnap installed with 'make install'?" >&2
  exit 1
fi

if [[ "$version" == "$target_version" && -z "${args[--force]:-}" ]]; then
  echo "Already up to date (v${version}). Use --force to reinstall."
  exit 0
fi

bin_path=$(head -1 "$manifest")
if [[ ! -w "$(dirname "$bin_path")" ]]; then
  echo "Error: No write permission on $(dirname "$bin_path"). Try running with sudo." >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [[ "$use_git" == true ]]; then
  echo "Downloading msnap from commit ${target_version:0:7}..."
  curl -fsSL "${REPO}/archive/${target_version}.tar.gz" -o "${tmp}/msnap.tar.gz" \
    || { echo "Error: Download failed." >&2; exit 1; }
else
  echo "Downloading msnap v${target_version}..."
  curl -fsSL "${REPO}/archive/refs/tags/v${target_version}.tar.gz" -o "${tmp}/msnap.tar.gz" \
    || { echo "Error: Download failed." >&2; exit 1; }
fi

tar -xzf "${tmp}/msnap.tar.gz" -C "$tmp" \
  || { echo "Error: Failed to extract archive." >&2; exit 1; }

src="${tmp}/msnap-${target_version}"
[[ -d "$src" ]] || { echo "Error: Unexpected archive layout." >&2; exit 1; }

gui_dir=$(grep -m1 '\.qml$' "$manifest" | xargs dirname)
icon_file=$(grep -m1 'hicolor' "$manifest")
desktop_file=$(grep '\.desktop$' "$manifest")

new_manifest=$(mktemp)
echo "$bin_path" >> "$new_manifest"
if [[ -d "$src/gui" ]]; then
  find "$src/gui" -type f ! -name '*.conf' -print0 | sort -z \
    | while IFS= read -r -d '' f; do
        echo "${gui_dir}/${f#$src/gui/}"
      done >> "$new_manifest"
fi
[[ -n "$desktop_file" ]] && echo "$desktop_file" >> "$new_manifest"
echo "$icon_file" >> "$new_manifest"

while IFS= read -r old_file; do
  [[ "$old_file" == *.conf ]] && continue
  if ! grep -qxF "$old_file" "$new_manifest"; then
    rm -f "$old_file"
    echo "Removed obsolete: $old_file"
  fi
done < "$manifest"

echo "Installing..."
failed=0
while IFS= read -r dest; do
  case "$dest" in
    *.conf) ;;
    *.desktop)
      sed "s|@GUI_PATH@|${gui_dir}|g" "${src}/assets/msnap.desktop.in" \
        | sed "s|@ICON_PATH@|${icon_file}|g" \
        | install -m644 /dev/stdin "$dest" \
        || { echo "Warning: Failed to install $(basename "$dest")." >&2; ((failed++)) || true; continue; } ;;
    */hicolor/*)
      install -m644 "${src}/assets/icons/msnap.svg" "$dest" \
        || { echo "Warning: Failed to install $(basename "$dest")." >&2; ((failed++)) || true; continue; } ;;
    */msnap/gui/Config.qml)
      sed "s|@BIN_PATH@|${bin_path}|g" "${src}/gui/Config.qml" \
        | install -m644 /dev/stdin "$dest" \
        || { echo "Warning: Failed to install Config.qml." >&2; ((failed++)) || true; continue; } ;;
    */msnap/*)
      mkdir -p "$(dirname "$dest")"
      install -m644 "${src}/${dest#*/msnap/}" "$dest" \
        || { echo "Warning: Failed to install $(basename "$dest")." >&2; ((failed++)) || true; continue; } ;;
    *)
      sed -e "s|@GUI_PATH@|${gui_dir}|g" \
          -e "s|@VERSION@|${target_version}|g" \
          -e "s|@MANIFEST_PATH@|${manifest}|g" "${src}/cli/msnap" \
        | install -m755 /dev/stdin "$dest" \
        || { echo "Error: Failed to install binary." >&2; exit 1; } ;;
  esac
done < "$new_manifest"

if [[ -n "$gui_dir" ]]; then
  find "$(dirname "$gui_dir")" -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

# Preserve config file paths in manifest (not updated by this script)
while IFS= read -r old_file; do
  [[ "$old_file" == *.conf ]] && echo "$old_file" >> "$new_manifest"
done < "$manifest"

cp "$new_manifest" "$manifest"
rm -f "$new_manifest"

if (( failed > 0 )); then
  echo "Warning: $failed file(s) could not be installed (see above)." >&2
fi

# Update portal config
PORTAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal-wlr"
PORTAL_CONFIG="$PORTAL_DIR/config"
PORTAL_NEW="$src/assets/xdpw-config"
if [[ -f "$PORTAL_NEW" ]]; then
  if [[ -f "$PORTAL_CONFIG" ]]; then
    cp "$PORTAL_CONFIG" "$PORTAL_CONFIG.bak" 2>/dev/null
    echo "Backed up portal config to $PORTAL_CONFIG.bak"
  fi
  install -d "$PORTAL_DIR"
  install -m644 "$PORTAL_NEW" "$PORTAL_CONFIG"
  echo "Portal config updated."
  systemctl --user restart xdg-desktop-portal-wlr 2>/dev/null \
    || echo "Restart portal: systemctl --user restart xdg-desktop-portal-wlr"
fi

if [[ "$use_git" == true ]]; then
  echo "msnap updated to commit ${target_version:0:7}."
  notify-send "msnap updated" "Updated to commit ${target_version:0:7}" -a msnap 2>/dev/null || true
else
  echo "msnap updated to v${target_version}."
  notify-send "msnap updated" "Updated to v${target_version}" -a msnap 2>/dev/null || true
fi
