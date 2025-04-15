---@module 'lazy'
---@type LazyPluginSpec
return {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
        notify_on_error = false,
        -- copied from kickstarter, if provided, enables format on save
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
        },
    },
}
