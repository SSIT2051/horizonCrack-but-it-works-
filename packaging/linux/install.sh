#!/usr/bin/env bash
# Horizon Launcher - One-click Linux installer
# Usage: curl -fsSL https://github.com/SSIT2051/horizonCrack-but-it-works-/releases/latest/download/install.sh | bash
# Or: curl -fsSL https://raw.githubusercontent.com/SSIT2051/horizonCrack-but-it-works-/main/packaging/linux/install.sh | bash

set -euo pipefail

REPO="SSIT2051/horizonCrack-but-it-works-"
INSTALL_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
APP_NAME="horizon-launcher"
BINARY_NAME="horizon-launcher"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[Horizon]${NC} $*"; }
success() { echo -e "${GREEN}[Horizon]${NC} $*"; }
warn() { echo -e "${YELLOW}[Horizon]${NC} $*"; }
error() { echo -e "${RED}[Horizon]${NC} $*" >&2; }

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) error "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
}

detect_libc() {
    if ldd --version 2>&1 | grep -q musl; then
        echo "musl"
    else
        echo "gnu"
    fi
}

get_latest_release() {
    local url="https://api.github.com/repos/${REPO}/releases/latest"
    if command -v curl >/dev/null; then
        curl -fsSL "$url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget >/dev/null; then
        wget -qO- "$url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        error "curl or wget required"
        exit 1
    fi
}

download_and_install() {
    local version="$1"
    local arch="$(detect_arch)"
    local libc="$(detect_libc)"
    
    local asset_name
    if [[ "$libc" == "musl" ]]; then
        asset_name="horizon-linux-musl-${arch}.tar.gz"
    else
        asset_name="horizon-linux-${arch}.tar.gz"
    fi
    
    local download_url="https://github.com/${REPO}/releases/download/${version}/${asset_name}"
    local tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    
    log "Downloading ${asset_name}..."
    if ! curl -fsSL -o "${tmpdir}/${asset_name}" "$download_url"; then
        error "Failed to download ${asset_name}"
        error "URL: ${download_url}"
        exit 1
    fi
    
    log "Extracting..."
    tar -xzf "${tmpdir}/${asset_name}" -C "$tmpdir"
    
    # Find the binary (could be in a subdirectory)
    local binary_path
    binary_path=$(find "$tmpdir" -name "$BINARY_NAME" -type f | head -1)
    if [[ -z "$binary_path" ]]; then
        error "Binary not found in archive"
        exit 1
    fi
    
    log "Installing to ${INSTALL_DIR}..."
    mkdir -p "$INSTALL_DIR"
    cp "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    
    # Install desktop entry
    log "Creating desktop entry..."
    mkdir -p "$DESKTOP_DIR"
    cat > "${DESKTOP_DIR}/${APP_NAME}.desktop" <<EOF
[Desktop Entry]
Name=Horizon Launcher
Comment=Minecraft: Java Edition launcher (Rust rewrite)
Exec=${INSTALL_DIR}/${BINARY_NAME}
Icon=horizon
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
EOF
    
    # Install icon
    log "Installing icon..."
    mkdir -p "$ICON_DIR"
    local icon_path
    icon_path=$(find "$tmpdir" -name "horizon.png" -type f | head -1)
    if [[ -n "$icon_path" ]]; then
        cp "$icon_path" "${ICON_DIR}/horizon.png"
    fi
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null; then
        gtk-update-icon-cache -f -t "$(dirname "$ICON_DIR")" 2>/dev/null || true
    fi
    
    success "Horizon Launcher installed successfully!"
    echo
    echo "Run it with: ${BINARY_NAME}"
    echo "Or find \"Horizon Launcher\" in your application menu."
    echo
    echo "Install location: ${INSTALL_DIR}/${BINARY_NAME}"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "Note: ${INSTALL_DIR} is not in your PATH"
        warn "Add this to your shell config (~/.bashrc, ~/.zshrc, etc.):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

main() {
    echo "╔══════════════════════════════════════╗"
    echo "║     Horizon Launcher Installer       ║"
    echo "║   Minecraft: Java Edition in Rust    ║"
    echo "╚══════════════════════════════════════╝"
    echo
    
    log "Fetching latest release..."
    local version
    version=$(get_latest_release)
    
    if [[ -z "$version" ]]; then
        error "Could not determine latest release"
        exit 1
    fi
    
    log "Latest version: ${version}"
    download_and_install "$version"
}

main "$@"