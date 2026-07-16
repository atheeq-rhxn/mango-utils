manifest="@MANIFEST_PATH@"
binary_path="${BASH_SOURCE[0]}"

nix_managed=false
[[ "$binary_path" == /nix/store/* ]] && nix_managed=true

if [[ "$nix_managed" == true ]]; then
  echo "Error: 'msnap uninstall' is not supported for Nix-managed installations." >&2
  echo "To uninstall, remove 'msnap' from your Nix flake." >&2
  exit 1
fi

if [[ ! -f "$manifest" ]]; then
  echo "Error: No manifest found. Was msnap installed with 'make install'?" >&2
  exit 1
fi

if [[ -z "${args[--force]:-}" ]]; then
  file_count=$(wc -l < "$manifest")
  echo "This will remove $file_count files from your system."
  read -p "Continue? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Uninstalling..."
removed=0
failed=0
while IFS= read -r dest; do
  if [[ -f "$dest" ]]; then
    if rm -f "$dest"; then
      ((removed++)) || true
    else
      ((failed++)) || true
    fi
  fi
done < "$manifest"
echo "Removed $removed file(s)."

while IFS= read -r dest; do
  dir=$(dirname "$dest")
  find "$dir" -type d -empty -delete 2>/dev/null || true
done < <(sort -u "$manifest")

rm -f "$manifest" && echo "Removed manifest: $manifest" || echo "Failed to remove manifest: $manifest" >&2

PORTAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal-wlr/config"
if [[ -f "$PORTAL_CONFIG" ]] && grep -q "msnap chooser" "$PORTAL_CONFIG" 2>/dev/null; then
  if [[ -f "$PORTAL_CONFIG.bak" ]]; then
    if [[ -z "${args[--force]:-}" ]]; then
      read -p "Restore backup of portal config? [Y/n] " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        rm -f "$PORTAL_CONFIG"
        echo "Removed: $PORTAL_CONFIG"
      else
        mv "$PORTAL_CONFIG.bak" "$PORTAL_CONFIG"
        echo "Restored: $PORTAL_CONFIG"
      fi
    else
      mv "$PORTAL_CONFIG.bak" "$PORTAL_CONFIG"
      echo "Restored: $PORTAL_CONFIG"
    fi
    systemctl --user restart xdg-desktop-portal-wlr 2>/dev/null \
      || echo "Restart portal: systemctl --user restart xdg-desktop-portal-wlr"
  else
    if [[ -z "${args[--force]:-}" ]]; then
      read -p "Remove portal config? [y/N] " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$PORTAL_CONFIG"
        echo "Removed: $PORTAL_CONFIG"
        systemctl --user restart xdg-desktop-portal-wlr 2>/dev/null \
          || echo "Restart portal: systemctl --user restart xdg-desktop-portal-wlr"
      else
        echo "Skipped."
      fi
    else
      rm -f "$PORTAL_CONFIG"
      echo "Removed: $PORTAL_CONFIG"
      systemctl --user restart xdg-desktop-portal-wlr 2>/dev/null \
        || echo "Restart portal: systemctl --user restart xdg-desktop-portal-wlr"
    fi
  fi
fi

echo "msnap uninstalled."
