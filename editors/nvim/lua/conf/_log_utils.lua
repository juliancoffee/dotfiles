-- INFO: module with logging-related utilities

local M = {}
local logging_enabled = false
local default_notify_level = vim.log.levels.INFO

--- Return an absolute path for one Neovim state log file.
--- @param name string basename without `.log`
--- @return string
function M.state_log_path(name)
    return vim.fs.joinpath(vim.fn.stdpath('state'), name .. '.log')
end

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

--- Convert one numeric `vim.notify` level into a stable string label.
--- @param level? integer|string
--- @return string
function M.notify_level_name(level)
    if type(level) ~= 'number' then
        return tostring(level or 'INFO')
    end

    for name, value in pairs(vim.log.levels) do
        if value == level then
            return name
        end
    end

    return tostring(level)
end

--- Enable persistent Neovim error-oriented logging.
---
--- This wires together Neovim's separate logging surfaces so startup and
--- plugin failures are harder to lose:
--- * `verbose.log` via `verbosefile`
--- * `session.log` via `vim.notify` mirroring and lifecycle markers
--- * `messages.log` via `:messages` dump on exit
--- * `lsp.log` via debug-level LSP logging
---
--- The setup is idempotent and safe to call multiple times.
---
--- @param opts? {session_log?: string, verbose_log?: string, messages_log?: string, verbose?: integer, lsp_log_level?: string|integer, notify_log_level?: integer}
function M.enable_persistent_error_logging(opts)
    local logging_state = {}
    opts = opts or {}

    logging_state.session_log = opts.session_log or M.state_log_path('session')
    logging_state.verbose_log = opts.verbose_log or M.state_log_path('verbose')
    logging_state.messages_log = opts.messages_log
        or M.state_log_path('messages')
    logging_state.notify_log_level = opts.notify_log_level
        or default_notify_level

    vim.opt.verbosefile = logging_state.verbose_log
    vim.opt.verbose = opts.verbose or 1

    if vim.lsp and vim.lsp.log and vim.lsp.log.set_level then
        local ok, err =
            pcall(vim.lsp.log.set_level, opts.lsp_log_level or 'debug')
        if not ok then
            M.append_log(
                logging_state.session_log,
                'ERROR',
                'Failed to set LSP log level: ' .. tostring(err)
            )
        end
    else
        M.append_log(
            logging_state.session_log,
            'WARN',
            'LSP log level hook unavailable: vim.lsp.log.set_level'
                .. ' is missing'
        )
    end

    if not logging_enabled then
        local original_notify = vim.notify
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, level, notify_opts)
            local numeric_level = type(level) == 'number' and level
                or logging_state.notify_log_level
            if numeric_level >= logging_state.notify_log_level then
                M.append_log(
                    logging_state.session_log,
                    M.notify_level_name(level),
                    msg
                )
            end
            return original_notify(msg, level, notify_opts)
        end

        vim.api.nvim_create_autocmd('VimLeavePre', {
            group = vim.api.nvim_create_augroup('PersistentErrorLogging', {
                clear = true,
            }),
            callback = function()
                local ok, messages = pcall(function()
                    return vim.api.nvim_exec2('silent messages', {
                        output = true,
                    }).output
                end)

                if ok and messages ~= '' then
                    vim.fn.writefile(
                        vim.split(messages, '\n'),
                        logging_state.messages_log,
                        'a'
                    )
                end

                if vim.v.errmsg ~= '' then
                    M.append_log(
                        logging_state.session_log,
                        'ERRMSG',
                        vim.v.errmsg
                    )
                end

                M.append_log(
                    logging_state.session_log,
                    'INFO',
                    '=== nvim session end ==='
                )
            end,
        })

        logging_enabled = true
    end

    M.append_log(
        logging_state.session_log,
        'INFO',
        '=== nvim session start ==='
    )
end

return M
