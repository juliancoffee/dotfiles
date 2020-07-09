" fish exotic
if &shell =~# 'fish$'
    set shell=sh
endif

" ------------------------------------------------------------
" Plugins
source $HOME/.config/nvim/plugins.vim
" ------------------------------------------------------------
"  Remaps
source $HOME/.config/nvim/keys.vim
" ------------------------------------------------------------
" Options
" ------------------------------------------------------------
colorscheme muclor

set termguicolors
set completeopt-=preview
set number             "numbers
set relativenumber
set tabstop=4   
set shiftwidth=4
set smarttab         "tabs
set expandtab
set smartindent

" ------------------------------------------------------------
" Language customize that don't fit into ftplugin
" ------------------------------------------------------------
" Julia
autocmd BufRead,BufNewFile *.jl :set filetype=julia
" ------------------------------------------------------------
" Ada
let g:ada_standard_types = 1
" ------------------------------------------------------------
" OCaml
" set rtp+=/home/julian/.opam/default/share/merlin/vim
" helptags /home/julian/.opam/default/share/merlin/vim/doc

" ------------------------------------------------------------
" IDE like
" ------------------------------------------------------------
" Ale linter
source $HOME/.config/nvim/ale.vim
" Deoplete
" source $HOME/.config/nvim/deoplete.vim
" LanguageClient
" source $HOME/.config/nvim/language_client.vim
" Coc.nvim
source $HOME/.config/nvim/coc.vim
let g:css_filetypes = ['css']
