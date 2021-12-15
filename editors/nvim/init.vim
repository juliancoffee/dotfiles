" fish exotic
if &shell =~# 'fish$'
    set shell=sh
endif

" ------------------------------------------------------------
" Plugins
call plug#begin()  "yes, there will be a plugins
source $HOME/.config/nvim/plugins.vim
" ------------------------------------------------------------
"  Remaps
source $HOME/.config/nvim/keys.vim
" ------------------------------------------------------------
" Options
" ------------------------------------------------------------

set termguicolors
set completeopt-=preview
set number             "numbers
set relativenumber
set tabstop=4   
set shiftwidth=4
set smarttab         "tabs
set expandtab
set smartindent
set exrc             " local config
set tabpagemax=500   " why this limit even exists?

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
"
" Plugins with options
" ------------------------------------------------------------
" *Code::Stats*
source $HOME/.config/nvim/code_stats.vim

" ------------------------------------------------------------
" IDE like
" ------------------------------------------------------------
" *ALE linter*
source $HOME/.config/nvim/ale.vim
" ------------------------------------------------------------
" *Deoplete*
" source $HOME/.config/nvim/deoplete.vim
" ------------------------------------------------------------
" *LanguageClient*
" source $HOME/.config/nvim/language_client.vim
" ------------------------------------------------------------
" *Coc.nvim*
source $HOME/.config/nvim/coc.vim
" ------------------------------------------------------------

" ------------------------------------------------------------
" Finita la comedia
call plug#end()
" colorshemes must be called after plug#end
colorscheme muclor
