#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OS=""
IS_MACOS=false
PACKAGE_MANAGER=""

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ==============================================================================
# OS DETECTION
# ==============================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        IS_MACOS=true
        OS="macos"
        if command -v brew >/dev/null 2>&1; then
            PACKAGE_MANAGER="brew"
        else
            log_error "Homebrew not found. Run setup-environment.sh first."
            exit 1
        fi
    elif [[ -n "${TERMUX_VERSION:-}" ]]; then
        OS="termux"
        PACKAGE_MANAGER="pkg"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="${ID:-unknown}"
        case "$OS" in
            ubuntu|debian)            PACKAGE_MANAGER="apt" ;;
            centos|rhel|rocky|almalinux)
                command -v dnf >/dev/null 2>&1 && PACKAGE_MANAGER="dnf" || PACKAGE_MANAGER="yum"
                ;;
            fedora)                   PACKAGE_MANAGER="dnf" ;;
            arch|manjaro|endeavouros) PACKAGE_MANAGER="pacman" ;;
            *)
                log_error "Unsupported distribution: $OS"
                exit 1
                ;;
        esac
    else
        log_error "Cannot detect OS."
        exit 1
    fi
    log_info "Detected: $OS (package manager: $PACKAGE_MANAGER)"
}

# ==============================================================================
# PACKAGE INSTALLATION / UPDATE
# ==============================================================================

# Try install first (no-op if already installed on most PMs), then upgrade.
install_or_upgrade_brew() {
    local pkg="$1"
    if brew list --formula "$pkg" >/dev/null 2>&1; then
        brew upgrade "$pkg" 2>/dev/null || true
    else
        brew install "$pkg"
    fi
}

install_update_packages() {
    log_info "Installing/updating core tools..."

    case $PACKAGE_MANAGER in
        brew)
            brew update
            for pkg in vim neovim tmux zsh; do
                install_or_upgrade_brew "$pkg"
            done
            # oh-my-posh
            if brew list jandedobbeleer/oh-my-posh/oh-my-posh >/dev/null 2>&1; then
                brew upgrade jandedobbeleer/oh-my-posh/oh-my-posh 2>/dev/null || true
            else
                brew install jandedobbeleer/oh-my-posh/oh-my-posh
            fi
            ;;
        apt)
            apt-get update -qq
            apt-get install -y vim neovim tmux zsh
            curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
            ;;
        dnf|yum)
            $PACKAGE_MANAGER install -y vim neovim tmux zsh
            curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
            ;;
        pacman)
            pacman -Syu --noconfirm vim neovim tmux zsh
            curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
            ;;
        pkg)
            pkg install -y vim neovim tmux zsh
            curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
            ;;
    esac

    log_success "Core tools ready"
}

# ==============================================================================
# STOW
# ==============================================================================

stow_package() {
    local package="$1"
    if [[ ! -d "$DOTFILES_DIR/$package" ]]; then
        log_warning "Package '$package' not found at $DOTFILES_DIR/$package, skipping"
        return
    fi

    local output
    if output=$(stow --restow -d "$DOTFILES_DIR" -t "$HOME" "$package" 2>&1); then
        log_success "Stowed: $package"
    else
        log_warning "Could not stow '$package' — conflict detected:"
        echo "$output"
        log_warning "  Resolve conflicts and re-run, or manually: stow --adopt -d $DOTFILES_DIR -t \$HOME $package"
    fi
}

stow_all() {
    log_info "Stowing dotfiles..."

    # Always stow these
    local packages=(nvim ohmyposh tmux vim zsh)

    # ghostty — only if the binary is present
    command -v ghostty >/dev/null 2>&1 && packages+=(ghostty)

    # kanata — only if the binary is present
    command -v kanata >/dev/null 2>&1 && packages+=(kanata)

    if [[ "$IS_MACOS" == true ]]; then
        # aerospace — only if installed
        command -v aerospace >/dev/null 2>&1 && packages+=(aerospace)
    else
        # hyprland — stow if binary exists (case-insensitive: hyprland or Hyprland)
        { command -v hyprland >/dev/null 2>&1 || command -v Hyprland >/dev/null 2>&1; } \
            && packages+=(hyprland) || true

        # waybar — only if installed
        command -v waybar >/dev/null 2>&1 && packages+=(waybar) || true
    fi

    for package in "${packages[@]}"; do
        stow_package "$package"
    done

    log_success "Dotfiles stowed"
}

# ==============================================================================
# ZSH — Oh My Zsh + plugins
# ==============================================================================

setup_zsh() {
    log_info "Setting up Zsh..."

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    else
        git -C "$HOME/.oh-my-zsh" pull --ff-only 2>/dev/null \
            && log_success "Oh My Zsh updated" \
            || log_warning "Oh My Zsh: pull skipped (local changes present?)"
    fi

    local ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        local dir="$ZSH_CUSTOM/plugins/$plugin"
        if [[ ! -d "$dir" ]]; then
            git clone "https://github.com/zsh-users/$plugin" "$dir"
            log_success "$plugin installed"
        else
            git -C "$dir" pull --ff-only 2>/dev/null \
                && log_success "$plugin updated" \
                || log_warning "$plugin: pull skipped (local changes present?)"
        fi
    done
}

# ==============================================================================
# TMUX — TPM + plugins
# ==============================================================================

install_tmux_plugins() {
    log_info "Setting up tmux plugins (TPM)..."

    local TPM_DIR="$HOME/.tmux/plugins/tpm"

    if [[ ! -d "$TPM_DIR" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        log_success "TPM installed"
    else
        git -C "$TPM_DIR" pull --ff-only 2>/dev/null \
            && log_success "TPM updated" \
            || log_warning "TPM: pull skipped (local changes present?)"
    fi

    "$TPM_DIR/bin/install_plugins" 2>/dev/null \
        && log_success "Tmux plugins installed" \
        || log_warning "Tmux plugin install encountered issues — open tmux and press prefix+I to install manually"

    "$TPM_DIR/bin/update_plugins" all 2>/dev/null \
        && log_success "Tmux plugins updated" \
        || log_warning "Tmux plugin update encountered issues"
}

# ==============================================================================
# VIM — vim-plug
# ==============================================================================

install_vim_plugins() {
    if ! command -v vim >/dev/null 2>&1; then
        log_warning "vim not found, skipping"
        return
    fi

    log_info "Setting up vim plugins (vim-plug)..."

    local PLUG_FILE="$HOME/.vim/autoload/plug.vim"
    if [[ ! -f "$PLUG_FILE" ]]; then
        curl -fLo "$PLUG_FILE" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log_success "vim-plug installed"
    fi

    vim +PlugUpgrade +PlugInstall +PlugUpdate +qall < /dev/null 2>/dev/null \
        && log_success "Vim plugins installed/updated" \
        || log_warning "Vim plugin install encountered issues — run :PlugInstall inside vim manually"
}

# ==============================================================================
# NEOVIM — lazy.nvim (+ LazyVim as a plugin)
# ==============================================================================

install_nvim_plugins() {
    if ! command -v nvim >/dev/null 2>&1; then
        log_warning "nvim not found, skipping"
        return
    fi

    log_info "Syncing neovim plugins (lazy.nvim)..."

    # lazy.nvim bootstraps itself from init.lua on first run.
    # `Lazy! sync` installs missing, updates all, and cleans removed plugins.
    nvim --headless -c "Lazy! sync" -c "qa" 2>/dev/null \
        && log_success "Neovim plugins synced" \
        || log_warning "lazy.nvim sync encountered issues — open nvim and run :Lazy sync manually"
}

# ==============================================================================
# MAIN
# ==============================================================================

show_help() {
    echo "Dotfiles Stow & Plugin Setup"
    echo "============================"
    echo "Stows appropriate config packages based on the current OS/environment,"
    echo "then installs and updates all editor/shell plugins."
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  (none)            Full run: packages + stow + plugins"
    echo "  --stow-only       Only stow dotfiles"
    echo "  --plugins-only    Only install/update plugins (zsh, tmux, vim, nvim)"
    echo "  --packages-only   Only install/update packages (vim, nvim, tmux, zsh, oh-my-posh)"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Packages stowed per platform:"
    echo "  Always:   nvim, ohmyposh, tmux, vim, zsh"
    echo "  If found: ghostty, kanata"
    echo "  macOS:    aerospace (if installed)"
    echo "  Linux:    hyprland, waybar (if installed)"
    echo ""
    echo "Note: on Linux, --packages-only requires root (sudo)."
}

run_plugins() {
    setup_zsh
    install_tmux_plugins
    install_vim_plugins
    install_nvim_plugins
}

main() {
    log_info "Starting dotfiles setup..."
    detect_os
    install_update_packages
    stow_all
    run_plugins
    log_success "All done! Restart your shell or run: exec zsh"
}

case "${1:-}" in
    --stow-only)
        detect_os
        stow_all
        ;;
    --plugins-only)
        detect_os
        run_plugins
        ;;
    --packages-only)
        detect_os
        install_update_packages
        ;;
    -h|--help)
        show_help
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
