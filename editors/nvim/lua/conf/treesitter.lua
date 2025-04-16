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
            'bash',
            'c',
            'lua',
            'luadoc',
            'html',
            'markdown',
            'markdown_inline',
            'query',
            'vim',
            'vimdoc',
        },
        auto_install = true,
        highlight = {
            enable = true,
            -- I'm used to old syntax highlight too much
            disable = { 'rust', 'python' },
        },
        indent = { enable = true },
    },
}
