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
        -- Default configuration closer to rust keybinds
        keymap = { preset = 'default' },

        completion = {
            -- Always show docs if available
            documentation = { auto_show = true, auto_show_delay_ms = 500 },
            menu = {
                draw = {
                    components = {
                        -- Disable nerd icons
                        kind_icon = {
                            text = function()
                                return '*'
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
        },
    },
    opts_extend = { 'sources.default' },
}

return {
    compat,
    main,
}
