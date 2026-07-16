select_file="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR not set}/msnap-chooser"
preselect_file="${XDG_RUNTIME_DIR}/msnap-preselect"
trap 'rm -f "$select_file"' EXIT

if [[ -s "$preselect_file" ]]; then
  selected_id=$(<"$preselect_file")
  rm -f "$preselect_file" "$select_file"
  echo "Window: $selected_id"
  exit 0
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
  exit 1
fi

rm -f "$select_file"
qs -p "$TARGET_DIR/chooser.qml" >&2

if [[ ! -s "$select_file" ]]; then
  exit 1
fi

selected_id=$(<"$select_file")
echo "Window: $selected_id"
