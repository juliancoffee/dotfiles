--- INFO: this module manages debugging support for neovim

---@module 'lazy'
---@module 'dapui'

---@type LazyPluginSpec
local dap_python = {
    'mfussenegger/nvim-dap-python',
    event = 'VeryLazy',
    config = function()
        require('dap-python').setup('uv')
    end,
}

---@type LazyPluginSpec
local dap_ui = {
    'rcarriga/nvim-dap-ui',
    dependencies = {
        'nvim-neotest/nvim-nio',
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
    dependencies = { dap_ui, dap_python },
    config = function()
        local dap = require('dap')
        dap.set_log_level('DEBUG')

        vim.keymap.set('n', '<F5>', dap.continue, { desc = 'DAP: Continue' })
        vim.keymap.set(
            'n',
            '<leader>b',
            dap.toggle_breakpoint,
            { desc = 'DAP: Continue' }
        )

        local dapui = require('dapui')
        -- open on connect
        dap.listeners.before.attach.dapui_config = dapui.open
        dap.listeners.before.launch.dapui_config = dapui.open
        -- close on disconnect
        dap.listeners.before.disconnect.dapui_config = dapui.close
        dap.listeners.before.event_terminated.dapui_config = dapui.close
        dap.listeners.before.event_exited.dapui_config = dapui.close

        vim.keymap.set('n', '<leader>de', dapui.eval, { desc = 'DAP: Eval' })
        vim.keymap.set('n', '<leader>dq', dapui.close, { desc = 'DAP: Close' })
    end,
}

---@type LazySpec
return {
    dap,
    {
        -- it's arguably much less pretty one, but at least it works
        'juliancoffee/vim-test',
        -- fork with UV support
        branch = 'juliancoffee/add-uv',
        event = 'VeryLazy',
    },
}
