--- INFO:
--- This module holds the plugin to add vim-specific info to lua LSP

---@module 'lazy'
---@module 'which-key'

---@type LazyPluginSpec
return {
    -- Add vim info to lua lsp
    'folke/which-key.nvim',
    event = 'VeryLazy',
    ---@type wk.Opts
    opts = {
        preset = 'helix',
        delay = function(mapping)
            -- if starting to type "+y don't flashbang with helpers
            if mapping.keys == '"' then
                return 1500
            end
            return 250
        end,
        icons = {
            -- disable fancy nerdfont icons for plugis
            mappings = false,
            -- disable fancy nerdfont icons for keys
            keys = {
                Up = '^',
                Down = 'v',
                Left = '<',
                Right = '>',
                C = 'C+', -- Ctrl?
                M = 'M+', -- Meta?
                D = 'D', -- Delete?
                S = 'S+', -- Shift?
                CR = '⏎', -- Enter
                Esc = 'ESC', -- Escape
                ScrollWheelDown = '⇣',
                ScrollWheelUp = '⇡',
                NL = '⏎', -- New Line
                BS = 'BS', -- Backspace
                Space = '␣',
                Tab = '⇥',
                F1 = 'F1',
                F2 = 'F2',
                F3 = 'F3',
                F4 = 'F4',
                F5 = 'F5',
                F6 = 'F6',
                F7 = 'F7',
                F8 = 'F8',
                F9 = 'F9',
                F10 = 'F10',
                F11 = 'F11',
                F12 = 'F12',
            },
        },
    },
    keys = {
        {
            '<leader>?',
            function()
                require('which-key').show { global = false }
            end,
            desc = 'Local Keymaps',
        },
    },
}
