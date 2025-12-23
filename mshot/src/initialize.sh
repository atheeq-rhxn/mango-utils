config_dir="$HOME/.config/mango-capture"
config_file="$config_dir/mshot.conf"
if [[ ! -f "$config_file" ]]; then
  mkdir -p "$config_dir"
  cp "./mshot.conf" "$config_file"
fi
CONFIG_FILE="$config_file"
ini_load "$config_file"
