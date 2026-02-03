" =============================================================================
" Vim config (ported from NixOS programs.vim.extraConfig)
" =============================================================================

" --- Leader key ---
let mapleader=" "

" --- UI ---
set number
set relativenumber

" Enable true color (safe to keep; may be ignored on some terminals/builds)
set termguicolors

" Sign column behavior (note: older Vim may not understand 'auto')
set signcolumn=auto

" Enable syntax and a simple built-in colorscheme
syntax on
colorscheme desert

" Transparent background (inherit terminal bg), do NOT change foregrounds
highlight Normal    guibg=NONE ctermbg=NONE
highlight NormalNC  guibg=NONE ctermbg=NONE
highlight NonText   guibg=NONE ctermbg=NONE

" Gutter/columns: transparent bg, keep readable numbers
highlight LineNr       guibg=NONE ctermbg=NONE guifg=#c8c8c8 ctermfg=White
highlight CursorLineNr guibg=NONE ctermbg=NONE guifg=#ffffff ctermfg=White
highlight SignColumn   guibg=NONE ctermbg=NONE
highlight FoldColumn   guibg=NONE ctermbg=NONE

" --- Indentation ---
set expandtab
set shiftwidth=2
set tabstop=2

" --- Mouse ---
set mouse=a

" --- Delete without copying (black-hole) ---
nnoremap d  "_d
xnoremap d  "_d
nnoremap dd "_dd

" --- Cut entire line to system clipboard (dx) ---
nnoremap dx "+dd

" --- Sane defaults ---
set ttyfast
set incsearch
set hlsearch
set ignorecase
set smartcase
set hidden
set noswapfile
set backspace=indent,eol,start
