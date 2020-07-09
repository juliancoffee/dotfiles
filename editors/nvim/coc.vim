nnoremap gd :call CocAction('jumpDefinition', 'tabe')<CR>
nnoremap gi :call CocAction('jumpImplementation', 'tabe')<CR>
nnoremap gc :call CocAction('jumpDeclaration', 'tabe')<CR>
nnoremap gy :call CocAction('jumpTypeDefinition', 'tabe')<CR>
nnoremap gr :call CocAction('jumpReferences', 'tabe')<CR>
nnoremap <C-f> :call CocAction('fold')<CR>
nnoremap <C-c>f :call CocAction('doQuickfix')<CR>
nnoremap <F8> :call CocAction('format')<CR>
nnoremap <F2> :call CocAction('rename')<CR>

" nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
" nnoremap <silent> ]g <Plug>(coc-diagnostic-next)
