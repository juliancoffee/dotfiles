--- INFO:
--- This module holds the plugin configuration for treesitter
---
--- WARN:
--- They say I need nightly to run this, but i'll take the risk

---@module 'lazy'
---@module 'nvim-treesitter.configs'

---@type LazyPluginSpec
return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    -- module to use for `opts`
    main = 'nvim-treesitter.configs',
    ---@type TSConfig
    ---@diagnostic disable: missing-fields
    opts = {
        ensure_installed = {
            -- smth
            'bash',
            'c',
            -- lua
            'lua',
            'luadoc',
            -- markdown
            'markdown',
            'markdown_inline',
            -- ???
            'query',
            -- vim
            'vim',
            'vimdoc',
            -- git
            'diff',
            'gitcommit',
            -- html
            'html',
            'htmldjango',
            -- ron (Rusty Object Notation)
            'ron',
            -- python
            'python',
            -- rust
            'rust',
        },
        auto_install = false,
        highlight = {
            -- disabling this leads also disables telescope treesitter view?
            -- what the fuck
            enable = true,
        },
        indent = { enable = true },
    },
}
