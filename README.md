# msnap

Screenshot and screencast utility for [mangowm](https://github.com/mangowm/mango).

https://github.com/user-attachments/assets/53a4c616-3a6f-4400-ae9c-a15e277e710f

---

## Dependencies

| Tool | Purpose |
|------|---------|
| [`grim`](https://gitlab.freedesktop.org/emersion/grim) | Screenshot capture |
| [`slurp`](https://github.com/emersion/slurp) | Region selection |
| [`wl-copy`](https://github.com/bugaevc/wl-clipboard) | Clipboard |
| [`notify-send`](https://gitlab.gnome.org/GNOME/libnotify) | Notifications |
| [`wayfreeze`](https://github.com/Jappie3/wayfreeze) | Freeze screen before capture |
| [`satty`](https://github.com/gabm/Satty) | Annotation |
| [`gpu-screen-recorder`](https://git.dec05eba.com/gpu-screen-recorder/) | Screen recording |
| [`quickshell`](https://github.com/quickshell-mirror/quickshell) | GUI |
| [`ffmpeg`](https://git.ffmpeg.org/ffmpeg.git) | Recording thumbnail generation |

---

## Installation

### User install

```sh
git clone https://github.com/atheeq-rhxn/msnap.git
cd msnap
make install PREFIX=~/.local SYSCONFDIR=~/.config
```

> Ensure `~/.local/bin` is in your `$PATH`.

### System install

```sh
git clone https://github.com/atheeq-rhxn/msnap.git
cd msnap
sudo make install PREFIX=/usr
```

> `PREFIX=/usr` is recommended — icons and the desktop entry won't integrate correctly with `/usr/local`.

### NixOS install

Add msnap's input in `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    msnap = {
      url = "github:atheeq-rhxn/msnap";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Your other inputs...
  };
}
```

Install it by editing `configuration.nix`.
```nix
environment.systemPackages = with pkgs; [
  inputs.msnap.packages.${pkgs.system}.default
  # Your other packages
];
```

### Uninstall

```sh
sudo make uninstall PREFIX=/usr  # drop sudo for user install
```

---

## Usage

```sh
msnap shot [OPTIONS]   # take a screenshot
msnap cast [OPTIONS]   # record the screen
```

### `msnap shot`

| Flag | Argument | Description |
|------|----------|-------------|
| *(none)* | | Full screen |
| `-r`, `--region` | | Interactive region selection |
| `-g`, `--geometry` | `X,Y WxH` | Fixed geometry region |
| `-w`, `--window` | | Active window |
| `-p`, `--pointer` | | Include mouse pointer |
| `-a`, `--annotate` | | Open in Satty after capture |
| `-F`, `--freeze` | | Freeze screen before capturing |
| `-o`, `--output` | `DIR` | Output directory |
| `-f`, `--filename` | `NAME` | Output filename or pattern |
| `-n`, `--no-copy` | | Skip clipboard |
| `-c`, `--only-copy` | | Clipboard only, don't save file |

### `msnap cast`

| Flag | Argument | Description |
|------|----------|-------------|
| *(none)* | | Full screen |
| `-r`, `--region` | | Interactive region selection |
| `-g`, `--geometry` | `X,Y WxH` | Fixed geometry region |
| `-t`, `--toggle` | | Toggle recording on/off |
| `-a`, `--audio` | | Record system audio |
| `-m`, `--mic` | | Record microphone |
| `-A`, `--audio-device` | `DEVICE` | System audio device (default: `default_output`) |
| `-M`, `--mic-device` | `DEVICE` | Microphone device (default: `default_input`) |
| `-o`, `--output` | `DIR` | Output directory |
| `-f`, `--filename` | `NAME` | Output filename or pattern |

---

## GUI

Launch from your application launcher, or directly:

```sh
msnap gui
```

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `H` / `L` | Navigate capture modes |
| `J` / `K` | Switch between Screenshot and Record |
| `Tab` | Toggle mode |
| `Enter` / `Space` | Execute |
| `P` | Toggle pointer *(screenshot only)* |
| `E` | Toggle annotation *(screenshot only)* |
| `A` | Toggle system audio *(recording only)* |
| `M` | Toggle microphone *(recording only)* |
| `Escape` | Close / stop recording |

While recording, a red indicator appears in the top-right corner — click it to stop.

---

## Configuration

Config files live in `$XDG_CONFIG_HOME/msnap/` (default: `~/.config/msnap/`).

### `msnap.conf`

| Key | Default | Description |
|-----|---------|-------------|
| `shot_output_dir` | `~/Pictures/Screenshots` | Screenshot save directory |
| `shot_filename_pattern` | `%Y%m%d%H%M%S.png` | Screenshot filename pattern |
| `shot_pointer_default` | `false` | Include pointer by default |
| `cast_output_dir` | `~/Videos/Screencasts` | Recording save directory |
| `cast_filename_pattern` | `%Y%m%d%H%M%S.mp4` | Recording filename pattern |

### `gui.conf`

Controls GUI theme (colors, accents, alphas) and `quick_capture` behaviour.

### Value precedence

Options resolve in this order (highest first):

1. CLI flags
2. `msnap.conf`
3. XDG env vars (`XDG_PICTURES_DIR`, `XDG_VIDEOS_DIR`)
4. Built-in defaults

---

## XDG paths

msnap follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/). Config is resolved from `$XDG_CONFIG_HOME/msnap/` first, falling back to `$XDG_CONFIG_DIRS/msnap/`.

| Component | User install | System install |
|-----------|--------------|----------------|
| CLI | `~/.local/bin/msnap` | `/usr/bin/msnap` |
| Config | `~/.config/msnap/` | `/etc/xdg/msnap/` |
| GUI | `~/.local/share/msnap/gui/` | `/usr/share/msnap/gui/` |
| Desktop entry | `~/.local/share/applications/msnap.desktop` | `/usr/share/applications/msnap.desktop` |
| Icon | `~/.local/share/icons/.../msnap.svg` | `/usr/share/icons/.../msnap.svg` |

---

## mango integration

Example keybinds for mango:

```ini
bind=none,Print,spawn,msnap gui
bind=SHIFT,Print,spawn_shell,msnap shot --region
bind=ALT,Print,spawn_shell,msnap cast --toggle --region
```

To prevent the GUI from being animated or blurred:

```ini
layerrule = layer_name:msnap, noanim:1, noblur:1
```
