--
-- package management
--

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

-- convinient way to swap between colorschemes
local colorscheme0 = {
    plug = {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    run = function()
        require("tokyonight").setup({
            style = "moon",
            styles = {},
        })
        vim.cmd [[ colorscheme tokyonight ]]
    end
}

local colorscheme = {
    plug = {
        "catppuccin/nvim", name = "catppuccin", priority = 1000,
    },
    run = function()
        require("catppuccin").setup({
            flavour = "frappe"
        })
        vim.cmd [[ colorscheme catppuccin ]]
    end
}

local lazy_config = {
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
}

require("lazy").setup({
    {
        colorscheme.plug,
    },
}, lazy_config)

colorscheme.run()

--
-- options
--

-- show pretty colors
vim.opt.termguicolors = true

-- shows numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- replace <tab> with spaces
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- vim has these options, but it seems to work just fine without them
-- I'll leave them just in case, but i'm not sure if they're still useful
-- vim.o.autoindent = true
-- vim.o.smartindent = true

-- show sneaky characters
vim.opt.list = true
vim.opt.listchars = {
    trail = ".",
    tab = "> ",
}

-- set bigger limit to allowed number of pages opened with "-p"
vim.o.tabpagemax = 500

--
-- keybinds
--

-- disable accidental q key-press
vim.keymap.set({'n', 'v'}, 'q:', '<Nop>') -- supposed to open cmdline window
vim.keymap.set('n', 'Q', '<Nop>') -- idk

-- stop search highlighting
-- <C-_> actually means <C-/>, don't ask me why
vim.keymap.set('n', '<C-_>', ':nohlsearch<CR>')
