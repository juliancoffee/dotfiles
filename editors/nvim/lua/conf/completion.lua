--- INFO:
--- This module holds the plugin configuration for completions

---@module 'lazy'
---@module 'blink.cmp'

---@type LazyPluginSpec
local compat = {
    'saghen/blink.compat',
    opts = {},
}

---@type LazyPluginSpec
local main = {
    'saghen/blink.cmp',

    -- Release tag for pre-built binaries
    version = '1.*',

    event = 'VeryLazy',
    dependencies = { 'andersevenrud/cmp-tmux' },

    ---@type blink.cmp.Config
    opts = {
        -- Default configuration closer to default nvim keybinds
        keymap = { preset = 'default' },
        enabled = function()
            return not vim.tbl_contains({ 'dap-repl' }, vim.bo.filetype)
        end,

        completion = {
            -- Always show docs if available
            documentation = { auto_show = true },
            menu = {
                draw = {
                    components = {
                        -- Disable nerd icons
                        kind_icon = {
                            text = function(a)
                                if a.source_name == 'LSP' then
                                    return '+'
                                else
                                    return '*'
                                end
                            end,
                        },
                    },
                },
            },
        },

        -- Complete paths and words from buffer
        sources = {
            default = { 'lsp', 'omni', 'buffer', 'path', 'tmux' },
            providers = {
                tmux = {
                    name = 'tmux',
                    module = 'blink.compat.source',
                    opts = {},
                },
            },
        },

        -- Prefer pre-built rust fuzzy matcher or fallback to lua with warning
        fuzzy = {
            implementation = 'prefer_rust_with_warning',
            sorts = {
                function(a, b)
                    -- if no source or sources are equal, return and let
                    -- other sorting methods handle it
                    if
                        (a.source_name == nil or b.source_name == nil)
                        or (a.source_name == b.source_name)
                    then
                        return
                    end

                    -- otherwise, if next proposal comes from `tmux`
                    -- return `true` which will always prefer first one
                    return b.source_name == 'tmux'
                end,

                -- defaults
                'score',
                'sort_text',
            },
        },
    },
    opts_extend = { 'sources.default' },
}

return {
    compat,
    main,
}
