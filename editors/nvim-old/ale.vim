Plug 'dense-analysis/ale'                              "linter plugin

let g:ale_linters = {
            \'javascript': ['eslint'],
            \'python': [],
            \'haskell': ['stack-ghc'],
            \'racket': ['raco'],
            \'fish': [],
            \'ocaml': [],
            \'reasonml': [],
            \'rust': [],
            \'c': [],
            \}

" commented out, use coc-pyright
" let g:ale_python_mypy_options = '--warn-return-any --warn-unreachable'
