XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

IFS=':' read -ra _dirs <<< "$config_home:$XDG_CONFIG_DIRS"
for dir in "${_dirs[@]}"; do
  if [[ -f "$dir/msnap/msnap.conf" ]]; then
    ini_load "$dir/msnap/msnap.conf"
    break
  fi
done