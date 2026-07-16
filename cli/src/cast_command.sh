output_dir="${args[--output]:-${ini[cast_output_dir]:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[cast_filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
quality="${args[--quality]:-${ini[cast_quality]:-}}"
video_codec="${args[--codec]:-${ini[cast_codec]:-}}"
frame_rate="${args[--framerate]:-${ini[cast_framerate]:-}}"
audio_codec="${args[--audio-codec]:-${ini[cast_audio_codec]:-}}"
color_range="${args[--color-range]:-${ini[cast_color_range]:-}}"
no_cursor="${args[--no-cursor]:-${ini[cast_cursor]:-}}"
resolution="${args[--resolution]:-${ini[cast_resolution]:-}}"
container="${args[--container]:-${ini[cast_container]:-}}"
tune="${args[--tune]:-${ini[cast_tune]:-}}"
recording_pid_file="/tmp/msnap-cast.pid"
recording_filepath_file="/tmp/msnap-cast.filepath"

build_cmd() {
  local geometry=""
  if [[ ${args[--geometry]:-} ]]; then
    geometry="${args[--geometry]}"
  elif [[ ${args[--region]:-} ]]; then
    geometry="$(slurp -d)" || { echo "Error: Failed to select region" >&2; exit 1; }
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
  fi
  if command -v gpu-screen-recorder > /dev/null 2>&1; then
    cmd=(gpu-screen-recorder)
  elif command -v flatpak > /dev/null 2>&1 && flatpak list --app 2>/dev/null | grep -q "com.dec05eba.gpu_screen_recorder"; then
    cmd=(flatpak run --command=gpu-screen-recorder com.dec05eba.gpu_screen_recorder)
  else
    echo "Error: gpu-screen-recorder not found" >&2
    exit 1
  fi
  if [[ ${args[--portal]:-} ]]; then
    cmd+=(-w portal)
  elif [[ -n "$geometry" ]]; then
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
  [[ -n "$quality" ]]     && cmd+=(-q "$quality")
  [[ -n "$video_codec" ]] && cmd+=(-k "$video_codec")
  [[ -n "$frame_rate" ]]  && cmd+=(-f "$frame_rate")
  [[ -n "$color_range" ]] && cmd+=(-cr "$color_range")
  [[ -n "$resolution" ]]  && cmd+=(-s "$resolution")
  [[ -n "$container" ]]   && cmd+=(-c "$container")
  [[ -n "$tune" ]]        && cmd+=(-tune "$tune")
  [[ -n "$no_cursor" ]]   && cmd+=(-cursor no)
  [[ -n "$audio_codec" ]] && cmd+=(-ac "$audio_codec")
  cmd+=(-o "$filepath")
}

if [[ -f "$recording_pid_file" ]]; then
  pkill -SIGINT -f "^(/nix/store/[^/]*-)?gpu-screen-recorder" 2>/dev/null || \
  pkill -SIGINT -f "^com\.dec05eba\.gpu_screen_recorder" 2>/dev/null || true
  (sleep 5 && pkill -9 -f "^(/nix/store/[^/]*-)?gpu-screen-recorder" 2>/dev/null; \
              pkill -9 -f "^com\.dec05eba\.gpu_screen_recorder" 2>/dev/null; true) &
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
