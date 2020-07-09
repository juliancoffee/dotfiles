let g:ale_linters = {
            \'javascript': ['eslint'],
            \'python': ['flake8', 'mypy'],
            \'haskell': ['stack-ghc'],
            \'racket': ['raco'],
            \'fish': [],
            \'ocaml': [],
            \'reasonml': [],
            \'rust': [],
            \'c': [],
            \}
let g:ale_python_mypy_options = '--warn-return-any --warn-unreachable'
