--- INFO:
--- Package management

-- load colorscheme module
local colorscheme = require('conf.color')

-- bootstrap lazy.nvim package manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- create a module object to return
local M = {}
function M.setup()
    -- install all the plugins
    require('lazy').setup({
        -- hotkey autocomplete basically
        require('conf.whichkey'),
        -- colorscheme
        colorscheme.lazy_spec,
        -- fuzzy finder UI
        require('conf.telescope'),
        -- completions
        require('conf.completion'),
        -- lsp
        require('conf.lsp'),
        -- autoformat
        require('conf.autoformat'),
        -- linters
        require('conf.linter'),
        -- todo-style comments
        require('conf.todo'),
        -- filetree UI
        require('conf.filetree'),
        -- mini plugins (surrounds, arounds, etc)
        require('conf.minipack'),
        -- tree-sitter
        require('conf.treesitter'),
        -- status line
        require('conf.statusline'),
        -- fluent
        'projectfluent/fluent.vim',
        -- git intergrations
        require('conf.gitsigns'),
        -- snacks
        require('conf.snacks').lazy_spec,
        -- debugging experience
        require('conf.dap'),
        -- testing experience
        require('conf.test'),
        -- interactive colors
        {
            'catgoose/nvim-colorizer.lua',
            event = 'BufReadPre',
            -- until I configure it to sane behaviour
            enabled = true,
            opts = {
                filetypes = {
                    '*',
                    css = { css = true, css_fn = true },
                    scss = { css = true, css_fn = true },
                    sass = { css = true, css_fn = true },
                    less = { css = true, css_fn = true },
                    javascriptreact = { css_fn = true },
                    typescriptreact = { css_fn = true },
                },
                user_default_options = {
                    names = false,
                    RGB = true,
                    RGBA = true,
                    RRGGBB = true,
                    RRGGBBAA = true,
                    AARRGGBB = false,
                    rgb_fn = true,
                    hsl_fn = true,
                    css = false,
                    css_fn = true,
                    tailwind = 'normal',
                },
            },
        },
        {
            -- highlights `f`-jumpable positions
            -- 'unblevable/quick-scope',
            -- event = 'VeryLazy',
        },
    }, {
        defaults = {
            lazy = true,
        },
        rocks = {
            enabled = false,
        },
        ui = {
            icons = {
                cmd = '⌘',
                config = '⚙',
                debug = '🐞',
                event = '📅',
                favorite = '⭐',
                ft = '📄',
                init = '🚀',
                import = '📥',
                keys = '🔑',
                lazy = '💤',
                loaded = '⚫︎',
                not_loaded = '⚪',
                plugin = '🔌',
                runtime = '💻',
                require = '📦',
                source = '📄',
                start = '▶',
                task = '✔️',
                list = {
                    '•',
                    '➜',
                    '★',
                    '–',
                },
            },
        },
    })

    -- don't forget to set up a colorscheme
    colorscheme.run()

    -- some fancy keybinds
    vim.keymap.set('n', '<leader>l', ':Lazy<CR>', {
        desc = 'Show [L]azy',
    })
end

return M
