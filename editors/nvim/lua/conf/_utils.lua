-- INFO: module with various useful utilities

local M = {}

local function read_file(path)
    return table.concat(vim.fn.readfile(path), '\n')
end

local function match_django_settings_module(content)
    return content:match(
        'os%.environ%.setdefault%s*%(%s*[\'"]DJANGO_SETTINGS_MODULE[\'"]%s*,%s*[\'"]([^\'"]+)[\'"]%s*[,%)]'
    )
end

local function match_django_settings_module_in_pyproject(content)
    local section = content:match('%[tool%.django%-stubs%](.-)\n%[')
        or content:match('%[tool%.django%-stubs%](.*)')
    if not section then
        return nil
    end

    return section:match(
        'django_settings_module%s*=%s*[\'"]([^\'"]+)[\'"]'
    )
end

--- Return `true` if in `termux` environment
--- @return boolean
function M.is_termux()
    -- check if `termux-setup-storage` command exists
    return vim.fn.executable('termux-setup-storage') == 1
end

--- Return `true` if editing the git file.
---
--- NOTE: uses filepath, not filetype, beause filetypes are sometimes
--- not there
--- @return boolean
function M.is_gitfile()
    return string.find(vim.fn.expand('%:p'), '%.git') ~= nil
end

--- Return `true` if no file is opened
function M.is_empty()
    return vim.fn.expand('%:p') == ''
end

--- Consume unused local to silence the diagnostic
function M.fake_use(...) end

--- Yes, it does what it says it does, it crashes the editor
function M.crash()
    M.crash()
end

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

--- Returns the path to project root using `.git` and optional extra markers.
--- @param markers? string|string[] additional files to indicate the root
--- @param toplevel? string path to a starting point, `.` by default
--- @param counter? number how many paths to take, default 25
function M.get_root(markers, toplevel, counter)
    local root_markers = { '.git' }
    if type(markers) == 'string' then
        table.insert(root_markers, markers)
    elseif markers then
        vim.list_extend(root_markers, markers)
    end

    local function find_root(path, depth)
        -- if reached the limit, give up
        if depth == 0 then
            return nil
        end

        -- search for stopfile
        local files = vim.fn.readdir(path)
        for _, f in ipairs(files) do
            if vim.tbl_contains(root_markers, f) then
                return path
            end
        end

        local parent = M.get_parent(path)
        if not parent then
            return nil
        end

        return find_root(parent, depth - 1)
    end

    return find_root(toplevel or vim.fn.getcwd(), counter or 25)
end

--- Find a file or directory in the current path or its ancestors.
---
--- The search checks only the current directory at each level and stops once
--- a stop marker is found. This avoids recursive downward scans in large trees.
---
--- @param names string|string[] files or directories to find
--- @param opts? {path?: string, stop?: string|string[], type?: string}
--- @return string?
function M.find_in_parents(names, opts)
    opts = opts or {}

    if type(names) == 'string' then
        names = { names }
    end

    local stop = opts.stop or { '.git' }
    if type(stop) == 'string' then
        stop = { stop }
    end

    local path = opts.path or vim.api.nvim_buf_get_name(0)
    if path == '' then
        path = vim.fn.getcwd()
    end

    path = M.absolute_path(path)

    local stat = vim.uv.fs_stat(path)
    if stat and stat.type ~= 'directory' then
        path = M.get_parent(path)
    end

    while path do
        for _, name in ipairs(names) do
            local candidate = vim.fs.joinpath(path, name)
            local candidate_stat = vim.uv.fs_stat(candidate)
            if
                candidate_stat
                and (not opts.type or candidate_stat.type == opts.type)
            then
                return candidate
            end
        end

        for _, marker in ipairs(stop) do
            local marker_path = vim.fs.joinpath(path, marker)
            if vim.uv.fs_stat(marker_path) then
                return nil
            end
        end

        path = M.get_parent(path)
    end
end

--- Return `true` if path belongs to a uv-managed project.
--- @param path string project root path
--- @return boolean
function M.is_uv_project(path)
    return vim.fn.executable('uv') == 1
        and vim.uv.fs_stat(vim.fs.joinpath(path, 'uv.lock')) ~= nil
end

--- Return `true` if path belongs to a pytest-configured project.
--- @param path string project root path
--- @return boolean
function M.is_pytest_project(path)
    if vim.uv.fs_stat(vim.fs.joinpath(path, 'pytest.toml')) then
        return true
    end
    if vim.uv.fs_stat(vim.fs.joinpath(path, '.pytest.toml')) then
        return true
    end
    if vim.uv.fs_stat(vim.fs.joinpath(path, 'pytest.ini')) then
        return true
    end
    if vim.uv.fs_stat(vim.fs.joinpath(path, '.pytest.ini')) then
        return true
    end
    if vim.uv.fs_stat(vim.fs.joinpath(path, 'conftest.py')) then
        return true
    end

    local pyproject = vim.fs.joinpath(path, 'pyproject.toml')
    if vim.fn.filereadable(pyproject) == 1 then
        local content = read_file(pyproject)
        if
            content:match('%[tool%.pytest%]')
            or content:match('%[tool%.pytest%.ini_options%]')
        then
            return true
        end
    end

    local tox = vim.fs.joinpath(path, 'tox.ini')
    if vim.fn.filereadable(tox) == 1 then
        local content = read_file(tox)
        if content:match('%[pytest%]') then
            return true
        end
    end

    local setup_cfg = vim.fs.joinpath(path, 'setup.cfg')
    if vim.fn.filereadable(setup_cfg) == 1 then
        local content = read_file(setup_cfg)
        if content:match('%[tool:pytest%]') then
            return true
        end
    end

    return false
end

--- Return `true` if path looks like a Django project root.
--- @param path string project root path
--- @return boolean
function M.is_django_project(path)
    return vim.uv.fs_stat(vim.fs.joinpath(path, 'manage.py')) ~= nil
end

--- Return Django settings module declared in project config.
--- @param path string project root path
--- @return string?
function M.get_django_settings_module(path)
    local pyproject = vim.fs.joinpath(path, 'pyproject.toml')
    if vim.fn.filereadable(pyproject) == 1 then
        local settings_module = match_django_settings_module_in_pyproject(
            read_file(pyproject)
        )
        if settings_module then
            return settings_module
        end
    end

    local manage_py = vim.fs.joinpath(path, 'manage.py')
    if vim.fn.filereadable(manage_py) ~= 1 then
        return nil
    end

    return match_django_settings_module(read_file(manage_py))
end

return M
