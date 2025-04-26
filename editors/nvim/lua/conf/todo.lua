--- INFO:
--- This module holds the plugin configuration for TODO-style comments

---@module 'lazy'
---@module 'todo-comments'

---@type LazyPluginSpec
return {
    'folke/todo-comments.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    event = 'VeryLazy',
    ---@type TodoOptions
    ---@dianostic
    opts = {
        keywords = {
            WARN = {
                alt = { 'SECURITY WARNING' },
            },
        },
        signs = false,
        highlight = {
            after = '',
        },
    },
}
