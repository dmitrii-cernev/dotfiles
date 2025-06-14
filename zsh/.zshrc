# ==============================================================================
# ZSH & OH-MY-ZSH CONFIGURATION
# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

# Local bin directory
export PATH="$HOME/.local/bin:$PATH"

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Java (if available)
if command -v java >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
    else
        # Linux - common paths
        for java_dir in /usr/lib/jvm/default-java /usr/lib/jvm/java-*-openjdk*; do
            if [ -d "$java_dir" ]; then
                export JAVA_HOME="$java_dir"
                break
            fi
        done
    fi
fi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ==============================================================================
# SHELL ENHANCEMENTS
# ==============================================================================

# Direnv (if available)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# Zoxide (better cd) - if available
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# FZF (if available)
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh) 2>/dev/null || true
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# TheFuck (if available)
if command -v thefuck >/dev/null 2>&1; then
    eval $(thefuck --alias)
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
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias battery='pmset -g batt | grep -o "[0-9]\{1,3\}%\|\d\+:\d\+"'
fi

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Format files with Biome (if available)
format() {
    if [ -z "$1" ]; then
        echo "Usage: format <file>"
        return 1
    fi
    
    if command -v npx >/dev/null 2>&1; then
        npx @biomejs/biome format --write "$1"
    else
        echo "npx not available. Please install Node.js and npm."
        return 1
    fi
}

# ==============================================================================
# EXTERNAL INTEGRATIONS
# ==============================================================================

# Google Cloud SDK (if available)
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then 
    . "$HOME/google-cloud-sdk/path.zsh.inc"
fi

if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then 
    . "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# ==============================================================================
# PROMPT CONFIGURATION (OH-MY-POSH)
# ==============================================================================

# Initialize Oh My Posh (skip for Apple Terminal, if available)
if command -v oh-my-posh >/dev/null 2>&1; then
    if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        if [ -f "$HOME/.config/ohmyposh/catppuccin.json" ]; then
            eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/catppuccin.json)"
        else
            eval "$(oh-my-posh init zsh)"
        fi
    fi

    # Oh My Posh Vi mode integration
    _omp_redraw_prompt() {
        local precmd
        for precmd in $precmd_functions; do
            $precmd
        done
        zle .reset-prompt
    }

    function _omp_zle-keymap-select() {
        if [[ $KEYMAP == vicmd ]]; then
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
        return $((128 + $1))
    }
fi
