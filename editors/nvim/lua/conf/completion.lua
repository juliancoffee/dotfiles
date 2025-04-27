--- INFO:
--- This module holds the plugin configuration for completions

---@module 'lazy'
---@module 'blink.cmp'

---@type LazyPluginSpec
return {
    'saghen/blink.cmp',

    -- Release tag for pre-built binaries
    version = '1.*',

    event = 'VeryLazy',

    ---@type blink.cmp.Config
    opts = {
        -- Default configuration closer to rust keybinds
        keymap = { preset = 'default' },

        completion = {
            -- Always show docs if available
            documentation = { auto_show = true },
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
            default = { 'path', 'buffer', 'omni', 'lsp' },
        },

        -- Prefer pre-built rust fuzzy matcher or fallback to lua with warning
        fuzzy = {
            implementation = 'prefer_rust_with_warning',
        },
    },
    opts_extend = { 'sources.default' },
}
