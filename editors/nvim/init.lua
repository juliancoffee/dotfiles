--
-- options
--

-- show pretty colors
vim.o.termguicolors = true

-- shows numbers
vim.o.number = true
vim.o.relativenumber = true

-- replace <tab> with spaces
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- vim has these options, but it seems to work just fine without them
-- I'll leave them just in case, but i'm not sure if they're still useful
-- vim.o.autoindent = true
-- vim.o.smartindent = true

-- show sneaky characters
vim.o.list = true
vim.opt.listchars = {
    trail = ".",
    tab = "> ",
}

-- set bigger limit to allowed number of pages opened with "-p"
vim.o.tabpagemax = 500

-- default yet pretty colorscheme
vim.cmd.colorscheme('desert')


--
-- keybinds
--

-- disable accidental q key-press
vim.keymap.set({'n', 'v'}, 'q:', '<Nop>') -- supposed to open cmdline window
vim.keymap.set('n', 'Q', '<Nop>') -- idk

-- disable search highlight
-- <C-_> actually means <C-/>, don't ask me why
vim.keymap.set('n', '<C-_>', ':nohlsearch<CR>')
