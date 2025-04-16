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
        -- colorscheme
        colorscheme.lazy_spec,
        require 'conf.telescope',
        require 'conf.completion',
        require 'conf.nvim_ls',
        require 'conf.lsp',
        require 'conf.autoformat',
        {
            'folke/todo-comments.nvim',
            dependencies = {
                'nvim-lua/plenary.nvim',
            },
            opts = { signs = false },
        },
    }, {
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
