--- INFO:
--- This module holds stuff, but different
---
--- For now, profiler only

---@module 'snacks'

---@type 'LazyPluginSpec'
local spec = {
    'folke/snacks.nvim',
    opts = function()
        -- Toggle the profiler
        Snacks.toggle.profiler():map '<leader>pp'
        -- Toggle the profiler highlights
        Snacks.toggle.profiler_highlights():map '<leader>ph'
    end,
    keys = {
        {
            '<leader>ps',
            function()
                Snacks.profiler.scratch()
            end,
            desc = 'Profiler Scratch Bufer',
        },
    },
}

local function profiler()
    local snacks = vim.fn.stdpath 'data' .. '/lazy/snacks.nvim'
    vim.opt.rtp:append(snacks)
    ---@diagnostic disable-next-line: missing-fields
    require('snacks.profiler').startup {
        startup = {
            -- stop profiler on this event. Defaults to `VimEnter`
            -- event = 'VimEnter',
            event = 'UIEnter',
            -- event = "VeryLazy",
        },
    }
end

return { lazy_spec = spec, profiler = profiler }
