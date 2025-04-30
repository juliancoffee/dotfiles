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
    -- it must be loaded eagerly, otherwise netrw stuff won't work
    -- properly
    lazy = false,
    init = function()
        -- we're replacing built-in netrw
        vim.g.loaded_netrwPlugin = 1
        vim.g.loaded_netrw = 1
    end,
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
                        vim.cmd([[ Neotree close ]])
                    end,
                },
            },
            default_component_configs = {
                icon = {
                    folder_closed = '[+]',
                    folder_open = '[-]',
                    folder_empty = '[]',
                    folder_empty_open = '',
                    default = '*',
                },
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
                hijack_netrw_behavior = 'open_current',
                filtered_items = {
                    visible = true,
                },
            },
        }

        vim.keymap.set('n', '<leader>k', function()
            vim.cmd([[ Neotree toggle reveal_force_cwd ]])
        end, { desc = 'Show Tree' })
    end,
}
