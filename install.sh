#!/usr/bin/env bash
set -e

REPO="https://github.com/xtheeq/msnap"
TMP_DIR="$(mktemp -d -t msnap-install-XXXXXX)"

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; exit 1; }

run_quiet() {
    local output
    if ! output=$("$@" 2>&1); then
        echo -e "\n${RED}Error executing: $*${NC}"
        echo "$output"
        exit 1
    fi
}

cleanup() {
    [[ -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

check_deps() {
    info "Checking dependencies..."
    local missing=()
    for dep in grim slurp wl-copy notify-send qs gpu-screen-recorder ffmpeg; do
        command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing recommended dependencies: ${missing[*]}"
        echo "    Please install them via your package manager for full functionality."
    fi
}

get_install_type() {
    if [[ "$1" == "--system" ]]; then echo "system"; return; fi
    if [[ "$1" == "--user" ]]; then echo "user"; return; fi

    echo -e "\n${BOLD}Select Installation Scope:${NC}" >&2
    echo "  1) Current user only (~/.local) [Default]" >&2
    echo "  2) System-wide (/usr/local) [Requires sudo]" >&2
    echo "  3) Abort" >&2
    read -rp "Enter choice [1]: " choice </dev/tty >&2

    case "$choice" in
        2) echo "system" ;;
        3) echo "abort" ;;
        *) echo "user" ;;
    esac
}

fetch_source() {
    if [[ -f "Makefile" ]] && grep -q "msnap" Makefile; then
        echo "$PWD"
    else
        info "Downloading latest release..." >&2
        local version
        version=$(curl -s https://api.github.com/repos/xtheeq/msnap/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        [[ -z "$version" ]] && version="main"

        run_quiet curl -fsSL "${REPO}/archive/refs/tags/${version}.tar.gz" -o "${TMP_DIR}/src.tar.gz" || \
        run_quiet curl -fsSL "${REPO}/archive/refs/heads/main.tar.gz" -o "${TMP_DIR}/src.tar.gz"
        
        run_quiet tar -xzf "${TMP_DIR}/src.tar.gz" -C "$TMP_DIR" --strip-components=1
        echo "$TMP_DIR"
    fi
}

main() {
    echo -e "${BOLD}${GREEN}>>> msnap installer${NC}\n"
    check_deps

    local install_type
    install_type=$(get_install_type "$1")
    
    [[ "$install_type" == "abort" ]] && error "Installation aborted by user."

    echo ""

    local src_dir
    src_dir=$(fetch_source)
    cd "$src_dir" || error "Failed to access source directory."

    local make_args=()
    if [[ "$install_type" == "system" ]]; then
        make_args=(
            "PREFIX=/usr/local"
            "BINDIR=/usr/local/bin"
            "DATADIR=/usr/local/share"
            "SYSCONFDIR=/etc/xdg"
            "STATEDIR=/var/lib"
        )
    else
        make_args=(
            "PREFIX=$HOME/.local"
            "BINDIR=$HOME/.local/bin"
            "DATADIR=$HOME/.local/share"
            "SYSCONFDIR=$HOME/.config"
            "STATEDIR=$HOME/.local/state"
        )
    fi

    info "Preparing build environment..."
    rm -f msnap.desktop Config.qml.build msnap.build 2>/dev/null || \
    sudo rm -f msnap.desktop Config.qml.build msnap.build 2>/dev/null || true

    info "Building msnap..."
    run_quiet make build "${make_args[@]}"

    if [[ "$install_type" == "system" ]]; then
        info "Installing system-wide (may prompt for sudo)..."
        run_quiet sudo make install "${make_args[@]}"
    else
        info "Installing for current user..."
        run_quiet make install "${make_args[@]}"
        
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo ""
            warn "Please add \$HOME/.local/bin to your PATH in ~/.bashrc or ~/.zshrc"
        fi
    fi

    info "Cleaning up..."
    run_quiet make clean

    echo ""
    success "msnap installed successfully!"
    echo -e "    Run ${BOLD}msnap --help${NC} or ${BOLD}msnap gui${NC} to get started."
}

main "$@"
