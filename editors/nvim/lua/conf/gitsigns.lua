--- INFO:
--- This module holds the plugin configuration for TODO-style comments

---@module 'lazy'
---@module 'gitsigns'

---@type LazyPluginSpec
return {
    'juliancoffee/gitsigns.nvim',
    -- fork because `gitsigns.diffthis` panics for some reason
    branch = 'juliancoffee/pcall-asystem',
    opts = {
        -- show blame lens if hovered for 1s
        current_line_blame = true,
        -- colored number lines instead of using sign column
        signcolumn = false,
        numhl = true,
        -- diff vertically
        diff_opts = {
            vertical = false,
        },
        on_attach = function(bufnr)
            local gitsigns = require 'gitsigns'

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

            -- Previews
            map(
                'n',
                '<leader>hp',
                gitsigns.preview_hunk_inline,
                { desc = '[H]unk [P]review inline' }
            )

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
        end,
    },
}
