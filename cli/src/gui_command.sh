if ! command -v qs &>/dev/null; then
  echo "Error: Quickshell (qs) is required for the GUI." >&2
  echo "Install quickshell, or use 'msnap shot' / 'msnap cast' for CLI-only operation." >&2
  exit 1
fi

USER_GUI_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/msnap/gui"
SYS_GUI_PATH="/usr/share/msnap/gui"
INJECTED_GUI_PATH="@GUI_PATH@"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOCAL_GUI_PATH="$REPO_ROOT/gui"

if [[ "$INJECTED_GUI_PATH" != "@"*GUI_PATH@ && -d "$INJECTED_GUI_PATH" ]]; then
  TARGET_DIR="$INJECTED_GUI_PATH"
elif [[ -d "$USER_GUI_PATH" ]]; then
  TARGET_DIR="$USER_GUI_PATH"
elif [[ -d "$SYS_GUI_PATH" ]]; then
  TARGET_DIR="$SYS_GUI_PATH"
elif [[ -d "$LOCAL_GUI_PATH" ]]; then
  TARGET_DIR="$LOCAL_GUI_PATH"
else
  echo "Error: Cannot find msnap GUI assets." >&2
  echo "Expected at $USER_GUI_PATH or $SYS_GUI_PATH" >&2
  exit 1
fi

XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
export MSNAP_GUI_CONFIG=""

IFS=':' read -ra _sys_dirs <<< "$XDG_CONFIG_DIRS"
for dir in "$config_home" "${_sys_dirs[@]}"; do
  if [[ -f "$dir/msnap/gui.conf" ]]; then
    export MSNAP_GUI_CONFIG="$dir/msnap/gui.conf"
    break
  fi
done

if [[ ${args['--no-freeze']} ]]; then
  export MSNAP_NO_FREEZE=1
fi

exec qs -p "$TARGET_DIR"
