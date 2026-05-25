--- INFO:
--- This module holds the plugin configuration for folds

---@module 'lazy'

--- Build the folded line-count suffix.
local function folded_text(_, _)
    local hidden_lines = math.max(vim.v.foldend - vim.v.foldstart, 0)
    return {
        { '  .. ', 'Comment' },
        {
            tostring(hidden_lines)
                .. (hidden_lines == 1 and ' line' or ' lines'),
            'Comment',
        },
    }
end

---@type LazyPluginSpec
return {
    'juliancoffeelab/tuck.nvim',
    dependencies = {
        {
            'OXY2DEV/foldtext.nvim',
            opts = {
                styles = {
                    default = {
                        {
                            kind = 'bufline',
                        },
                        {
                            kind = 'section',
                            output = folded_text,
                        },
                    },
                },
            },
        },
    },
    event = { 'BufReadPost', 'BufNewFile' },
    init = function()
        vim.o.foldcolumn = '1'
        vim.o.foldlevel = 0
        vim.o.foldlevelstart = 0
        vim.o.foldenable = true
    end,
    config = function()
        require('tuck').setup {
            auto_unfold = false,
        }

        vim.keymap.set('n', 'zz', function()
            vim.cmd.normal { args = { 'za' }, bang = true }
        end, {
            desc = 'Toggle fold under cursor',
        })
    end,
}
