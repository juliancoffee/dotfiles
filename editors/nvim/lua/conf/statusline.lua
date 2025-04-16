--- INFO:
--- StatusLine configuration

---@module 'lazy'

---@type LazyPluginSpec
return {
    'nvim-lualine/lualine.nvim',
    opts = {
        options = {
            icons_enabled = false,
            component_separators = { left = '|', right = '|' },
            section_separators = { left = '', right = '' },
        },
    },
}
