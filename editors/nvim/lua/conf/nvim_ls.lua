--- INFO:
--- This module holds the plugin to add vim-specific info to lua LSP

---@module 'lazy'
---@module 'lazydev'

---@type LazyPluginSpec
return {
    -- Add vim info to lua lsp
    'folke/lazydev.nvim',
    ft = 'lua',
    ---@type lazydev.Config
    opts = {
        library = {
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
    },
}
