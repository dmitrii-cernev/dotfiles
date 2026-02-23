#!/bin/bash

# ==============================================================================
# UNIVERSAL SHELL ENVIRONMENT SETUP SCRIPT
# ==============================================================================
# This script sets up zsh, oh-my-zsh, oh-my-posh, and various shell utilities
# Compatible with macOS (Homebrew), Ubuntu/Debian, and RHEL/CentOS/Fedora systems
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
OS=""
VERSION=""
PACKAGE_MANAGER=""
IS_MACOS=false
HAS_HOMEBREW=false
ACTUAL_USER=""
ACTUAL_HOME=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        IS_MACOS=true
        OS="macos"
        VERSION=$(sw_vers -productVersion)
        log_info "Detected macOS $VERSION"
        
        # Check for Homebrew
        if command -v brew >/dev/null 2>&1; then
            HAS_HOMEBREW=true
            PACKAGE_MANAGER="brew"
            log_info "Homebrew detected"
        else
            log_warning "Homebrew not found. Will install it first."
        fi
    elif [[ -n "${TERMUX_VERSION:-}" ]]; then
        OS="termux"
        VERSION="$TERMUX_VERSION"
        PACKAGE_MANAGER="pkg"
        log_info "Detected Termux (Android) $VERSION"
        return
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=${VERSION_ID:-}
        
        case $OS in
            ubuntu|debian)
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|rocky|almalinux)
                if command -v dnf >/dev/null 2>&1; then
                    PACKAGE_MANAGER="dnf"
                else
                    PACKAGE_MANAGER="yum"
                fi
                ;;
            fedora)
                PACKAGE_MANAGER="dnf"
                ;;
            *)
                log_error "Unsupported Linux distribution: $OS"
                exit 1
                ;;
        esac
        
        log_info "Detected Linux: $OS $VERSION (Package manager: $PACKAGE_MANAGER)"
    else
        log_error "Cannot detect OS. Unsupported system."
        exit 1
    fi
}

# Check if running as root (Linux only)
check_permissions() {
    if [[ "$IS_MACOS" == true ]]; then
        # On macOS, we don't need root for most operations
        return 0
    fi
    
    if [[ $EUID -ne 0 ]]; then
        log_error "On Linux, this script must be run as root (use sudo)"
        exit 1
    fi
}

# Get the actual user
get_actual_user() {
    if [[ "$IS_MACOS" == true ]]; then
        ACTUAL_USER="$USER"
        ACTUAL_HOME="$HOME"
    else
        if [[ -n "${SUDO_USER:-}" ]]; then
            ACTUAL_USER="$SUDO_USER"
            ACTUAL_HOME=$(eval echo ~"$SUDO_USER")
        else
            ACTUAL_USER="$USER"
            ACTUAL_HOME="$HOME"
        fi
    fi
    log_info "Setting up environment for user: $ACTUAL_USER"
}

# Install Homebrew on macOS
install_homebrew() {
    if [[ "$IS_MACOS" != true ]]; then
        return 0
    fi
    
    if [[ "$HAS_HOMEBREW" == true ]]; then
        log_info "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "$ACTUAL_HOME/.zprofile"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'export PATH="/usr/local/bin:$PATH"' >> "$ACTUAL_HOME/.zprofile"
    fi
    
    HAS_HOMEBREW=true
    PACKAGE_MANAGER="brew"
    log_success "Homebrew installed"
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    
    case $PACKAGE_MANAGER in
        brew)
            brew update && brew upgrade
            ;;
        apt)
            apt update && apt upgrade -y
            ;;
        dnf)
            dnf update -y
            ;;
        yum)
            yum update -y
            ;;
    esac
    
    log_success "System packages updated"
}

# Install basic packages
install_basic_packages() {
    log_info "Installing basic packages..."
    
    case $PACKAGE_MANAGER in
        brew)
            brew install curl wget git zsh tmux vim neovim stow
            ;;
        apt)
            apt install -y curl wget git zsh tmux vim neovim build-essential unzip stow
            ;;
        dnf)
            dnf install -y curl wget git zsh tmux vim neovim gcc gcc-c++ make unzip stow
            # Install EPEL for additional packages on RHEL-based systems
            if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
                dnf install -y epel-release
            fi
            ;;
        yum)
            yum install -y curl wget git zsh tmux vim neovim gcc gcc-c++ make unzip stow
            # Install EPEL for additional packages
            yum install -y epel-release
            ;;
    esac
    
    log_success "Basic packages installed"
}

# Run command as actual user
run_as_user() {
    if [[ "$IS_MACOS" == true ]]; then
        eval "$@"
    else
        sudo -u "$ACTUAL_USER" bash -c "$@"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."
    
    if [[ -d "$ACTUAL_HOME/.oh-my-zsh" ]]; then
        log_warning "Oh My Zsh already installed, skipping..."
        return
    fi
    
    # Download and install Oh My Zsh non-interactively
    run_as_user 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    
    log_success "Oh My Zsh installed"
}

# Install Zsh plugins
install_zsh_plugins() {
    log_info "Installing Zsh plugins..."
    
    local ZSH_CUSTOM="$ACTUAL_HOME/.oh-my-zsh/custom"
    
    # Install zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        run_as_user "git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_warning "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        run_as_user "git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_warning "zsh-syntax-highlighting already installed"
    fi
}

# Install Oh My Posh
install_oh_my_posh() {
    log_info "Installing Oh My Posh..."
    
    if command -v oh-my-posh >/dev/null 2>&1; then
        log_warning "Oh My Posh already installed, skipping..."
        return
    fi
    
    case $PACKAGE_MANAGER in
        brew)
            brew install jandedobbeleer/oh-my-posh/oh-my-posh
            ;;
        *)
            # Install Oh My Posh using the official installer
            curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
            ;;
    esac
    
    # Create config directory and download theme
    run_as_user "mkdir -p $ACTUAL_HOME/.config/ohmyposh"
    run_as_user "curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin.omp.json -o $ACTUAL_HOME/.config/ohmyposh/catppuccin.json"
    
    log_success "Oh My Posh installed"
}

# Install FZF
install_fzf() {
    log_info "Installing FZF..."
    
    if command -v fzf >/dev/null 2>&1; then
        log_warning "FZF already installed, skipping..."
        return
    fi
    
    case $PACKAGE_MANAGER in
        brew)
            brew install fzf
            # Install shell integration
            run_as_user "$(brew --prefix)/opt/fzf/install --all --no-bash --no-fish"
            ;;
        *)
            # Clone and install FZF
            run_as_user "git clone --depth 1 https://github.com/junegunn/fzf.git $ACTUAL_HOME/.fzf"
            run_as_user "$ACTUAL_HOME/.fzf/install --all --no-bash --no-fish"
            ;;
    esac
    
    log_success "FZF installed"
}

# Install Zoxide
install_zoxide() {
    log_info "Installing Zoxide..."
    
    if command -v zoxide >/dev/null 2>&1; then
        log_warning "Zoxide already installed, skipping..."
        return
    fi
    
    case $PACKAGE_MANAGER in
        brew)
            brew install zoxide
            ;;
        *)
            # Install Zoxide using the official installer
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            
            # Move to system path (Linux only)
            if [[ "$IS_MACOS" != true ]]; then
                if [[ -f "$ACTUAL_HOME/.local/bin/zoxide" ]]; then
                    mv "$ACTUAL_HOME/.local/bin/zoxide" /usr/local/bin/
                    log_success "Zoxide installed to /usr/local/bin/"
                else
                    log_warning "Zoxide installation location not found, it might be installed elsewhere"
                fi
            fi
            ;;
    esac
    
    log_success "Zoxide installed"
}

# Install Node Version Manager (nvm)
install_nvm() {
    log_info "Installing nvm..."

    if [[ -d "$ACTUAL_HOME/.nvm" ]]; then
        log_warning "nvm already installed, skipping..."
        return
    fi

    local NVM_INSTALL_SCRIPT
    NVM_INSTALL_SCRIPT=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    run_as_user "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_SCRIPT}/install.sh | bash"

    log_success "nvm installed"
    log_info "Run 'nvm install --lts' after restarting your shell to install Node.js"
}


# Install Tmux Plugin Manager (TPM)
install_tmux_plugin_manager() {
    log_info "Installing Tmux Plugin Manager (TPM)..."

    local TPM_DIR="$ACTUAL_HOME/.tmux/plugins/tpm"

    if [[ -d "$TPM_DIR" ]]; then
        log_warning "TPM already installed, skipping..."
        return
    fi

    run_as_user "git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
    
    log_success "TPM installed"
    log_info "You can now install tmux plugins by running 'tmux' and then pressing prefix + I (capital I)."
}

# Install vim-plug for Vim 
install_vim_plugin_manager() {
    log_info "Installing vim-plug for Vim"

    # For Vim
    local VIM_PLUG_DIR="$ACTUAL_HOME/.vim/autoload/plug.vim"
    if [[ ! -f "$VIM_PLUG_DIR" ]]; then
        run_as_user "curl -fLo $VIM_PLUG_DIR --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        log_success "vim-plug installed for Vim"
    else
        log_warning "vim-plug already installed for Vim"
    fi
}


# Install additional useful tools
install_additional_tools() {
    log_info "Installing additional useful tools..."
    
    case $PACKAGE_MANAGER in
        brew)
            # Install additional tools that are useful for development
            brew install direnv thefuck bat eza fd ripgrep jq
            ;;
        apt)
            apt install -y direnv bat fd-find ripgrep jq
            # thefuck needs to be installed via pip
            if command -v pip3 >/dev/null 2>&1; then
                pip3 install thefuck
            fi
            ;;
        dnf|yum)
            $PACKAGE_MANAGER install -y direnv bat fd-find ripgrep jq
            # thefuck needs to be installed via pip
            if command -v pip3 >/dev/null 2>&1; then
                pip3 install thefuck
            fi
            ;;
    esac
    
    log_success "Additional tools installed"
}

# Install lazydocker
install_lazydocker() {
    log_info "Installing lazydocker..."

    if command -v lazydocker >/dev/null 2>&1; then
        log_warning "lazydocker already installed, skipping..."
        return
    fi

    case $PACKAGE_MANAGER in
        brew)
            brew install lazydocker
            ;;
        *)
            run_as_user "curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
            ;;
    esac

    log_success "lazydocker installed"
}

# Install lnav
install_lnav() {
    log_info "Installing lnav..."

    if command -v lnav >/dev/null 2>&1; then
        log_warning "lnav already installed, skipping..."
        return
    fi

    case $PACKAGE_MANAGER in
        brew)
            brew install lnav
            ;;
        apt)
            if command -v snap >/dev/null 2>&1; then
                snap install lnav
            else
                log_warning "snap not available, skipping lnav install"
            fi
            ;;
        dnf|yum)
            curl -fsSL https://packagecloud.io/install/repositories/tstack/lnav/script.rpm.sh | bash
            $PACKAGE_MANAGER install -y lnav
            ;;
    esac

    log_success "lnav installed"
}

# Setup .zshrc file
setup_zshrc() {
    log_info "Setting up .zshrc file..."
    
    local ZSHRC_FILE="$ACTUAL_HOME/.zshrc"
    
    # Skip if .zshrc is a symlink (e.g. managed by stow)
    if [[ -L "$ZSHRC_FILE" ]]; then
        log_warning ".zshrc is a symlink (likely managed by stow), skipping overwrite"
        return
    fi

    # Backup existing .zshrc if it exists
    if [[ -f "$ZSHRC_FILE" ]]; then
        run_as_user "cp $ZSHRC_FILE $ZSHRC_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing .zshrc backed up"
    fi
    
    # Create new .zshrc with macOS-specific additions
    local HOMEBREW_PATH_CONFIG=""
    if [[ "$IS_MACOS" == true ]]; then
        HOMEBREW_PATH_CONFIG='
# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
elif [[ -f "/usr/local/bin/brew" ]]; then
    export PATH="/usr/local/bin:$PATH"
fi'
    fi
    
    run_as_user "cat > $ZSHRC_FILE" << EOF
# ==============================================================================
# ZSH & OH-MY-ZSH CONFIGURATION
# ==============================================================================

export ZSH="\$HOME/.oh-my-zsh"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================
$HOMEBREW_PATH_CONFIG

# Local bin directory
export PATH="\$HOME/.local/bin:\$PATH"

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Java (if available)
if command -v java >/dev/null 2>&1; then
    if [[ "\$OSTYPE" == "darwin"* ]]; then
        # macOS
        export JAVA_HOME=\$(/usr/libexec/java_home 2>/dev/null)
    else
        # Linux - common paths
        for java_dir in /usr/lib/jvm/default-java /usr/lib/jvm/java-*-openjdk*; do
            if [ -d "\$java_dir" ]; then
                export JAVA_HOME="\$java_dir"
                break
            fi
        done
    fi
fi

# Node Version Manager
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

# ==============================================================================
# SHELL ENHANCEMENTS
# ==============================================================================

# Direnv (if available)
if command -v direnv >/dev/null 2>&1; then
    eval "\$(direnv hook zsh)"
fi

# Zoxide (better cd) - if available
if command -v zoxide >/dev/null 2>&1; then
    eval "\$(zoxide init zsh)"
fi

# FZF (if available)
if command -v fzf >/dev/null 2>&1; then
    if [[ "\$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
        # macOS with Homebrew
        source "\$(brew --prefix)/opt/fzf/shell/completion.zsh" 2>/dev/null
        source "\$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" 2>/dev/null
    else
        # Linux or manual installation
        source <(fzf --zsh) 2>/dev/null || true
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    fi
fi

# TheFuck (if available)
if command -v thefuck >/dev/null 2>&1; then
    eval \$(thefuck --alias)
fi

# Vi mode
set -o vi

# Kubectl completion (if available)
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# ==============================================================================
# ALIASES
# ==============================================================================

# Battery status (macOS only)
if [[ "\$OSTYPE" == "darwin"* ]]; then
    alias battery='pmset -g batt | grep -o "[0-9]\{1,3\}%\|\d\+:\d\+"'
fi

# Better ls alternatives (if available)
if command -v exa >/dev/null 2>&1; then
    alias ls='exa'
    alias ll='exa -l'
    alias la='exa -la'
elif command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -l'
    alias la='eza -la'
fi

# Better cat (if available)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Format files with Biome (if available)
format() {
    if [ -z "\$1" ]; then
        echo "Usage: format <file>"
        return 1
    fi
    
    if command -v npx >/dev/null 2>&1; then
        npx @biomejs/biome format --write "\$1"
    else
        echo "npx not available. Please install Node.js and npm."
        return 1
    fi
}

# ==============================================================================
# EXTERNAL INTEGRATIONS
# ==============================================================================

# Google Cloud SDK (if available)
if [ -f "\$HOME/google-cloud-sdk/path.zsh.inc" ]; then 
    . "\$HOME/google-cloud-sdk/path.zsh.inc"
fi

if [ -f "\$HOME/google-cloud-sdk/completion.zsh.inc" ]; then 
    . "\$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# ==============================================================================
# PROMPT CONFIGURATION (OH-MY-POSH)
# ==============================================================================

# Initialize Oh My Posh (skip for Apple Terminal, if available)
if command -v oh-my-posh >/dev/null 2>&1; then
    if [ "\$TERM_PROGRAM" != "Apple_Terminal" ]; then
        if [ -f "\$HOME/.config/ohmyposh/catppuccin.json" ]; then
            eval "\$(oh-my-posh init zsh --config \$HOME/.config/ohmyposh/catppuccin.json)"
        else
            eval "\$(oh-my-posh init zsh)"
        fi
    fi

    # Oh My Posh Vi mode integration
    _omp_redraw_prompt() {
        local precmd
        for precmd in \$precmd_functions; do
            \$precmd
        done
        zle .reset-prompt
    }

    function _omp_zle-keymap-select() {
        if [[ \$KEYMAP == vicmd ]]; then
            export POSH_VI_MODE=command
        else
            export POSH_VI_MODE=insert
        fi
        _omp_redraw_prompt
    }
    
    # Create widget only if oh-my-posh is available
    if typeset -f _omp_create_widget >/dev/null 2>&1; then
        _omp_create_widget zle-keymap-select _omp_zle-keymap-select
    fi

    function _omp_zle-line-finish() {
        export POSH_VI_MODE=insert
    }
    
    if typeset -f _omp_create_widget >/dev/null 2>&1; then
        _omp_create_widget zle-line-finish _omp_zle-line-finish
    fi

    # Reset to insert mode on Ctrl-C
    TRAPINT() {
        export POSH_VI_MODE=insert
        return \$((128 + \$1))
    }
fi
EOF
    
    log_success ".zshrc file created"
}

# Change default shell to zsh
change_default_shell() {
    log_info "Changing default shell to zsh for user $ACTUAL_USER..."
    
    local ZSH_PATH
    ZSH_PATH=$(which zsh)
    
    if [[ "$IS_MACOS" == true ]]; then
        if ! grep -qF "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
    else
        # On Linux, add zsh to /etc/shells if not already there
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" >> /etc/shells
        fi
        
        # Change default shell
        chsh -s "$ZSH_PATH" "$ACTUAL_USER"
    fi
    
    log_success "Default shell changed to zsh"
}

# Create local bin directory
create_local_bin() {
    log_info "Creating local bin directory..."
    
    run_as_user "mkdir -p $ACTUAL_HOME/.local/bin"
    
    log_success "Local bin directory created"
}

# Install fonts for Oh My Posh (optional)
install_fonts() {
    log_info "Installing Nerd Fonts for Oh My Posh..."
    
    case $PACKAGE_MANAGER in
        brew)
            brew install --cask font-meslo-lg-nerd-font
            ;;
        *)
            # Download and install Meslo Nerd Font manually
            local FONT_DIR
            if [[ "$IS_MACOS" == true ]]; then
                FONT_DIR="$ACTUAL_HOME/Library/Fonts"
            else
                FONT_DIR="$ACTUAL_HOME/.local/share/fonts"
                run_as_user "mkdir -p $FONT_DIR"
            fi
            
            log_info "Downloading Meslo Nerd Font..."
            run_as_user "curl -fLo '$FONT_DIR/MesloLGS NF Regular.ttf' https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
            run_as_user "curl -fLo '$FONT_DIR/MesloLGS NF Bold.ttf' https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
            run_as_user "curl -fLo '$FONT_DIR/MesloLGS NF Italic.ttf' https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
            run_as_user "curl -fLo '$FONT_DIR/MesloLGS NF Bold Italic.ttf' https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
            
            # Update font cache on Linux
            if [[ "$IS_MACOS" != true ]]; then
                if command -v fc-cache >/dev/null 2>&1; then
                    run_as_user "fc-cache -fv"
                fi
            fi
            ;;
    esac
    
    log_success "Nerd Fonts installed"
}

# Main installation function
main() {
    log_info "Starting universal shell environment setup..."
    
    # Check prerequisites
    detect_os
    check_permissions
    get_actual_user
    
    # Install Homebrew on macOS if needed
    if [[ "$IS_MACOS" == true ]]; then
        install_homebrew
    fi
    
    # System setup
    update_system
    install_basic_packages
    create_local_bin
    
    # Shell setup
    install_oh_my_zsh
    install_zsh_plugins
    install_oh_my_posh
    
    # Tools installation
    install_fzf
    install_zoxide
    install_nvm
    install_additional_tools
    install_lazydocker
    install_lnav

    # Install plugin managers
    install_tmux_plugin_manager
    install_vim_plugin_manager

    # Configuration
    setup_zshrc
    change_default_shell
    
    # Optional: Install fonts
    read -p "Do you want to install Nerd Fonts for better Oh My Posh experience? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_fonts
    fi
    
    log_success "Universal environment setup completed!"
    
    if [[ "$IS_MACOS" == true ]]; then
        log_info "Please restart your terminal or run: exec zsh"
    else
        log_info "Please log out and log back in to start using zsh as your default shell."
        log_info "Or run: exec zsh"
    fi
    
    log_info "Note: If you installed fonts, you may need to configure your terminal to use 'MesloLGS NF' font for the best experience."
}

# Help function
show_help() {
    echo "Universal Shell Environment Setup Script"
    echo "========================================"
    echo "This script installs and configures:"
    echo "  - Zsh as default shell"
    echo "  - Oh My Zsh framework"
    echo "  - Oh My Posh prompt theme"
    echo "  - Zsh plugins (autosuggestions, syntax highlighting)"
    echo "  - FZF fuzzy finder"
    echo "  - Zoxide smart cd"
    echo "  - Tmux, Vim, Neovim"
    echo "  - nvm (Node Version Manager)"
    echo "  - Additional development tools (direnv, bat, ripgrep, etc.)
  - lazydocker (Docker TUI)
  - lnav (log file navigator)"
    echo "  - Optional: Nerd Fonts"
    echo ""
    echo "Supported systems:"
    echo "  - macOS (uses Homebrew)"
    echo "  - Ubuntu/Debian"
    echo "  - RHEL/CentOS/Fedora/Rocky/AlmaLinux"
    echo ""
    echo "Usage:"
    echo "  macOS: $0 [options]"
    echo "  Linux: sudo $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Note: On Linux, this script must be run with sudo privileges"
    echo "      On macOS, run as regular user (Homebrew will be installed if needed)"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
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
