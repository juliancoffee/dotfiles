-- convinient way to swap between colorschemes
local tokyonight = {
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

local catpuccin = {
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

return catpuccin
