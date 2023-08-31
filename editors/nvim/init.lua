-- show pretty colors
vim.o.termguicolors = true

-- shows numbers
vim.o.number = true
vim.o.relativenumber = true

-- replace <tab> with spaces
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

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
