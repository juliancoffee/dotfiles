" ==============================================================================
"   Name:        Muclor
"   Author:      Julian Coffee
"   Url:         https://github.com/juliancoffee/muclor.vim
"   License:     The MIT License (MIT)
"
"   A dark vim color scheme. Code based on onehalfdark from
"   github.com/sonph/onehalf
" ==============================================================================

set background=dark
highlight clear
syntax reset

let g:colors_name="onehalfdark"
let colors_name="onehalfdark"


let s:black       = { "gui": "#282c34", "cterm": "236" }
let s:red         = { "gui": "#e06c75", "cterm": "168" }
let s:green       = { "gui": "#98c379", "cterm": "114" }
let s:yellow      = { "gui": "#ffce80", "cterm": "184" }
let s:blue        = { "gui": "#61afef", "cterm": "75"  }
let s:purple      = { "gui": "#c678dd", "cterm": "176" }
let s:magenta     = { "gui": "#e700f7", "cterm": "13" }
let s:cyan        = { "gui": "#56b6c2", "cterm": "73"  }
let s:white       = { "gui": "#dcdfe4", "cterm": "188" }

let s:fg          = s:white
let s:bg          = s:black

let s:comment_fg  = { "gui": "#5c6370", "cterm": "241" }
let s:gutter_bg   = { "gui": "#282c34", "cterm": "236" }
let s:gutter_fg   = { "gui": "#919baa", "cterm": "247" }

let s:cursor_line = { "gui": "#313640", "cterm": "237" }
let s:color_col   = { "gui": "#313640", "cterm": "237" }

let s:selection   = { "gui": "#474e5d", "cterm": "239" }
let s:vertsplit   = { "gui": "#313640", "cterm": "237" }


function! s:h(group, fg, bg, attr)
  if type(a:fg) == type({})
    exec "hi " . a:group . " guifg=" . a:fg.gui . " ctermfg=" . a:fg.cterm
  else
    exec "hi " . a:group . " guifg=NONE cterm=NONE"
  endif
  if type(a:bg) == type({})
    exec "hi " . a:group . " guibg=" . a:bg.gui . " ctermbg=" . a:bg.cterm
  else
    exec "hi " . a:group . " guibg=NONE ctermbg=NONE"
  endif
  if a:attr != ""
    exec "hi " . a:group . " gui=" . a:attr . " cterm=" . a:attr
  else
    exec "hi " . a:group . " gui=NONE cterm=NONE"
  endif
endfun


" User interface colors {
call s:h("Normal", s:fg, s:bg, "")
call s:h("NonText", s:fg, "", "")

call s:h("Cursor", s:bg, s:blue, "")
call s:h("CursorColumn", "", s:cursor_line, "")
call s:h("CursorLine", "", s:cursor_line, "")

call s:h("LineNr", s:gutter_fg, s:gutter_bg, "")
call s:h("CursorLineNr", s:fg, "", "")

call s:h("DiffAdd", s:green, "", "")
call s:h("DiffChange", s:yellow, "", "")
call s:h("DiffDelete", s:red, "", "")
call s:h("DiffText", s:blue, "", "")

call s:h("IncSearch", s:bg, s:yellow, "")
call s:h("Search", s:bg, s:yellow, "")

call s:h("ErrorMsg", s:fg, "", "")
call s:h("ModeMsg", s:fg, "", "")
call s:h("MoreMsg", s:fg, "", "")
call s:h("WarningMsg", s:red, "", "")
call s:h("Question", s:purple, "", "")

call s:h("Pmenu", s:fg, s:selection, "")
call s:h("PmenuSel", s:fg, s:blue, "")
call s:h("PmenuSbar", "", s:selection, "")
call s:h("PmenuThumb", "", s:fg, "")

call s:h("SpellBad", s:red, s:cursor_line, "underline")
call s:h("SpellCap", s:yellow, s:cursor_line, "underline")
call s:h("SpellLocal", s:yellow, "", "")
call s:h("SpellRare", s:yellow, "", "")

call s:h("StatusLine", s:blue, s:cursor_line, "")
call s:h("StatusLineNC", s:comment_fg, s:cursor_line, "")
call s:h("TabLine", s:comment_fg, s:cursor_line, "")
call s:h("TabLineFill", s:comment_fg, s:cursor_line, "")
call s:h("TabLineSel", s:fg, s:bg, "")

call s:h("Visual", "", s:selection, "")
call s:h("VisualNOS", "", s:selection, "")

call s:h("ColorColumn", "", s:color_col, "")
call s:h("Conceal", s:fg, "", "")
call s:h("Directory", s:blue, "", "")
call s:h("VertSplit", s:vertsplit, s:vertsplit, "")
call s:h("Folded", s:fg, "", "")
call s:h("FoldColumn", s:fg, "", "")
call s:h("SignColumn", s:fg, "", "")

call s:h("MatchParen", s:blue, "", "underline")
call s:h("SpecialKey", s:fg, "", "")
call s:h("Title", s:green, "", "")
call s:h("WildMenu", s:fg, "", "")
" }


" Syntax colors {
call s:h("Comment", s:comment_fg, "", "")
call s:h("Constant", s:cyan, "", "")
call s:h("String", s:yellow, "", "")
call s:h("Character", s:green, "", "")
call s:h("Number", s:blue, "", "")
call s:h("Boolean", s:yellow, "", "")
call s:h("Float", s:blue, "", "")

call s:h("Identifier", s:magenta, "", "")
call s:h("Function", s:green, "", "")
call s:h("Statement", s:green, "", "")

call s:h("Conditional", s:purple, "", "")
call s:h("Repeat", s:purple, "", "")
call s:h("Label", s:purple, "", "")
call s:h("Operator", s:green, "", "")
call s:h("Keyword", s:red, "", "")
call s:h("Exception", s:purple, "", "")

call s:h("PreProc", s:yellow, "", "")
call s:h("Include", s:blue, "", "")
call s:h("Define", s:purple, "", "")
call s:h("Macro", s:purple, "", "")
call s:h("PreCondit", s:yellow, "", "")

call s:h("Type", s:yellow, "", "")
call s:h("StorageClass", s:yellow, "", "")
call s:h("Structure", s:yellow, "", "")
call s:h("Typedef", s:yellow, "", "")

call s:h("Special", s:blue, "", "")
call s:h("SpecialChar", s:fg, "", "")
call s:h("Tag", s:fg, "", "")
call s:h("Delimiter", s:fg, "", "")
call s:h("SpecialComment", s:fg, "", "")
call s:h("Debug", s:fg, "", "")
call s:h("Underlined", s:fg, "", "")
call s:h("Ignore", s:fg, "", "")
call s:h("Error", s:red, s:gutter_bg, "")
call s:h("Todo", s:black, s:yellow, "")
" }


" Plugins {
" GitGutter
call s:h("GitGutterAdd", s:green, s:gutter_bg, "")
call s:h("GitGutterDelete", s:red, s:gutter_bg, "")
call s:h("GitGutterChange", s:yellow, s:gutter_bg, "")
call s:h("GitGutterChangeDelete", s:red, s:gutter_bg, "")
" Fugitive
call s:h("diffAdded", s:green, "", "")
call s:h("diffRemoved", s:red, "", "")
" Coc.nvim
call s:h("CocErrorSign", s:red, "", "")
" }


" Git {
call s:h("gitcommitComment", s:comment_fg, "", "")
call s:h("gitcommitUnmerged", s:red, "", "")
call s:h("gitcommitOnBranch", s:fg, "", "")
call s:h("gitcommitBranch", s:purple, "", "")
call s:h("gitcommitDiscardedType", s:red, "", "")
call s:h("gitcommitSelectedType", s:green, "", "")
call s:h("gitcommitHeader", s:fg, "", "")
call s:h("gitcommitUntrackedFile", s:cyan, "", "")
call s:h("gitcommitDiscardedFile", s:red, "", "")
call s:h("gitcommitSelectedFile", s:green, "", "")
call s:h("gitcommitUnmergedFile", s:yellow, "", "")
call s:h("gitcommitFile", s:fg, "", "")
hi link gitcommitNoBranch gitcommitBranch
hi link gitcommitUntracked gitcommitComment
hi link gitcommitDiscarded gitcommitComment
hi link gitcommitSelected gitcommitComment
hi link gitcommitDiscardedArrow gitcommitDiscardedFile
hi link gitcommitSelectedArrow gitcommitSelectedFile
hi link gitcommitUnmergedArrow gitcommitUnmergedFile
" }

" Fix colors in neovim terminal buffers {
  if has('nvim')
    let g:terminal_color_0 = s:black.gui
    let g:terminal_color_1 = s:red.gui
    let g:terminal_color_2 = s:green.gui
    let g:terminal_color_3 = s:yellow.gui
    let g:terminal_color_4 = s:blue.gui
    let g:terminal_color_5 = s:purple.gui
    let g:terminal_color_6 = s:cyan.gui
    let g:terminal_color_7 = s:white.gui
    let g:terminal_color_8 = s:black.gui
    let g:terminal_color_9 = s:red.gui
    let g:terminal_color_10 = s:green.gui
    let g:terminal_color_11 = s:yellow.gui
    let g:terminal_color_12 = s:blue.gui
    let g:terminal_color_13 = s:purple.gui
    let g:terminal_color_14 = s:cyan.gui
    let g:terminal_color_15 = s:white.gui
    let g:terminal_color_background = s:bg.gui
    let g:terminal_color_foreground = s:fg.gui
  endif
" }