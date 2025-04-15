--
-- package management
--
local colorscheme = require("conf.color")

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
        colorscheme.lazy_spec,
        require 'conf.telescope',
        require 'conf.completion',
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

    -- some fancy keybinds
    vim.keymap.set('n', '<leader>l', ':Lazy<CR>', {
        desc = 'Show [L]azy',
    })
end

return M
