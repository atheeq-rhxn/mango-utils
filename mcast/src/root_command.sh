output_dir="${ini[output_dir]:-${args[--output]:-$HOME/Videos/Screencasts}}"
filename_pattern="${ini[filename_pattern]:-${args[--filename]:-%Y%m%d%H%M%S.mp4}}"
filename="$(date +"$filename_pattern")"
filepath="$output_dir/$filename"
mkdir -p "$output_dir"
if [[ ${args[--region]} ]]; then
  wf-recorder -g "$(slurp)" -f "$filepath"
else
  wf-recorder -f "$filepath"
fi
notify-send "Recording saved" "$filepath"