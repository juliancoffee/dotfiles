--- INFO:
--- This module holds the plugin configuration for folds

---@module 'lazy'

--- Split a line into syntax-highlighted fragments.
local function syntax_fragments(line_nr, line)
    local fragments = {}
    local text = ''
    local current_hl

    for col, char in ipairs(vim.fn.split(line, '\\zs')) do
        local hl_id = vim.fn.synID(line_nr, col, true)
        local hl = vim.fn.synIDattr(vim.fn.synIDtrans(hl_id), 'name')
        if hl == '' then
            hl = nil
        end

        if hl == current_hl then
            text = text .. char
        else
            if text ~= '' then
                table.insert(fragments, { text, current_hl })
            end
            text = char
            current_hl = hl
        end
    end

    if text ~= '' then
        table.insert(fragments, { text, current_hl })
    end

    return fragments
end

--- Build folded text from syntax-highlighted line fragments.
local function folded_text(buffer, _)
    local first_line =
        vim.api.nvim_buf_get_lines(
            buffer,
            vim.v.foldstart - 1,
            vim.v.foldstart,
            false
        )[1] or ''
    local hidden_lines = math.max(vim.v.foldend - vim.v.foldstart, 0)
    local fragments = syntax_fragments(vim.v.foldstart, first_line)

    table.insert(fragments, { '  .. ', 'Comment' })
    table.insert(fragments, {
        tostring(hidden_lines) .. (hidden_lines == 1 and ' line' or ' lines'),
        'Comment',
    })

    return fragments
end

---@type LazyPluginSpec
return {
    'juliancoffeelab/tuck.nvim',
    dev = true,
    dependencies = {
        {
            'OXY2DEV/foldtext.nvim',
            opts = {
            styles = {
                default = {
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
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
    end,
    config = function()
        require('tuck').setup {
            auto_unfold = false,
            integrations = {
                gitsigns = true,
            },
        }

        vim.keymap.set('n', 'zz', function()
            vim.cmd.normal { args = { 'za' }, bang = true }
        end, {
            desc = 'Toggle fold under cursor',
        })
    end,
}
