output_dir="${ini[output_dir]:-${args[--output]:-$HOME/Pictures/Screenshots}}"
filename_pattern="${ini[filename_pattern]:-${args[--filename]:-%Y%m%d%H%M%S.png}}"
filename="$(date +"$filename_pattern")"
filepath="$output_dir/$filename"
mkdir -p "$output_dir"
cmd="still"
cursor_default="${ini[cursor_default]:-false}"
cursor_enabled=false
if [[ $cursor_default == true ]] || [[ ${args[--cursor]} ]]; then
  cursor_enabled=true
fi
window_capture=false
if [[ ${args[--window]} ]]; then
  window_capture=true
fi
if [[ $cursor_enabled == true ]]; then
  cmd="$cmd -p"
fi
cmd="$cmd -c 'grim"
if [[ $window_capture == true ]]; then
  geometry=$(mmsg -x | awk '/x / {x=$3} /y / {y=$3} /width / {w=$3} /height / {h=$3} END {print x","y" "w"x"h}')
  if [[ -z "$geometry" ]]; then
    echo "Error: No active window found or mmsg failed." >&2
    exit 1
  fi
  cmd="$cmd -g \"$geometry\""
elif [[ ${args[--region]} ]]; then
  cmd="$cmd -g \"\$(slurp)\""
fi
cmd="$cmd \"$filepath\"'"
if [[ ${args[--annotate]} ]]; then
  cmd="$cmd && satty --filename \"$filepath\" --output-filename \"$filepath\" --actions-on-enter save-to-file --early-exit --disable-notifications"
fi
eval "$cmd"
notify-send "Screenshot saved" "$filepath"
