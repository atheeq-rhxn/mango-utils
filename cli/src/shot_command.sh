if pgrep -x "slurp" >/dev/null; then
  echo "Screenshot selection already in progress." >&2
  exit 0
fi

if [[ ${args[--only-copy]} ]]; then
  filepath="$(mktemp -t msnap-XXXXXX.png)"
  find "$(dirname "$filepath")" -maxdepth 1 -name "msnap-*.png" -mmin +5 -delete 2>/dev/null &
else
  output_dir="${args[--output]:-${ini[shot_output_dir]:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}}"
  filename_pattern="${args[--filename]:-${ini[shot_filename_pattern]:-%Y%m%d%H%M%S.png}}"
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"
fi

cmd=(grim)

use_pointer=""
{ [[ ${ini[shot_pointer_default]} == true ]] || [[ ${args[--pointer]} ]]; } && use_pointer=true
[[ $use_pointer ]] && cmd+=(-c)

if [[ ${args[--window]} ]]; then
  if ! command -v mmsg >/dev/null 2>&1; then
    echo "missing dependency: mmsg (required for --window)" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "missing dependency: jq (required for --window)" >&2
    exit 1
  fi
  geometry=$(mmsg get focusing-client | jq -r '"\(.x),\(.y) \(.width)x\(.height)"')
  if [[ -z "$geometry" ]]; then
    echo "Error: No active window found or mmsg failed." >&2
    exit 1
  fi
  cmd+=(-g "$geometry")
elif [[ ${args[--geometry]} ]]; then
  cmd+=(-g "${args[--geometry]}")
else
  if ! command -v mmsg >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "missing dependency: mmsg and jq are required for screen capture" >&2
    exit 1
  fi
  geometry=$(mmsg get all-monitors | jq -r '.monitors[] | select(.active == true) | "\(.x),\(.y) \(.width * .scale | round)x\(.height * .scale | round)"')
  if [[ -z "$geometry" ]]; then
    echo "Error: No active monitor found." >&2
    exit 1
  fi
  cmd+=(-g "$geometry")
fi

if [[ ${args[--freeze]} ]]; then
  if ! command -v wayfreeze >/dev/null 2>&1; then
    echo "missing dependency: wayfreeze (required for --freeze)" >&2
    exit 1
  fi
  wayfreeze_cmd=(wayfreeze)
  [[ -z $use_pointer ]] && wayfreeze_cmd+=(--hide-cursor)
  trap 'kill $wayfreeze_pid 2>/dev/null || true; rm -f "$pipe"' EXIT
  pipe=$(mktemp -u).fifo
  mkfifo "$pipe"
  if [[ ${args[--region]} ]]; then
    "${wayfreeze_cmd[@]}" --after-freeze-timeout 100 --after-freeze-cmd "echo > $pipe" &
    wayfreeze_pid=$!
    read -r < "$pipe"
    geometry=$(slurp -d)
    if [[ -z "$geometry" ]]; then
      trap - EXIT
      kill $wayfreeze_pid 2>/dev/null || true
      rm -f "$pipe"
      exit 1
    fi
    "${cmd[@]}" -g "$geometry" "$filepath"
  else
    "${wayfreeze_cmd[@]}" --after-freeze-timeout 100 --after-freeze-cmd "echo > $pipe" &
    wayfreeze_pid=$!
    read -r < "$pipe"
    "${cmd[@]}" "$filepath"
  fi
  trap - EXIT
  kill $wayfreeze_pid 2>/dev/null || true
  rm -f "$pipe"
elif [[ ${args[--region]} ]]; then
  geometry=$(slurp -d)
  [[ -z "$geometry" ]] && exit 1
  "${cmd[@]}" -g "$geometry" "$filepath"
else
  "${cmd[@]}" "$filepath"
fi

if [[ ${args[--annotate]} ]]; then
  satty --filename "$filepath" --output-filename "$filepath" \
    --actions-on-enter save-to-file --early-exit --disable-notifications
fi

if [[ ${args[--only-copy]} ]]; then
  wl-copy < "$filepath"
  notify-send "Screenshot captured" "Image copied to the clipboard." \
    -i "$filepath" -a msnap
else
  if [[ ! ${args[--no-copy]} ]]; then
    wl-copy < "$filepath"
    message="Image saved in <i>${filepath}</i> and copied to the clipboard."
  else
    message="Image saved in <i>${filepath}</i>."
  fi
  notify_saved "$filepath" "$message" "shot"
fi
