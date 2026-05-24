--- INFO:
--- This module holds the plugin configuration for folds

---@module 'lazy'

-- NOTE: copypasted from the source
---
---return a string type use ufo providers
---return a string in a table like a string type
---return empty string '' will disable any providers
---return `nil` will use default value {'lsp', 'indent'}
---@alias UfoProviderSelector fun(
---    bufnr: number,
---    filetype: string,
---    buftype: string,
---): UfoProviderEnum|string[]|function|nil

---@type UfoProviderSelector
local provider_selector = function(_, _, _)
    return { 'treesitter', 'indent' }
end

---@type LazyPluginSpec
return {
    'kevinhwang91/nvim-ufo',
    dependencies = {
        'kevinhwang91/promise-async',
    },
    event = { 'BufReadPost', 'BufNewFile' },
    init = function()
        vim.o.foldcolumn = '1'
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
    end,
    config = function()
        local ufo = require('ufo')
        ufo.setup {
            provider_selector = provider_selector,
        }

        vim.keymap.set('n', 'zR', ufo.openAllFolds, {
            desc = 'Open all folds',
        })
        vim.keymap.set('n', 'zM', ufo.closeAllFolds, {
            desc = 'Close all folds',
        })
        vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds, {
            desc = 'Open folds except kinds',
        })
        vim.keymap.set('n', 'zm', ufo.closeFoldsWith, {
            desc = 'Close folds with level',
        })
        vim.keymap.set('n', 'zz', function()
            vim.cmd.normal { args = { 'za' }, bang = true }
        end, {
            desc = 'Toggle fold under cursor',
        })
    end,
}
