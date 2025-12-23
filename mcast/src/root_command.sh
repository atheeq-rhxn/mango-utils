output_dir="${args[--output]:-${ini[output_dir]:-$HOME/Videos/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
filename="$(date +"$filename_pattern")"
filepath="$output_dir/$filename"
mkdir -p "$output_dir"
if [[ ${args[--region]} ]]; then
  wf-recorder -g "$(slurp -d)" -f "$filepath"
else
  wf-recorder -f "$filepath"
fi
notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
