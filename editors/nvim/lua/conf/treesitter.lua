-- INFO:
--- This module holds the plugin configuration for treesitter
---
--- WARN:
--- They say I need nightly to run this, but i'll take the risk

---@module 'lazy'
---@module 'nvim-treesitter'

local ensure_installed = {
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
    'css',
    -- ron (Rusty Object Notation)
    'ron',
    -- python
    'python',
    -- rust
    'rust',
    -- java
    'java',
    -- js
    'javascript',
    -- ts
    'typescript',
    'tsx',
}

--- Install missing tree-sitter languages.
local function ensure_ts_languages_installed()
    --- Compute languages missing parser or query installs.
    local config = require('nvim-treesitter.config')
    local installed_parsers = config.get_installed('parsers')
    local installed_queries = config.get_installed('queries')

    local missing = vim.tbl_filter(function(lang)
        return not vim.list_contains(installed_parsers, lang)
            or not vim.list_contains(installed_queries, lang)
    end, ensure_installed)
    if #missing == 0 then
        return
    end

    --- Install missing parsers
    require('nvim-treesitter').install(missing, { summary = true })
end

--- Set a buffer-local tree-sitter motion keymap.
local function map_ts_move(bufnr, move_mode, lhs, rhs, desc)
    pcall(vim.keymap.del, move_mode, lhs, { buffer = bufnr })
    vim.keymap.set(move_mode, lhs, rhs, {
        buffer = bufnr,
        desc = desc,
    })
end

--- Reinstall function motions after ftplugins.
local function set_ts_function_move_keymaps(bufnr, move)
    map_ts_move(bufnr, { 'n', 'x', 'o' }, ']m', function()
        move.goto_next_start('@function.outer', 'textobjects')
    end, 'next @function start')
    map_ts_move(bufnr, { 'n', 'x', 'o' }, ']M', function()
        move.goto_next_end('@function.outer', 'textobjects')
    end, 'next @function end')
    map_ts_move(bufnr, { 'n', 'x', 'o' }, '[m', function()
        move.goto_previous_start('@function.outer', 'textobjects')
    end, 'prev @function start')
    map_ts_move(bufnr, { 'n', 'x', 'o' }, '[M', function()
        move.goto_previous_end('@function.outer', 'textobjects')
    end, 'prev @function end')
end

---@type LazyPluginSpec
local treesitter = {
    'juliancoffeelab/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    init = function()
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
                local ok, parser = pcall(function()
                    return vim.treesitter.get_parser(event_opts.buf)
                end)
                if ok and parser then
                    parser:parse()

                    local lang = parser:lang()
                    local query = vim.treesitter.query.get(lang, 'locals')
                    if not query then
                        error('no locals query for ' .. lang)
                    end
                else
                    vim.notify(
                        'no tree-sitter parser for ' .. event_opts.file,
                        vim.log.levels.WARN
                    )
                end
            end,
        })
    end,
    config = function()
        require('nvim-treesitter').setup()
        ensure_ts_languages_installed()
        -- Enable core treesitter features for parsable buffers.
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup('TreesitterCoreFeatures', {}),
            pattern = '*',
            callback = function(event_opts)
                local ok = pcall(vim.treesitter.get_parser, event_opts.buf)
                if not ok then
                    return
                end

                if vim.bo[event_opts.buf].filetype == 'diff' then
                    pcall(vim.treesitter.start, event_opts.buf)
                end

                vim.bo[event_opts.buf].indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}

local to_opts = {
    select = {
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,

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
        set_jumps = true,
    },
}

---@type LazyPluginSpec
return {
    'juliancoffeelab/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { treesitter },
    enabled = function()
        return not require('conf._utils').is_termux()
    end,
    event = 'VeryLazy',
    config = function()
        require('nvim-treesitter-textobjects').setup(to_opts)
        local select = require('nvim-treesitter-textobjects.select')
        local move = require('nvim-treesitter-textobjects.move')
        local ts_repeat_move =
            require('nvim-treesitter-textobjects.repeatable_move')

        vim.keymap.set({ 'x', 'o' }, 'af', function()
            select.select_textobject('@function.outer', 'textobjects')
        end, { desc = '@function' })
        vim.keymap.set({ 'x', 'o' }, 'if', function()
            select.select_textobject('@function.inner', 'textobjects')
        end, { desc = 'inner @function' })
        vim.keymap.set({ 'x', 'o' }, 'ac', function()
            select.select_textobject('@class.outer', 'textobjects')
        end, { desc = '@class' })
        vim.keymap.set({ 'x', 'o' }, 'ic', function()
            select.select_textobject('@class.inner', 'textobjects')
        end, { desc = 'inner @class' })
        vim.keymap.set({ 'x', 'o' }, 'aa', function()
            select.select_textobject('@parameter.outer', 'textobjects')
        end, { desc = '@parameter' })
        vim.keymap.set({ 'x', 'o' }, 'ia', function()
            select.select_textobject('@parameter.inner', 'textobjects')
        end, { desc = 'inner @parameter' })
        vim.keymap.set({ 'x', 'o' }, 'ax', function()
            select.select_textobject('@call.outer', 'textobjects')
        end, { desc = '@call' })
        vim.keymap.set({ 'x', 'o' }, 'ix', function()
            select.select_textobject('@call.inner', 'textobjects')
        end, { desc = 'inner @call' })
        vim.keymap.set({ 'x', 'o' }, 'ab', function()
            select.select_textobject('@block.outer', 'textobjects')
        end, { desc = '@block' })
        vim.keymap.set({ 'x', 'o' }, 'ib', function()
            select.select_textobject('@block.inner', 'textobjects')
        end, { desc = 'inner @block' })
        vim.keymap.set({ 'x', 'o' }, 'ad', function()
            select.select_textobject('@conditional.outer', 'textobjects')
        end, { desc = '@conditional' })
        vim.keymap.set({ 'x', 'o' }, 'id', function()
            select.select_textobject('@conditional.inner', 'textobjects')
        end, { desc = 'inner @conditional' })
        vim.keymap.set({ 'x', 'o' }, 'ie', function()
            select.select_textobject('@assignment.rhs', 'textobjects')
        end, { desc = 'right of @assignment' })
        vim.keymap.set({ 'x', 'o' }, 'ir', function()
            select.select_textobject('@return.inner', 'textobjects')
        end, { desc = 'inner @return' })
        vim.keymap.set({ 'x', 'o' }, 'as', function()
            select.select_textobject('@local.scope', 'locals')
        end, { desc = 'Select language scope' })

        vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
            move.goto_next_start('@class.outer', 'textobjects')
        end, { desc = 'next @class start' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']d', function()
            move.goto_next_start('@conditional.inner', 'textobjects')
        end, { desc = 'next @conditional start' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']C', function()
            move.goto_next_end('@class.outer', 'textobjects')
        end, { desc = 'next @class end' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']a', function()
            move.goto_next_end('@parameter.outer', 'textobjects')
        end, { desc = 'next @parameter end' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']D', function()
            move.goto_next_end('@conditional.inner', 'textobjects')
        end, { desc = 'next @conditional end' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
            move.goto_previous_start('@class.outer', 'textobjects')
        end, { desc = 'prev @class start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[a', function()
            move.goto_previous_start('@parameter.outer', 'textobjects')
        end, { desc = 'prev @parameter start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[d', function()
            move.goto_previous_start('@conditional.inner', 'textobjects')
        end, { desc = 'prev @conditional start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[C', function()
            move.goto_previous_end('@class.outer', 'textobjects')
        end, { desc = 'prev @class end' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[D', function()
            move.goto_previous_end('@conditional.inner', 'textobjects')
        end, { desc = 'prev @conditional end' })

        -- Reinstall only function motions so ftplugins can't steal them.
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup(
                'TreesitterTextobjectMoves',
                {}
            ),
            pattern = '*',
            callback = function(event_opts)
                set_ts_function_move_keymaps(event_opts.buf, move)
            end,
        })
        set_ts_function_move_keymaps(vim.api.nvim_get_current_buf(), move)

        -- Repeat movement with [;] and [,]
        --  [;] goes backward
        --  [,] goes forward
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
