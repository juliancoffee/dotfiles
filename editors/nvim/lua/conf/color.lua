--- INFO:
--- This module provides a convinient way to swap between colorschemes

---@module 'lazy'

---@class ColorScheme
---@field lazy_spec LazyPluginSpec Spec to pass to lazy.nvim
---@field run fun() The function to actually enable the colorscheme

---@type ColorScheme
---@diagnostic disable-next-line: unused-local
local tokyonight = {
    lazy_spec = {
        'folke/tokyonight.nvim',
        lazy = false,
        priority = 1000,
        opts = {},
    },
    run = function()
        require('tokyonight').setup {
            style = 'moon',
            styles = {},
        }
        vim.cmd [[ colorscheme tokyonight ]]
    end,
}

---@type ColorScheme
local catpuccin = {
    lazy_spec = {
        'catppuccin/nvim',
        name = 'catppuccin',
        priority = 1000,
    },
    run = function()
        require('catppuccin').setup {
            flavour = 'frappe',
        }
        vim.cmd [[ colorscheme catppuccin ]]
    end,
}

return catpuccin
