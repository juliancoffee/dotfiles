--- INFO:
--- This module holds the plugin configuration for autoformat and other
--- tools

---@module 'lazy'
---@module 'conform'

---@type LazyPluginSpec
return {
    -- Add autoformat and stuff
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },

    ---@type conform.setupOpts
    opts = {
        notify_on_error = false,
        -- if provided, enables format on save
        format_on_save = function()
            -- also it's possible to disable certain formatters here, they say
            return {
                timeout_ms = 500,
                lsp_format = 'fallback',
            }
        end,
        formatters_by_ft = {
            lua = {
                'stylua',
            },
            rust = {
                'rustfmt',
            },
            python = {
                'isort',
                'ruff_format',
                lsp_format = 'fallback',
            },
        },
    },
}
