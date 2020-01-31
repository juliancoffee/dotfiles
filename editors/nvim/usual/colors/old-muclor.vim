" Vim color file
" Maintainer:	Hans Fugal <hans@fugal.net>
" Last Change:	$Date: 2004/06/13 19:30:30 $
" Last Change:	$Date: 2004/06/13 19:30:30 $
" URL:		http://hans.fugal.net/vim/colors/desert.vim
" Version:	$Id: desert.vim,v 1.1 2004/06/13 19:30:30 vimboss Exp $

" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
	syntax reset
    endif
endif
let g:colors_name="muclor"


"Because I can
hi Normal ctermfg=194 ctermbg=235

hi Constant	ctermfg=202           "integer, float et cetera
hi String ctermfg=226             "things between quote
hi Macro ctermfg=141              "macros
hi Operator ctermfg=118           
hi Include ctermfg=102

hi Type	ctermfg=120                "things before declaration
hi Identifier cterm=NONE ctermfg=200

hi LineNr ctermfg=133             "numbers line
hi CursorLineNr ctermfg=149       "numbers where I am

hi IncSearch cterm=reverse ctermfg=102 ctermbg=NONE
hi Search cterm=reverse ctermfg=102 ctermbg=NONE

hi TabLine cterm=NONE ctermfg=141 ctermbg=234
hi TabLineFill ctermfg=235
hi TabLineSel ctermbg=236

hi StatusLine cterm=NONE
hi StatusLineNC cterm=reverse

hi ModeMsg cterm=NONE ctermfg=brown
"-----------------------------------
"Because I cannot
"hi SpecialKey	ctermfg=darkgreen
"hi NonText	cterm=bold ctermfg=darkblue
hi Directory	ctermfg=darkcyan
"hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi MoreMsg	ctermfg=200
"hi Question	ctermfg=200
hi VertSplit	cterm=reverse
hi Title	ctermfg=200
hi Visual	cterm=reverse
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgrey ctermbg=NONE
hi FoldColumn	ctermfg=darkgrey ctermbg=NONE
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi Comment	ctermfg=darkcyan


hi Special	ctermfg=5
hi Statement	ctermfg=118
hi PreProc	ctermfg=5
hi Underlined	cterm=underline ctermfg=5
hi Ignore	cterm=bold ctermfg=7
hi Ignore	ctermfg=darkgrey
hi Error	cterm=bold ctermfg=7 ctermbg=1


"vim: sw=4
