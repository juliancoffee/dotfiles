return {
    'saghen/blink.cmp',

    -- Release tag for pre-built binaries
    version = '1.*',
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
                            text = function(ctx)
                                return '*'
                            end,
                        },
                    },
                },
            },
        },

        -- Complete paths and words from buffer
        sources = {
            default = { 'path', 'buffer' },
        },

        -- Prefer pre-built rust fuzzy matcher or fallback to lua with warning
        fuzzy = {
            implementation = 'prefer_rust_with_warning',
        }
    },
    opts_extend = { 'sources.default' },
}
