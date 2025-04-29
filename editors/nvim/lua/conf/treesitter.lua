-- INFO:
--- This module holds the plugin configuration for treesitter
---
--- WARN:
--- They say I need nightly to run this, but i'll take the risk

---@module 'lazy'
---@module 'nvim-treesitter.configs'

---@type TSConfig
---@diagnostic disable: missing-fields
local ts_opts = {
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
}

---@type LazyPluginSpec
local treesitter = {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = 'VeryLazy',
    config = function()
        require('nvim-treesitter.configs').setup(ts_opts)
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

local function mapquery(query, desc)
    return {
        query = query,
        desc = desc,
    }
end

---@TSConfig
local to_opts = {
    textobjects = {
        select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                -- items
                ['af'] = mapquery('@function.outer', '@function'),
                ['if'] = mapquery('@function.inner', 'inner @function'),
                ['ac'] = mapquery('@class.outer', '@class'),
                ['ic'] = mapquery('@class.inner', 'inner @class'),
                -- locals
                ['aa'] = mapquery('@parameter.outer', '@parameter'),
                ['ia'] = mapquery('@parameter.inner', 'inner @parameter'),
                -- blocks
                ['ax'] = mapquery('@call.outer', '@call'),
                ['ix'] = mapquery('@call.inner', 'inner @call'),
                ['ab'] = mapquery('@block.outer', '@block'),
                ['ib'] = mapquery('@block.inner', 'inner @block'),
                ['ad'] = mapquery('@conditional.outer', '@conditional'),
                ['id'] = mapquery('@conditional.inner', 'inner @conditional'),
                -- special stuff
                ['ie'] = mapquery('@assignment.rhs', 'right of @assignment'),
                ['ir'] = mapquery('@return.inner', 'inner @return'),
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
        move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
                [']m'] = mapquery('@function.outer', 'next @function start'),
                [']c'] = mapquery('@class.outer', 'next @class start'),
                [']d'] = mapquery('@conditional.inner', 'next @conditional'),
            },
            goto_next_end = {
                [']M'] = mapquery('@function.outer', 'next @function end'),
                [']C'] = mapquery('@class.outer', 'next @class end'),
                [']a'] = mapquery('@parameter.outer', 'next @parameter end'),
                [']D'] = mapquery(
                    '@conditional.inner',
                    'next @conditional end'
                ),
            },
            goto_previous_start = {
                ['[m'] = mapquery('@function.outer', 'prev @function start'),
                ['[c'] = mapquery('@class.outer', 'prev @class start'),
                ['[a'] = mapquery('@parameter.outer', 'prev @parameter start'),
                ['[d'] = mapquery(
                    '@conditional.inner',
                    'prev @conditional start'
                ),
            },
            goto_previous_end = {
                ['[M'] = mapquery('@function.outer', 'prev @function end'),
                ['[C'] = mapquery('@class.outer', 'prev @class end'),
                ['[D'] = mapquery(
                    '@conditional.inner',
                    'prev @conditional end'
                ),
            },
            goto_next = {},
            goto_previos = {},
        },
    },
}

---@type LazyPluginSpec
return {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { treesitter },
    enabled = function()
        return not require('conf._utils').is_termux()
    end,

    event = 'VeryLazy',
    config = function()
        require('nvim-treesitter.configs').setup(to_opts)
        local ts_repeat_move =
            require 'nvim-treesitter.textobjects.repeatable_move'

        -- Repeat movement with [;] and [,]
        --  [,] goes forward
        --  [;] goes backward
        --
        -- regardless of the last direction
        vim.keymap.set(
            { 'n', 'x', 'o' },
            ',',
            ts_repeat_move.repeat_last_move_next
        )
        vim.keymap.set(
            { 'n', 'x', 'o' },
            ';',
            ts_repeat_move.repeat_last_move_previous
        )

        -- Make builtin f, F, t, T also repeatable with ; and ,
        vim.keymap.set(
            { 'n', 'x', 'o' },
            'f',
            ts_repeat_move.builtin_f_expr,
            { expr = true }
        )
        vim.keymap.set(
            { 'n', 'x', 'o' },
            'F',
            ts_repeat_move.builtin_F_expr,
            { expr = true }
        )
        vim.keymap.set(
            { 'n', 'x', 'o' },
            't',
            ts_repeat_move.builtin_t_expr,
            { expr = true }
        )
        vim.keymap.set(
            { 'n', 'x', 'o' },
            'T',
            ts_repeat_move.builtin_T_expr,
            { expr = true }
        )
    end,
}
