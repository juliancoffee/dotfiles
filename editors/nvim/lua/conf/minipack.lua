--- INFO:
--- This module holds ... stuff
---
--- objects, surrounds, status line, etc

---@module 'lazy'

---@type LazyPluginSpec
return {
    'echasnovski/mini.nvim',
    config = function()
        -- extends built-in textobjects but plays horribly with whichkey
        local enable_around = false
        -- same, but at least it's useful
        local enable_surround = true

        if enable_around then
            -- ai stands for arround+inside
            require('mini.ai').setup {
                -- how far we will search for text object
                n_lines = 3000,
            }
        end

        if enable_surround then
            -- surround plugin
            --
            -- Examples:
            -- - sd{ to [d]elete brackets
            -- {test}
            -- - sr{( to [r]eplace brackets with other brackets
            -- {test}
            -- - saiw{ to [a]dd brackets [i]nside [w]ord
            -- test
            --
            -- Takes time to get used to, not gonna lie.
            -- Also idk how useful it is, but we'll see.
            require('mini.surround').setup()
        end

        -- statusline
        require('mini.statusline').setup { use_icons = false }
    end,
}
