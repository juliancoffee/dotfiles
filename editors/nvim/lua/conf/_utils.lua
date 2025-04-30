-- INFO: module with various useful utilities

local M = {}
function M.is_termux()
    -- check if `termux-setup-storage` command exists
    return vim.fn.executable('termux-setup-storage') == 1
end

return M
