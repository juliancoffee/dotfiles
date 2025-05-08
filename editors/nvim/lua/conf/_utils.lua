-- INFO: module with various useful utilities

local M = {}

--- Return `true` if in `termux` environment
--- @return boolean
function M.is_termux()
    -- check if `termux-setup-storage` command exists
    return vim.fn.executable('termux-setup-storage') == 1
end

--- Consume unused local to silence the diagnostic
function M.fake_use(...) end

--- Return the fully resolved absolute path
--- @param path string input path
function M.absolute_path(path)
    -- help: filename-modifiers
    --
    -- :p means absolute path (kinda)
    --
    -- resolve() helps to fix all the issues
    return vim.fn.resolve(vim.fn.fnamemodify(path, ':p'))
end

--- Return the parent path (or `nil` if root)
--- @param path string current path
function M.get_parent(path)
    path = M.absolute_path(path)

    -- help: filename-modifiers
    --
    -- :h means head
    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then
        return nil
    end

    return parent
end

--- Returns the path to project root using `.git`
--- @param stop_list? [string] additional files to indicate the root
--- @param toplevel? string path to a starting point, `.` by default
--- @param counter? number how many paths to take, default 25
function M.get_root(stop_list, toplevel, counter)
    -- set the defaults
    counter = counter or 25
    stop_list = stop_list or {}
    table.insert(stop_list, '.git')
    toplevel = toplevel or vim.fn.getcwd()

    -- if reached the limit, give up
    if counter == 0 then
        return nil
    end

    -- search for stopfile
    local files = vim.fn.readdir(toplevel)
    for _, f in ipairs(files) do
        if vim.tbl_contains(stop_list, f) then
            return toplevel
        end
    end

    -- recurse
    local parent = M.get_parent(toplevel)
    if not parent then
        return nil
    end

    return M.get_root(stop_list, parent, counter - 1)
end

--- Returns file content
--- @param path string path to the file to read
function M.filecontent(path)
    local buf = ''
    for _, line in ipairs(vim.fn.readfile(path)) do
        buf = buf .. '\n' .. line
    end
    return buf
end

--- Get local `.nvim/settings.json` configuration
-- TODO: provide some fun meta table to fetch them?
function M.get_local_config()
    local root = M.get_root()
    if not root then
        return {}
    end

    local config_path = root .. '/.nvim/settings.json'
    if vim.fn.filereadable(config_path) == 1 then
        local content = M.filecontent(config_path)
        return vim.json.decode(content)
    end

    return {}
end

--- Get a variable using fetcher function
--- @generic T
---
--- @param fetcher fun(table):T
---
--- @return T?
function M.from_local_config(fetcher)
    local ok, res = pcall(function()
        local conf = M.get_local_config()
        return fetcher(conf)
    end)
    if ok then
        return res
    else
        vim.notify('Error loading config: ' .. res)
    end
end

return M
