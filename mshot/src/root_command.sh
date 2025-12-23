output_dir="${args[--output]:-${ini[output_dir]:-$HOME/Pictures/Screenshots}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.png}}"
filename="$(date +"$filename_pattern")"
filepath="$output_dir/$filename"
mkdir -p "$output_dir"
cmd="still"
pointer_default="${ini[pointer_default]:-false}"
pointer_enabled=false
if [[ $pointer_default == true ]] || [[ ${args[--pointer]} ]]; then
  pointer_enabled=true
fi
copy_enabled=true
if [[ ${args[--no-copy]} ]]; then
  copy_enabled=false
fi
window_capture=false
if [[ ${args[--window]} ]]; then
  window_capture=true
fi
if [[ $pointer_enabled == true ]]; then
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
if [[ $copy_enabled == true ]]; then
  wl-copy < "$filepath"
  message="Image saved in <i>${filepath}</i> and copied to the clipboard."
else
  message="Image saved in <i>${filepath}</i>."
fi
notify-send "Screenshot saved" "${message}" -i "${filepath}" -a mshot
