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
eval "$(brew shellenv)"
# Add Homebrew's site-functions to fpath
fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
source $ZSH/oh-my-zsh.sh

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

# Homebrew (M1 Mac)
export PATH=/opt/homebrew/bin:$PATH

# Flutter
export PATH="$PATH:/Users/dmitriicernev/flutter/bin"

# Pipx
export PATH="$PATH:/Users/dmitriicernev/.local/bin"

# PostgreSQL
export PATH="/usr/local/opt/libpq/bin:$PATH"

# IntelliJ IDEA
export PATH="/Applications/IntelliJ IDEA.app/Contents/MacOS:$PATH"

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 24.0.1)

# Go
export GOROOT=$(brew --prefix go)/libexec
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# ==============================================================================
# CONDA CONFIGURATION
# ==============================================================================

__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# ==============================================================================
# SHELL ENHANCEMENTS
# ==============================================================================

# Direnv
eval "$(direnv hook zsh)"

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# FZF
source <(fzf --zsh)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# TheFuck
eval $(thefuck --alias)

# Vi mode
set -o vi

# Kubectl completion
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# ==============================================================================
# ALIASES
# ==============================================================================

# Homebrew aliases (x86 vs ARM)
alias x86brew="arch -x86_64 /usr/local/bin/brew"
alias brew="/opt/homebrew/bin/brew"


# Battery status
alias battery='pmset -g batt | grep -o "[0-9]\{1,3\}%\|\d\+:\d\+"'
alias em='emacsclient -c -n -a "emacs"'

alias j='just'

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Format files with Biome
format() {
    if [ -z "$1" ]; then
        echo "Usage: format <file>"
    else
        npx @biomejs/biome format --write "$1"
    fi
}

# Start ecommerce project
start_ecom() {
    cd /Users/dmitriicernev/IdeaProjects/ecom-sync-engine || return
    direnv allow
    nohup idea . >/dev/null 2>&1 &
}

# ==============================================================================
# PROMPT CONFIGURATION (OH-MY-POSH)
# ==============================================================================

autoload -Uz compinit
compinit
# Initialize Oh My Posh (skip for Apple Terminal)
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/catppuccin.json)"
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
_omp_create_widget zle-keymap-select _omp_zle-keymap-select

function _omp_zle-line-finish() {
    export POSH_VI_MODE=insert
}
_omp_create_widget zle-line-finish _omp_zle-line-finish

# Reset to insert mode on Ctrl-C
TRAPINT() {
    export POSH_VI_MODE=insert
    return $((128 + $1))
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# opencode
export PATH=/Users/dmitriicernev/.opencode/bin:$PATH
