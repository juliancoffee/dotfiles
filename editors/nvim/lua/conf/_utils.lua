-- INFO: module with various useful utilities

local M = {}

--- Returns `true` if in `termux` environment
function M.is_termux()
    -- check if `termux-setup-storage` command exists
    return vim.fn.executable('termux-setup-storage') == 1
end

--- Consume unused local to silence the diagnostic
function M.fake_use(...) end

return M
