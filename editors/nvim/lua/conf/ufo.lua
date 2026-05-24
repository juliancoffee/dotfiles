--- INFO:
--- This module holds the plugin configuration for folds

---@module 'lazy'

---@type LazyPluginSpec
return {
    'kevinhwang91/nvim-ufo',
    dependencies = {
        'kevinhwang91/promise-async',
        'juliancoffeelab/tuck.nvim',
    },
    event = { 'BufReadPost', 'BufNewFile' },
    init = function()
        vim.o.foldcolumn = '1'
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
    end,
    config = function()
        local tuck = require('tuck')
        local ufo = require('ufo')

        tuck.setup {
            manage_folds = false,
            auto_unfold = false,
            integrations = {
                telescope = true,
            },
        }

        ufo.setup {
            provider_selector = function()
                return tuck.ufo_provider
            end,
            close_fold_kinds_for_ft = {
                -- nvim-ufo doesn't know that we're defining a new type
                ---@diagnostic disable-next-line: assign-type-mismatch
                default = { 'body' },
            },
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

        local disable_foldbg = function()
            vim.cmd([[
                    highlight Folded guibg=NONE ctermbg=NONE
                    highlight UfoFoldedBg guibg=NONE ctermbg=NONE
                    highlight UfoCursorFoldedLine guibg=NONE ctermbg=NONE
                ]])
        end
        disable_foldbg()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup('ufo_highlights', {
                clear = true,
            }),
            callback = disable_foldbg,
        })
    end,
}
