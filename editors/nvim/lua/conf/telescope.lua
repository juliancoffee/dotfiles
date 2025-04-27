--- INFO:
--- This module holds the plugin configuration for telescope.
--- Very cool fuzzy finder and floating UI

---@module 'lazy'

---@type LazyPluginSpec
return {
    -- fuzzy finder UI
    --
    -- p.s. copied from kickstart.nvim and tweaked a bit
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',

            build = 'make',
            cond = function()
                return vim.fn.executable 'make' == 1
            end,
        },
        'nvim-telescope/telescope-ui-select.nvim',
    },
    config = function()
        local themes = require 'telescope.themes'
        local actions = require 'telescope.actions'

        require('telescope').setup {
            -- use dropdown theme by default
            -- easier when you don't have the ultra-wide screen :)
            defaults = vim.tbl_extend('force', themes.get_dropdown(), {
                mappings = {
                    i = {
                        ['<esc>'] = actions.close,
                    },
                },
            }),
            extensions = {
                -- switch default vim's select menu to telescope
                ['ui-select'] = {
                    themes.get_dropdown(),
                },
            },
        }

        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'ui-select')

        local builtin = require 'telescope.builtin'
        -- Search help manual
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, {
            desc = '[S]earch [H]elp',
        })

        -- Search set keymaps (without defaults)
        vim.keymap.set('n', '<leader>sk', builtin.keymaps, {
            desc = '[S]earch [K]eymaps',
        })

        -- Scroll through telescope commands
        vim.keymap.set('n', '<leader>ss', builtin.builtin, {
            desc = '[S]croll Tele[s]cope builtins',
        })

        -- Search fuzzy in current buffer
        vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, {
            desc = '[/] Fuzzily search in current buffer',
        })

        -- Search by grep-ing around
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, {
            desc = '[S]earch by [G]rep',
        })

        -- Switch through files with this word
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, {
            desc = '[S]witch files with current [W]ord',
        })

        -- Scroll through diagnostic
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, {
            desc = 'LSP: [S]croll [D]iagnostics',
        })

        -- Scroll through all tree sitter symolbs
        vim.keymap.set('n', '<leader>st', builtin.treesitter, {
            desc = '[S]earch [T]reeSitter symbols',
        })

        -- Resume last telescope search
        vim.keymap.set('n', '<leader>sr', builtin.resume, {
            desc = '[S]earch [R]esume',
        })

        -- Recent file switcher
        vim.keymap.set('n', '<leader>s.', builtin.oldfiles, {
            desc = '[S]witch Recent Files ("." for repeat)',
        })

        -- Buffer switcher
        vim.keymap.set('n', '<leader><leader>', builtin.buffers, {
            desc = '[ ] Switch existing buffers',
        })

        -- Search current file
        vim.keymap.set('n', '<leader>sf', builtin.find_files, {
            desc = '[S]witch [F]iles',
        })

        -- Config files switcher
        vim.keymap.set('n', '<leader>sn', function()
            builtin.find_files { cwd = vim.fn.stdpath 'config' }
        end, { desc = '[S]witch [N]eovim files' })
    end,
}
