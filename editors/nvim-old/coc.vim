Plug 'neoclide/coc.nvim', {'branch': 'release'}        " VSCode like completion

let g:coc_global_extensions = [
    \ 'coc-pyright',
    \ 'coc-clangd',
    \ 'coc-css',
    \ 'coc-html',
    \ 'coc-json',
    \ 'coc-vimlsp',
    \ ]

nnoremap gd :call CocAction('jumpDefinition', 'edit')<CR>
nnoremap gi :call CocAction('jumpImplementation', 'edit')<CR>
nnoremap gc :call CocAction('jumpDeclaration', 'edit')<CR>
nnoremap gy :call CocAction('jumpTypeDefinition', 'edit')<CR>
nnoremap gr :call CocAction('jumpReferences', 'edit')<CR>
nnoremap gh :call CocAction('doHover')<CR>
nnoremap <C-f> :call CocAction('fold')<CR>
nnoremap <C-c>f :call CocAction('doQuickfix')<CR>
nnoremap <C-c>r :call CocAction('runCommand')<CR>
nnoremap <F8> :call CocAction('format')<CR>
nnoremap <F2> :call CocAction('rename')<CR>

" nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
" nnoremap <silent> ]g <Plug>(coc-diagnostic-next)
