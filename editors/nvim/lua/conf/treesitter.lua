-- INFO:
--- This module holds the plugin configuration for treesitter
---
--- WARN:
--- They say I need nightly to run this, but i'll take the risk

---@module 'lazy'
---@module 'nvim-treesitter.configs'

---@type LazyPluginSpec
local treesitter = {
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
            enable = true,
            disable = { 'luadoc', 'vimdoc', 'rust', 'python' },
        },
        incremental_selection = { enable = true },
        indent = { enable = true },
    },
    init = function()
        --
        -- Enable folds with treesitter
        --
        vim.o.foldmethod = 'expr'
        vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        -- The number of levels to fold on startup
        -- * 0 is toplevel
        -- * 1 is level lower
        -- * 2 is even lower
        -- * ... etc
        vim.o.foldlevel = 50

        -- Force evaluate treesitter on buffer load
        --
        -- This is needed because treesitter is very lazy and if, for example,
        -- you don't need highlighting for this language, it won't run at all.
        --
        -- And when you want to use the information that would be normally
        -- gathered during parsing, for textobjects or querying all locals
        -- to display them in telescope, it silently fails.
        vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
            group = vim.api.nvim_create_augroup('ForceTreesitterEval', {}),
            pattern = '*.*',
            callback = function(event_opts)
                local parsers = require 'nvim-treesitter.parsers'
                local lang = parsers.get_buf_lang(event_opts.buf)
                local ok, parser = pcall(function()
                    return vim.treesitter.get_parser(event_opts.buf, lang)
                end)
                if ok and parser then
                    parser:parse()
                end
            end,
        })
    end,
}

---@type LazyPluginSpec
return {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { treesitter },

    -- module to use for `opts`
    main = 'nvim-treesitter.configs',
    ---@type TSConfig
    ---@diagnostic disable: missing-fields
    opts = {
        textobjects = {
            select = {
                enable = true,

                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,

                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ['af'] = {
                        query = '@function.outer',
                        desc = '@function',
                    },
                    ['if'] = {
                        query = '@function.inner',
                        desc = 'inner @function',
                    },
                    ['ac'] = {
                        query = '@class.outer',
                        desc = '@class',
                    },
                    ['ic'] = {
                        query = '@class.inner',
                        desc = 'inner @class',
                    },
                    -- You can also use captures from other query groups like
                    -- `locals.scm`
                    ['as'] = {
                        query = '@local.scope',
                        query_group = 'locals',
                        desc = 'Select language scope',
                    },
                },

                -- You can choose the select mode (default is charwise 'v')
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * method: eg 'v' or 'o'
                -- and should return the mode ('v', 'V', or '<c-v>') or a table
                -- mapping query_strings to modes.
                selection_modes = {
                    ['@parameter.outer'] = 'v', -- charwise
                    ['@function.outer'] = 'V', -- linewise
                    ['@class.outer'] = '<c-v>', -- blockwise
                },

                -- If you set this to `true` (default is `false`) then any
                -- textobject is extended to include preceding or succeeding
                -- whitespace.
                -- Succeeding whitespace has priority in order to act similarly
                -- to eg the built-in `ap`.
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * selection_mode: eg 'v'
                -- and should return true or false
                include_surrounding_whitespace = false,
            },
        },
    },
}
