--- INFO:
--- This module holds the plugin configuration for TODO-style comments

---@module 'lazy'
---@module 'gitsigns'

---@type LazyPluginSpec
return {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    opts = {
        -- show blame lens if hovered for 1s
        current_line_blame = true,
        -- diff vertically
        diff_opts = {
            vertical = false,
        },
        on_attach = function(bufnr)
            local gitsigns = require('gitsigns')

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Staging and restoring
            map(
                'n',
                '<leader>hS',
                gitsigns.stage_buffer,
                { desc = '[S]tage buffer' }
            )

            map(
                'n',
                '<leader>hs',
                gitsigns.stage_hunk,
                { desc = '[h]unk [s]tage' }
            )
            map(
                'n',
                '<leader>hr',
                gitsigns.reset_hunk,
                { desc = '[h]unk [r]estore' }
            )
            map('v', '<leader>hs', function()
                gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } {
                    desc = '[h]unk [s]tage',
                }
            end)

            map('v', '<leader>hr', function()
                gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } {
                    desc = '[h]unk [r]estore',
                }
            end)

            -- Previews
            map(
                'n',
                '<leader>hp',
                gitsigns.preview_hunk_inline,
                { desc = '[H]unk [P]review inline' }
            )

            map('v', '<leader>hp', function()
                gitsigns.preview_hunk_inline {
                    vim.fn.line('.'),
                    vim.fn.line('v'),
                } { desc = '[H]unk [P]review inline' }
            end)

            map('n', '<leader>hd', function()
                gitsigns.diffthis(nil, {
                    split = 'rightbelow',
                })
            end, { desc = '[h]unt [d]iff' })

            map('n', '<leader>hb', gitsigns.blame, { desc = '[h]unt [b]lame' })

            -- Text Objects
            map(
                { 'o', 'x' },
                'ih',
                gitsigns.select_hunk,
                { desc = 'inner git hunk' }
            )

            -- Movements
            local has_ts_moves, ts_repeat_move = pcall(function()
                return require('nvim-treesitter.textobjects.repeatable_move')
            end)

            local next_hunk, prev_hunk =
                function()
                    gitsigns.nav_hunk('next')
                end, function()
                    gitsigns.nav_hunk('prev')
                end

            if has_ts_moves then
                next_hunk, prev_hunk = ts_repeat_move.make_repeatable_move_pair(
                    next_hunk,
                    prev_hunk
                )
            end

            vim.keymap.set(
                { 'n', 'x', 'o' },
                ']h',
                next_hunk,
                { desc = 'next Git hunk' }
            )
            vim.keymap.set(
                { 'n', 'x', 'o' },
                '[h',
                prev_hunk,
                { desc = 'prev Git hunk' }
            )
        end,
    },
}
