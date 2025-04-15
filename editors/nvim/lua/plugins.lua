--
-- package management
--
local colorscheme = require("color")

-- bootstrap lazy.nvim package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- create a module object to return
local M = {}
function M.setup()
    -- install all the plugins
    require("lazy").setup({
        -- colorscheme
        {
            colorscheme.plug,
        },
        -- fuzzy finder UI
        --
        -- p.s. copied from kickstart.nvim
        {
            'nvim-telescope/telescope.nvim',
            event = 'VimEnter',
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
                local themes = require("telescope.themes")
                local actions = require("telescope.actions")

                require('telescope').setup {
                    -- use dropdown theme by default
                    -- easier when you don't have the ultra-wide screen :)
                    defaults = vim.tbl_extend(
                        "force",
                        themes.get_dropdown(),
                        {
                            mappings = {
                                i = {
                                    ["<esc>"] = actions.close,
                                },
                            },
                        }
                    ),
                    extensions = {
                        -- switch default vim's select menu to telescope
                        ['ui-select'] = {
                            themes.get_dropdown(),
                        },
                    }
                }

                pcall(require('telescope').load_extension, 'fzf')
                pcall(require('telescope').load_extension, 'ui-select')

                local builtin = require 'telescope.builtin'
                vim.keymap.set('n', '<leader>sh', builtin.help_tags, {
                    desc = '[S]earch [H]elp',
                })
                vim.keymap.set('n', '<leader>sk', builtin.keymaps, {
                    desc = '[S]earch [K]eymaps',
                })
                vim.keymap.set('n', '<leader>sf', builtin.find_files, {
                    desc = '[S]earch [F]iles'
                })
                vim.keymap.set('n', '<leader>ss', builtin.builtin, {
                    desc = '[S]earch [S]elect Telescope'
                })
                vim.keymap.set('n', '<leader>sw', builtin.grep_string, {
                    desc = '[S]earch current [W]ord'
                })
                vim.keymap.set('n', '<leader>sg', builtin.live_grep, {
                    desc = '[S]earch by [G]rep'
                })

                vim.keymap.set('n', '<leader>sd', builtin.diagnostics, {
                    desc = '[S]earch [D]iagnostics'
                })
                vim.keymap.set('n', '<leader>sr', builtin.resume, {
                    desc = '[S]earch [R]esume'
                })
                vim.keymap.set('n', '<leader>s.', builtin.oldfiles, {
                    desc = '[S]earch Recent Files ("." for repeat)'
                })
                vim.keymap.set('n', '<leader><leader>', builtin.buffers, {
                    desc = '[ ] Find existing buffers'
                })
                -- Shortcut for searching your Neovim configuration files
                vim.keymap.set('n', '<leader>sn',
                function()
                    builtin.find_files { cwd = vim.fn.stdpath 'config' }
                end,
                { desc = '[S]earch [N]eovim files' })
            end,
        },
    }, {
        ui = {
            icons = {
                cmd = "⌘",
                config = "🛠",
                event = "📅",
                ft = "📂",
                init = "⚙",
                keys = "🗝",
                plugin = "🔌",
                runtime = "💻",
                source = "📄",
                start = "🚀",
                task = "📌",
                lazy = "💤 ",
            },
        },
    })

    -- don't forget to set up a colorscheme
    colorscheme.run()
end

return M
