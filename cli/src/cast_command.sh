output_dir="${args[--output]:-${ini[cast_output_dir]:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[cast_filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
recording_pid_file="/tmp/msnap-cast.pid"
recording_filepath_file="/tmp/msnap-cast.filepath"

build_cmd() {
  local geometry=""
  if [[ ${args[--geometry]:-} ]]; then
    geometry="${args[--geometry]}"
  elif [[ ${args[--region]:-} ]]; then
    geometry="$(slurp -d)" || { echo "Error: Failed to select region" >&2; exit 1; }
  fi
  cmd=(gpu-screen-recorder)
  if [[ -n "$geometry" ]]; then
    local x y w h
    IFS=',x ' read -r x y w h <<< "$geometry"
    cmd+=(-w region -region "${w}x${h}+${x}+${y}")
  else
    cmd+=(-w screen)
  fi
  if [[ ${args[--audio]:-} && ${args[--mic]:-} ]]; then
    cmd+=(-a "${args[--audio-device]:-default_output}|${args[--mic-device]:-default_input}")
  elif [[ ${args[--audio]:-} ]]; then
    cmd+=(-a "${args[--audio-device]:-default_output}")
  elif [[ ${args[--mic]:-} ]]; then
    cmd+=(-a "${args[--mic-device]:-default_input}")
  fi
  cmd+=(-o "$filepath")
}

if [[ -f "$recording_pid_file" ]]; then
  pkill -SIGINT -f "^gpu-screen-recorder"
  while pgrep -f "^gpu-screen-recorder" > /dev/null; do sleep 0.1; done
  rm -f "$recording_pid_file" "/tmp/msnap-cast.starttime"
  if [[ -f "$recording_filepath_file" ]]; then
    filepath=$(<"$recording_filepath_file")
    rm -f "$recording_filepath_file"
    notify_saved "$filepath" "Recording saved in <i>${filepath}</i>." "cast"
  fi
else
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"
  echo "$filepath" > "$recording_filepath_file"
  date +%s > "/tmp/msnap-cast.starttime"
  build_cmd
  "${cmd[@]}" > /dev/null 2>&1 &
  echo $! > "$recording_pid_file"
fi
