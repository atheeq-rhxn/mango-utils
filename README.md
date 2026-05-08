# <img src="assets/icons/msnap.svg" width="28" height="28" alt="mango Logo" style="vertical-align: middle;"> msnap

Screenshot and screencast utility for [mango](https://github.com/mangowm/mango).

https://github.com/user-attachments/assets/99f3e8dc-77af-43d6-9601-2bddf4e31675

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

```sh
curl -fsSL https://raw.githubusercontent.com/xtheeq/msnap/main/install.sh | bash
```

The script will prompt for **user** or **system-wide** installation.

### NixOS install

Add msnap's input and overlay in your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    msnap = {
      url = "github:xtheeq/msnap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, msnap, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ msnap.overlays.default ]; }
        ./configuration.nix
      ];
    };
  };
}
```

Then add `msnap` to your packages in `configuration.nix`:

```nix
environment.systemPackages = [ pkgs.msnap ];
```

Or for a standalone try without installing:

```sh
nix run github:xtheeq/msnap -- shot
```

---

## Mango setup

### Keybinds

```ini
bind=none,Print,spawn,msnap gui
bind=SHIFT,Print,spawn_shell,msnap shot --region
bind=ALT,Print,spawn_shell,msnap cast --toggle --region
```

### Layer rule

To prevent the GUI from being animated or blurred:

```ini
layerrule = layer_name:msnap, noanim:1, noblur:1
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

`--toggle` is required — call it once to start recording, again to stop.

| Flag | Argument | Description |
|------|----------|-------------|
| `-t`, `--toggle` | | **Required.** Toggle recording on/off |
| `-r`, `--region` | | Interactive region selection |
| `-g`, `--geometry` | `X,Y WxH` | Fixed geometry region |
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

#### Mode selection
| Key | Action |
|-----|--------|
| `S` | Screenshot mode |
| `V` | Recording mode |
| `J` / `K` | Switch between Screenshot and Record |
| `Tab` | Toggle mode |

#### Capture target
| Key | Action |
|-----|--------|
| `H` / `L` | Navigate capture targets |
| `←` / `→` | Navigate capture targets |
| `R` | Region selection |
| `W` | Active window *(screenshot only)* |
| `F` | Full screen |

#### Options
| Key | Action |
|-----|--------|
| `P` | Toggle pointer *(screenshot only)* |
| `E` | Toggle annotation *(screenshot only)* |
| `M` | Toggle microphone *(recording only)* |
| `A` | Toggle system audio *(recording only)* |

#### Execution
| Key | Action |
|-----|--------|
| `Enter` / `Space` | Execute capture |
| `Escape` | Clear selection / Close |

### Mouse interactions

| Action | Result |
|--------|--------|
| Drag on background | Create new region selection |
| Click inside selection | Start moving selection |
| Click on corner handles | Resize selection |
| Right-click | Clear selection or cancel |
| Hover recording pill | Expand to show timer + stop button |
| Click recording pill | Stop recording |

---

## Configuration

Config files live in `$XDG_CONFIG_HOME/msnap/` (default: `~/.config/msnap/`).

### `msnap.conf`

| Key | Default | Description |
|-----|---------|-------------|
| `shot_output_dir` | `$XDG_PICTURES_DIR/Screenshots` or `~/Pictures/Screenshots` | Screenshot save directory |
| `shot_filename_pattern` | `%Y%m%d%H%M%S.png` | Screenshot filename pattern |
| `shot_pointer_default` | `false` | Include pointer by default |
| `cast_output_dir` | `$XDG_VIDEOS_DIR/Screencasts` or `~/Videos/Screencasts` | Recording save directory |
| `cast_filename_pattern` | `%Y%m%d%H%M%S.mp4` | Recording filename pattern |

> **Filename patterns** support standard `date` format tokens (`%Y`, `%m`, `%d`, `%H`, `%M`, `%S`, etc.)

### `gui.conf`

Controls GUI theme (colors, accents, and alphas):

All other options control colors and alpha values for the UI. See the default `gui.conf` for available options.

### Value precedence

Options resolve in this order (highest first):

1. CLI flags
2. `msnap.conf`
3. XDG env vars (`XDG_PICTURES_DIR`, `XDG_VIDEOS_DIR`)
4. Built-in defaults

### Notifications

After capturing, notifications provide quick actions:

| Action | Description |
|--------|-------------|
| **Open File** | Open the captured file |
| **Open Folder** | Open the containing folder |
| **Annotate** | Re-edit in Satty *(screenshot only)* |

Recordings include an auto-generated thumbnail in the notification.

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

## Updating

```sh
msnap update              # update to latest release
msnap update --git        # update to latest git commit (unreleased)
msnap update --check      # check for updates without installing
msnap update --version x.x.x  # install specific version
msnap update --force      # reinstall current version
```

> NOTE: Not supported for Nix-managed installs — use `nix flake update` instead.

---

## Uninstall

```sh
msnap uninstall        # interactive
msnap uninstall -f     # skip confirmation
```

> Nix-managed installs should use `nix-collect-garbage` or remove from `flake.nix`.
