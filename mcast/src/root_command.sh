output_dir="${args[--output]:-${ini[output_dir]:-$HOME/Videos/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
backend="${args[--backend]:-${ini[backend]:-wf-recorder}}"
filename="$(date +"$filename_pattern")"
filepath="$output_dir/$filename"
mkdir -p "$output_dir"

command -v "$backend" >/dev/null || { echo "Error: $backend not installed"; exit 1; }

geometry=""
if [[ ${args[--region]} ]]; then
  geometry="$(slurp -d)"
fi

case "$backend" in
  wf-recorder)
    if [[ -n "$geometry" ]]; then
      cmd="$backend -g \"$geometry\" -f \"$filepath\""
    else
      cmd="$backend -f \"$filepath\""
    fi
    ;;
  wl-screenrec)
    if [[ -n "$geometry" ]]; then
      cmd="$backend -g \"$geometry\" -f \"$filepath\""
    else
      cmd="$backend -f \"$filepath\""
    fi
    ;;
  gpu-screen-recorder)
    if [[ -n "$geometry" ]]; then
      IFS=',x ' read x y w h <<< "$geometry"
      region_arg="-region ${w}x${h}+${x}+${y}"
      capture_type="-w region"
    else
      capture_type="-w screen"
      region_arg=""
    fi
    cmd="$backend $capture_type $region_arg -f 60 -o \"$filepath\""
    ;;
  *)
    echo "Error: Unknown backend $backend"
    exit 1
    ;;
esac
eval "$cmd"

notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
