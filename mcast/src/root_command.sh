set -euo pipefail

output_dir="${args[--output]:-${ini[output_dir]:-$HOME/Videos/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
backend="${args[--backend]:-${ini[backend]:-wf-recorder}}"
toggle_mode="${args[--toggle]:-}"

command -v "$backend" >/dev/null || { echo "Error: $backend not installed"; exit 1; }

recording_pid_file="/tmp/mcast.pid"
recording_filepath_file="/tmp/mcast.filepath"

build_cmd() {
  local geometry=""
  if [[ ${args[--region]:-} ]]; then
    geometry="$(slurp -d)" || { echo "Error: Failed to select region"; exit 1; }
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
        local x y w h
        IFS=',x ' read -r x y w h <<< "$geometry"
        local region_arg="-region ${w}x${h}+${x}+${y}"
        local capture_type="-w region"
        cmd="$backend $capture_type $region_arg -f 60 -o \"$filepath\""
      else
        cmd="$backend -w screen -f 60 -o \"$filepath\""
      fi
      ;;
    *)
      echo "Error: Unknown backend $backend"
      exit 1
      ;;
  esac
}

if [[ -n "$toggle_mode" ]]; then
  if [[ -f "$recording_pid_file" ]] && kill -0 "$(<"$recording_pid_file")" 2>/dev/null; then
    kill "$(<"$recording_pid_file")"
    rm -f "$recording_pid_file"
    if [[ -f "$recording_filepath_file" ]]; then
      filepath=$(<"$recording_filepath_file")
      rm -f "$recording_filepath_file"
      notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
    fi
  else
    filename="$(date +"$filename_pattern")"
    filepath="$output_dir/$filename"
    mkdir -p "$output_dir"
    echo "$filepath" > "$recording_filepath_file"

    build_cmd
    eval "$cmd > /dev/null 2>&1 &"
    echo $! > "$recording_pid_file"
  fi
else
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"

  build_cmd
  eval "$cmd"
  notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
fi
