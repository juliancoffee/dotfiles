" fish exotic
if &shell =~# 'fish$'
    set shell=sh
endif


" vim plug
call plug#begin()  "yes, there will be a plugins

" ------------------------------------------------------------
" Workflow plugins
"Plug 'Valloric/YouCompleteMe'
Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle' }  "improved file explorer
Plug 'tell-k/vim-autopep8'                             "python code autoformat
Plug 'dense-analysis/ale'                              "linter plugin
Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'} "completer plugin
Plug 'Shougo/echodoc.vim'                              " documentation to echo area
" language server client
Plug 'autozimu/LanguageClient-neovim', {
            \'branch': 'next',
            \'do': 'bash install.sh',
            \}
"Plug 'davidhalter/jedi-vim'                            " python completion
Plug 'racer-rust/vim-racer'                            " rust completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}        " VSCode like completion

" ------------------------------------------------------------

" ------------------------------------------------------------
" Colorshemes
Plug 'morhetz/gruvbox' "gruvbox colorscheme
" ------------------------------------------------------------

" ------------------------------------------------------------
" Syntax or language specific plugins
Plug 'neovimhaskell/haskell-vim'               "plugin to syntax haskell
Plug 'JuliaEditorSupport/julia-vim'            "plugin to julia-language
"Plug 'dcjones/julia-minimalist-vim'
Plug 'cespare/vim-toml'                        "plugin to highlight toml-files
Plug 'dag/vim-fish'                            "plugin to fish-files
Plug 'zah/nim.vim'                             "plugin to nim filej
Plug 'lcolaholicl/vim-v'                       "plugin to V language code
Plug 'ziglang/zig.vim'                         "plugin to Zig language code
"Plug 'wolfgangmehner/lua-support'              "plugin to lua-support
"Plug 'xolox/vim-lua-ftplugin'                  "plugin to Lua code
Plug 'xolox/vim-misc'                          "depencies for vim-lua
Plug 'vmchale/ion-vim'                         "plugin to ion shell
Plug 'vim-scripts/syntaxada.vim'               "plugin to ada language
Plug 'dart-lang/dart-vim-plugin'               "plugin to dart language
Plug 'wlangstroth/vim-racket'                  "plugin to racket language
Plug 'rhysd/vim-crystal'                       "plugin to crystal language
Plug 'elmcast/elm-vim'                         "plugin to elm language
Plug 'lilydjwg/colorizer'                      "plugin to higlight colors
" ------------------------------------------------------------

call plug#end()

map <C-t> :NERDTreeToggle<CR>
" ------------------------------------------------------------
"  Remaps
nnoremap <C-_> :noh<CR>
nnoremap gM :exe "tabedit ".expand('<cword>').'.c'
" ------------------------------------------------------------
set termguicolors
colorscheme muclor

set completeopt-=preview
set number             "numbers
set relativenumber
set tabstop=4   
set shiftwidth=4
set smarttab         "tabs
set expandtab
set smartindent

" ------------------------------------------------------------
" Language customize
" ------------------------------------------------------------
" Julia
autocmd BufRead,BufNewFile *.jl :set filetype=julia
" ------------------------------------------------------------
" Ada
let g:ada_standard_types = 1
" ------------------------------------------------------------
" OCaml
set rtp+=/home/julian/.opam/default/share/merlin/vim
helptags /home/julian/.opam/default/share/merlin/vim/doc

" ------------------------------------------------------------
" IDE
" ------------------------------------------------------------
" Ale linter
let g:ale_linters = {
            \'javascript': ['eslint'],
            \'python': ['flake8', 'mypy'],
            \'haskell': ['stack-ghc'],
            \'racket': ['raco'],
            \'fish': [],
            \}
" Deoplete
let g:deoplete#enable_at_startup = 1
" LanguageClient
"let g:LanguageClient_serverCommands = {
"            \ }
let g:LanguageClient_windowLogMessageLevel = "Log"
let g:LanguageClient_loggingFile = expand('~/.vim/LanguageClient.log')
let g:LanguageClient_hoverPreview = "Never"
let g:LanguageClient_useFloatingHover = 0
" Racer
" Coc.nvim
let g:css_filetypes = ['css']
