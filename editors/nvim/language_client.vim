call plug#begin()
Plug 'autozimu/LanguageClient-neovim', {
            \'branch': 'next',
            \'do': 'bash install.sh',
            \}
call plug#end()

let g:LanguageClient_serverCommands = {
            \ }

let g:LanguageClient_windowLogMessageLevel = "Log"
let g:LanguageClient_loggingFile = expand('~/.vim/LanguageClient.log')
let g:LanguageClient_hoverPreview = "Never"
let g:LanguageClient_useFloatingHover = 0
