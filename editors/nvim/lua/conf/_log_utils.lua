-- INFO: module with logging-related utilities

local M = {}
local logging_enabled = false

--- Append one formatted log entry to a file.
---
--- If `msg` contains multiple lines, each line receives the same timestamp
--- and level prefix so stack traces remain readable after later grepping.
---
--- @param path string absolute log file path
--- @param level string log level label
--- @param msg string|string[] message payload
function M.append_log(path, level, msg)
    local lines = type(msg) == 'table' and msg or vim.split(tostring(msg), '\n')
    local prefix =
        string.format('[%s][%s] ', os.date('%Y-%m-%d %H:%M:%S'), level)
    local payload = {}

    for _, line in ipairs(lines) do
        table.insert(payload, prefix .. line)
    end

    vim.fn.writefile(payload, path, 'a')
end

--- Enable persistent Neovim error-oriented logging.
---
--- This wires together Neovim's custom logging surfaces so startup and
--- plugin failures are harder to lose:
--- * `nvim.log` for `WARN`, `ERROR`, `ERRMSG`, and `:messages`
--- * `lsp.log` kept separate for the built-in LSP logger
---
--- The setup is idempotent and safe to call multiple times.
function M.enable_persistent_error_logging()
    local main_log = vim.fs.joinpath(vim.fn.stdpath('log'), 'nvim.log')

    if vim.env.LSP_DEBUG then
        local lsp_debug_log =
            vim.fs.joinpath(vim.fn.stdpath('state'), 'lsp-debug.log')
        vim.lsp.log._set_filename(lsp_debug_log)
        vim.lsp.log.set_level('debug')
    end

    if not logging_enabled then
        local original_notify = vim.notify
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, level, notify_opts)
            local label = tostring(level or 'INFO')

            if type(level) == 'number' then
                for name, value in pairs(vim.log.levels) do
                    if value == level then
                        label = name
                        break
                    end
                end
            end

            if label == 'WARN' or label == 'ERROR' then
                M.append_log(main_log, label, msg)
            end
            return original_notify(msg, level, notify_opts)
        end

        vim.api.nvim_create_autocmd('VimLeavePre', {
            group = vim.api.nvim_create_augroup('PersistentErrorLogging', {
                clear = true,
            }),
            callback = function()
                local messages = vim.api.nvim_exec2('silent messages', {
                    output = true,
                }).output

                if messages ~= '' then
                    M.append_log(main_log, 'MESSAGES', messages)
                end

                if vim.v.errmsg ~= '' then
                    M.append_log(main_log, 'ERRMSG', vim.v.errmsg)
                end
            end,
        })

        logging_enabled = true
    end
end

return M
