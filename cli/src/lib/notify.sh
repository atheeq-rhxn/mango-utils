notify_error() {
  local title="$1"
  local msg="$2"

  (
    notify-send "$title" "$msg" \
      -u critical \
      -i "video-x-generic" \
      -a "msnap"
  ) </dev/null >/dev/null 2>&1 &
}

notify_saved() {
  local fp="$1"
  local msg="$2"
  local type="$3"
  local skip_annotate="${4:-}"

  local title icon thumb=""
  if [[ "$type" == "shot" ]]; then
    title="Screenshot saved"
    icon="$fp"
  else
    title="Recording saved"
    thumb="$(mktemp --suffix=.jpg)"
    if ffmpeg -i "$fp" -vframes 1 -q:v 2 "$thumb" -y >/dev/null 2>&1; then
      icon="$thumb"
    else
      icon="video-x-generic"
      rm -f "$thumb"
      thumb=""
    fi
  fi

  local app="msnap"
  local notify_actions=(-A "open=Open File" -A "folder=Open Folder")
  [[ "$type" == "shot" && -z "${args[--annotate]}" && -z "$skip_annotate" ]] \
    && notify_actions+=(-A "annotate=Annotate")

  (
    local action
    action=$(notify-send "$title" "$msg" \
      -i "$icon" -a "$app" \
      "${notify_actions[@]}")

    [[ -n "$thumb" ]] && rm -f "$thumb"

    case "$action" in
      open)
        xdg-open "$fp" >/dev/null 2>&1 &
        ;;
      folder)
        xdg-open "$(dirname "$fp")" >/dev/null 2>&1 &
        ;;
      annotate)
        satty --filename "$fp" --output-filename "$fp" \
          --actions-on-enter save-to-file --early-exit --disable-notifications
        notify_saved "$fp" "Annotated image saved in <i>${fp}</i>." "shot" "skip"
        ;;
    esac
  ) </dev/null >/dev/null 2>&1 &
}
