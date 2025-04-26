--- INFO:
--- Package management

-- load colorscheme module
local colorscheme = require 'conf.color'

-- bootstrap lazy.nvim package manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
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
        require 'conf.whichkey',
        -- colorscheme
        colorscheme.lazy_spec,
        -- fuzzy finder UI
        require 'conf.telescope',
        -- completions
        require 'conf.completion',
        -- lsp
        require 'conf.lsp',
        -- autoformat
        require 'conf.autoformat',
        -- todo-style comments
        require 'conf.todo',
        -- filetree UI
        require 'conf.filetree',
        -- mini plugins (surrounds, arounds, etc)
        require 'conf.minipack',
        -- tree-sitter
        require 'conf.treesitter',
        -- status line
        require 'conf.statusline',
        -- fluent
        'projectfluent/fluent.vim',
        -- git intergrations
        require 'conf.gitsigns',
    }, {
        rocks = {
            enabled = false,
        },
        ui = {
            icons = {
                cmd = '⌘',
                config = '🛠',
                event = '📅',
                ft = '📂',
                init = '⚙',
                keys = '🗝',
                plugin = '🔌',
                runtime = '💻',
                source = '📄',
                start = '🚀',
                task = '📌',
                lazy = '💤 ',
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
