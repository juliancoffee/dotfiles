--- INFO:
--- Config entry point

--- NOTE: to introduce new module, add it to lua/ folder
local plugins = require 'plugins'

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

-- i still don't get what these do, but probably better with them than
-- without
--
-- some of these are default btw
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.breakindent = true

-- show sneaky characters
vim.opt.list = true
vim.opt.listchars = {
    trail = '.',
    tab = '> ',
}

-- set bigger limit to allowed number of pages opened with "-p"
vim.o.tabpagemax = 500

-- set minimum number of lines visible
vim.opt.scrolloff = 5

-- Natural splits.
-- Right and below, instead of left and above.
vim.opt.splitright = true
vim.opt.splitbelow = true

--
-- keybinds
--

-- Set space as the <leader> key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- disable accidental q key-press
vim.keymap.set({ 'n', 'v' }, 'q:', '<Nop>') -- supposed to open cmdline window
vim.keymap.set('n', 'Q', '<Nop>') -- idk

-- stop search highlighting
-- <C-_> actually means <C-/>, don't ask me why
vim.keymap.set('n', '<C-_>', ':nohlsearch<CR>')

vim.keymap.set('n', '<leader>o', ':only<CR>', { desc = 'Keep [o]nly window' })

-- call plugins at the end after all the options
plugins.setup()
