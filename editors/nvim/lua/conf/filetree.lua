--- INFO:
--- This module holds the plugin for filetree UI

---@module 'lazy'
---@module 'neo-tree'

---@type LazyPluginSpec
return {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
    },
    lazy = false,
    config = function()
        require('neo-tree').setup {
            log_level = 'debug',
            window = {
                mappings = {
                    ['i'] = {
                        'open',
                        nowait = true,
                    },
                    ['l'] = {
                        'toggle_node',
                        nowait = true,
                    },
                },
            },
            event_handlers = {
                {
                    event = 'file_open_requested',
                    handler = function()
                        vim.cmd [[ Neotree close ]]
                    end,
                },
            },
            default_component_configs = {
                git_status = {
                    symbols = {
                        added = '+',
                        modified = '~',
                        deleted = 'D',
                        renamed = '»',

                        -- Status type
                        untracked = '?',
                        ignored = '◌',
                        unstaged = '!',
                        staged = '✓',
                        conflict = 'C',
                    },
                },
            },
            filesystem = {
                filtered_items = {
                    visible = true,
                },
            },
        }

        vim.keymap.set('n', '<leader>k', function()
            vim.cmd [[ Neotree toggle reveal ]]
        end, { desc = 'Show Tree' })
    end,
}
