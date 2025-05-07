--- INFO: this module manages debugging support for neovim

---@module 'lazy'
---@module 'dapui'

---@type LazyPluginSpec
local dap_ui = {
    'rcarriga/nvim-dap-ui',
    dependencies = {
        -- utility dependency
        'nvim-neotest/nvim-nio',
        -- adds variable information as virtual text
        { 'theHamsta/nvim-dap-virtual-text', opts = {} },
    },
    event = 'VeryLazy',
    ---@type dapui.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        icons = {
            expanded = '-',
            collapsed = '+',
            current_frame = '>',
        },
        ---@diagnostic disable-next-line: missing-fields
        controls = {
            icons = {
                pause = '||', -- pause
                play = '▶', -- play
                step_into = '↓', -- step into
                step_over = '→', -- step over
                step_out = '↑', -- step out
                step_back = '←', -- step back
                run_last = '↻', -- run last
                terminate = '✖', -- terminate
                disconnect = '⏏', -- eject / disconnect
            },
        },
    },
}

---@type LazySpec
local dap = {
    'mfussenegger/nvim-dap',
    event = 'VeryLazy',
    dependencies = {
        dap_ui,
        'mfussenegger/nvim-dap-python',
        'jbyuki/one-small-step-for-vimkind',
    },
    config = function()
        local dap = require('dap')
        local dapui = require('dapui')

        --
        -- setup
        --
        -- enable logging
        dap.set_log_level('DEBUG')
        -- init python adapter
        require('dap-python').setup('uv')
        -- init osv adapter
        -- we're overwriting it, hopefully this won't cause trouble :D
        dap.configurations.lua = {
            {
                type = 'nlua',
                request = 'attach',
                name = 'attach to neovim instance',
            },
        }

        dap.adapters.nlua = function(callback, config)
            callback {
                type = 'server',
                host = config.host or '127.0.0.1',
                port = config.port or 8086,
            }
        end

        --
        -- breakpoint keymap
        --
        vim.keymap.set(
            'n',
            '<leader>b',
            dap.toggle_breakpoint,
            { desc = 'DAP: Toggle [B]reakpoint' }
        )

        --
        -- execution keymaps, continue, step_over, step_into, etc
        --
        for _, key in ipairs { '<F5>', '<leader>dc' } do
            vim.keymap.set('n', key, dap.continue, { desc = 'DAP: [C]ontinue' })
        end
        vim.keymap.set(
            'n',
            '<leader>ds',
            dap.step_over,
            { desc = 'DAP: [S]tep Over' }
        )
        vim.keymap.set(
            'n',
            '<leader>di',
            dap.step_into,
            { desc = 'DAP: Step [I]nto' }
        )

        --
        -- visualization keymaps
        --
        vim.keymap.set('n', '<leader>de', function()
            ---@diagnostic disable-next-line: missing-fields
            dapui.eval(nil, { enter = true })
        end, { desc = 'DAP: [E]val' })

        vim.keymap.set(
            'n',
            '<leader>do',
            dap.repl.open,
            { desc = 'DAP: [O]pen Repl' }
        )
        vim.keymap.set(
            'n',
            '<leader>dq',
            dap.repl.close,
            { desc = 'DAP: [Q]uit Repl' }
        )

        --
        -- keymaps for special stuff
        --
        vim.keymap.set('n', '<leader>dl', function()
            -- [O]ne[S]mallstepfor[V]imkind
            require('osv').launch { port = 8086 }
        end, { noremap = true, desc = 'DAP: Launch Vim debugger' })
    end,
}

---@type LazySpec
return {
    dap,
}
