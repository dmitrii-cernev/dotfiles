" Enable line numbers
set number

" Enable relative line numbers (optional but useful for movement)
set relativenumber

" Enable syntax highlighting
syntax on

" Enable filetype detection and plugin support
filetype plugin indent on

" Set tabs and indentation
set tabstop=4       " Number of spaces that a <Tab> in the file counts for
set shiftwidth=4    " Number of spaces to use for each step of (auto)indent
set expandtab       " Use spaces instead of tabs

" Enable auto-indenting
set autoindent
set smartindent

" Show matching parentheses/brackets
set showmatch

" Highlight search results
set hlsearch

" Incremental search (shows matches as you type)
set incsearch

" Ignore case in searches unless a capital letter is used
set ignorecase
set smartcase

" Display command being typed
set showcmd

" Set clipboard to use system clipboard (only works if Vim supports it)
set clipboard=unnamedplus

" Set a more useful backspace
set backspace=indent,eol,start

" Enable mouse support
set mouse=a

" Enable line wrapping (optional)
set wrap

" Show line and column number of the cursor
set ruler

" Keep 8 lines of context above/below cursor
set scrolloff=8

" Better command line completion
set wildmenu

" Disable audible bell
set noerrorbells
set visualbell

" Show partial commands in the last line of the screen
set showmode

" Persistent undo (requires undo directory)
set undofile
set undodir=~/.vim/undodir

" Set colorscheme (you can install others later)
colorscheme slate 

" Sync Vim and system clipboards
set clipboard^=unnamed,unnamedplus

" jump between angle brackets
set matchpairs+=<:>

" only if jq is available
if executable('jq')
    " put the ex-command + Enter into register “j”
    let @j = ":%!jq .\<CR>"
endif

" Initialize plugin system
call plug#begin('~/.vim/plugged')

" List your plugins here:
Plug 'junegunn/vim-plug'         " vim-plug itself
Plug 'chrisbra/csv.vim'

" Plug 'tpope/vim-fugitive'      " example: Git integration
" Plug 'scrooloose/nerdtree'     " example: file browser

call plug#end()
