#!/usr/bin/env bash
# Horizon Launcher - One-click Linux installer
# Usage: curl -fsSL https://raw.githubusercontent.com/SSIT2051/horizonCrack-but-it-works-/main/packaging/linux/install.sh | bash

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

# Get the latest launcher release (not game release)
# Launcher releases are tagged as launcher@X.Y.Z or launcher-vX.Y.Z
get_latest_launcher_release() {
    local url="https://api.github.com/repos/${REPO}/releases"
    local releases_json
    
    if command -v curl >/dev/null; then
        releases_json=$(curl -fsSL "$url?per_page=100")
    elif command -v wget >/dev/null; then
        releases_json=$(wget -qO- "$url?per_page=100")
    else
        error "curl or wget required"
        exit 1
    fi
    
    # Find the latest non-draft, non-prerelease launcher release
    # Launcher tags start with "launcher@" or "launcher-v"
    echo "$releases_json" | grep -E '"tag_name":\s*"launcher[@v]' | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

# Alternative: get latest release by checking tag names
get_latest_launcher_release_v2() {
    local url="https://api.github.com/repos/${REPO}/releases/latest"
    local tag_name
    
    if command -v curl >/dev/null; then
        tag_name=$(curl -fsSL "$url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command -v wget >/dev/null; then
        tag_name=$(wget -qO- "$url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        error "curl or wget required"
        exit 1
    fi
    
    # If the latest release is a launcher release, use it
    if [[ "$tag_name" =~ ^launcher[@v] ]]; then
        echo "$tag_name"
        return
    fi
    
    # Otherwise, search through releases for the latest launcher release
    local releases_url="https://api.github.com/repos/${REPO}/releases?per_page=100"
    local releases_json
    
    if command -v curl >/dev/null; then
        releases_json=$(curl -fsSL "$releases_url")
    elif command -v wget >/dev/null; then
        releases_json=$(wget -qO- "$releases_url")
    else
        error "curl or wget required"
        exit 1
    fi
    
    # Find first launcher release (they're ordered by creation date, newest first)
    echo "$releases_json" | grep -E '"tag_name":\s*"launcher[@v]' | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

download_and_install() {
    local version="$1"
    local arch="$(detect_arch)"
    
    # Launcher assets are named differently from game assets
    # Linux: horizon-launcher-linux-x86_64.tar.gz or horizon-launcher-linux-x86_64.AppImage
    # For musl, there's no separate launcher build yet
    local asset_name_tar="horizon-launcher-linux-${arch}.tar.gz"
    local asset_name_appimage="horizon-launcher-linux-${arch}.AppImage"
    
    local download_url_tar="https://github.com/${REPO}/releases/download/${version}/${asset_name_tar}"
    local download_url_appimage="https://github.com/${REPO}/releases/download/${version}/${asset_name_appimage}"
    # tmpdir must not be local so the EXIT trap can access it after function returns
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    
    # Try tar.gz first, then AppImage
    local asset_name=""
    local download_url=""
    local binary_path=""
    
    log "Downloading ${asset_name_tar}..."
    if curl -fsSL -o "${tmpdir}/${asset_name_tar}" "$download_url_tar" 2>/dev/null; then
        asset_name="$asset_name_tar"
        download_url="$download_url_tar"
        log "Extracting..."
        tar -xzf "${tmpdir}/${asset_name_tar}" -C "$tmpdir"
        
        # Find the binary (could be in a subdirectory)
        binary_path=$(find "$tmpdir" -name "$BINARY_NAME" -type f | head -1)
    else
        log "${asset_name_tar} not found, trying AppImage..."
        if curl -fsSL -o "${tmpdir}/${asset_name_appimage}" "$download_url_appimage" 2>/dev/null; then
            asset_name="$asset_name_appimage"
            download_url="$download_url_appimage"
            chmod +x "${tmpdir}/${asset_name_appimage}"
            binary_path="${tmpdir}/${asset_name_appimage}"
        else
            error "Failed to download launcher assets"
            error "Tried: ${download_url_tar}"
            error "Tried: ${download_url_appimage}"
            error "Version: ${version}"
            exit 1
        fi
    fi
    
    if [[ -z "$binary_path" ]] || [[ ! -f "$binary_path" ]]; then
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
    else
        # Try to extract icon from AppImage if we have one
        if [[ "$asset_name" == *.AppImage ]]; then
            cd "$tmpdir"
            ./"$asset_name_appimage" --appimage-extract horizon.png 2>/dev/null || true
            if [[ -f "squashfs-root/horizon.png" ]]; then
                cp "squashfs-root/horizon.png" "${ICON_DIR}/horizon.png"
            fi
        fi
        # If still no icon, download from repository
        if [[ ! -f "${ICON_DIR}/horizon.png" ]]; then
            log "Downloading icon from repository..."
            curl -fsSL -o "${ICON_DIR}/horizon.png" "https://raw.githubusercontent.com/${REPO}/main/packaging/icons/hicolor/256x256/apps/horizon.png" 2>/dev/null || true
        fi
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
    
    log "Fetching latest launcher release..."
    local version
    version=$(get_latest_launcher_release_v2)
    
    if [[ -z "$version" ]]; then
        error "Could not determine latest launcher release"
        error "Check https://github.com/${REPO}/releases for launcher releases"
        exit 1
    fi
    
    log "Latest launcher version: ${version}"
    download_and_install "$version"
}

main "$@"