" Standalone, plugin-free Vim configuration based on the minimal Neovim setup.
set nocompatible
colorscheme slate
syntax on
filetype plugin indent on

set number
set relativenumber
set hidden
set path+=**
set wildmenu
set ignorecase
set smartcase
if has('clipboard')
    set clipboard=unnamedplus
endif

if executable('rg')
    set grepprg=rg\ --vimgrep\ --smart-case
    set grepformat=%f:%l:%c:%m
endif

let mapleader=" "

" Built-in file explorer, file search, buffers, and project search.
nnoremap <leader>e :Lexplore<CR>
nnoremap <leader>E :Lexplore %:p:h<CR>
nnoremap <leader>fo :find<Space>
nnoremap <leader>. :find<Space>
nnoremap <leader>fr :buffers<CR>:buffer<Space>
nnoremap <leader>/ :grep<Space>
nnoremap <leader>q :copen<CR>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bb <C-^>
nnoremap <leader>bl :ls<CR>
nnoremap <leader>bq :bd<CR>
nnoremap <leader>br :buffers<CR>:buffer<Space>

nnoremap <leader>wv <C-w>v<C-w>w
nnoremap <leader>ws <C-w>s<C-w>w
nnoremap <leader>wh <C-w>s<C-w>w
nnoremap <leader>ww <C-w>w
nnoremap <leader>wq <C-w>q
nnoremap <leader>wo :only<CR>

nnoremap <C-s> :w<CR>
nnoremap <leader>hrr :source $MYVIMRC<CR>

" Text search for the word under the cursor, not an LSP definition lookup.
nnoremap gd :vimgrep /<C-r><C-w>/ **/*<CR>:copen<CR>

" GUI-only: terminal font sizing belongs to the terminal emulator.
if has('gui_running')
    let g:font_size = 16
    set guifont=Consolas:h16

    function! ChangeFontSize(delta) abort
        let g:font_size = max([6, g:font_size + a:delta])
        execute 'set guifont=Consolas:h' . g:font_size
    endfunction

    nnoremap <C-=> :call ChangeFontSize(1)<CR>
    nnoremap <C--> :call ChangeFontSize(-1)<CR>
endif
