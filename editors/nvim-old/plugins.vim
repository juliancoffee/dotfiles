" vim plug

" ------------------------------------------------------------
" Workflow plugins
"Plug 'Valloric/YouCompleteMe'
Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle' }  "improved file explorer
Plug 'tell-k/vim-autopep8'                             "python code autoformat
Plug 'Shougo/echodoc.vim'                              " documentation to echo area
"Plug 'davidhalter/jedi-vim'                            " python completion
" source ./deoplete-install.vim

" ------------------------------------------------------------

" ------------------------------------------------------------
" Colorshemes
Plug 'morhetz/gruvbox'                         "gruvbox colorscheme
Plug 'lilydjwg/colorizer'                      "plugin to higlight colors
" ------------------------------------------------------------

" ------------------------------------------------------------
"  Fancy things
Plug 'vim-airline/vim-airline'                 " airline
" ------------------------------------------------------------

" ------------------------------------------------------------
" Syntax or language specific plugins
Plug 'neovimhaskell/haskell-vim'               "plugin to syntax haskell
Plug 'JuliaEditorSupport/julia-vim'            "plugin to julia-language
"Plug 'dcjones/julia-minimalist-vim'
Plug 'cespare/vim-toml'                        "plugin to highlight toml-files
Plug 'dag/vim-fish'                            "plugin to fish-files
Plug 'zah/nim.vim'                             "plugin to nim filej
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
Plug 'reasonml-editor/vim-reason-plus'         "plugin to reasoml language
Plug 'ron-rs/ron.vim'                          "plugin for Rusty Object Notation
Plug 'tikhomirov/vim-glsl'                     "plugin for glsl syntax
Plug 'maxmellon/vim-jsx-pretty'                "plugin for JSX support
" ------------------------------------------------------------

" ------------------------------------------------------------
map <C-t> :NERDTreeToggle<CR>
let g:airline#extensions#tabline#enabled = 1
