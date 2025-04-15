---@diagnostic disable: unused-local
-- convinient way to swap between colorschemes
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
