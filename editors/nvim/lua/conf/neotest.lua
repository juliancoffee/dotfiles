--- INFO: this module manages testing support for neovim

---@module 'lazy'

---@type LazyPluginSpec
local vim_test = {
    -- it's arguably much less pretty one, but at least it works
    'juliancoffee/vim-test',
    -- fork with UV support
    -- NOTE: doesn't autodetect django or anything
    branch = 'juliancoffee/add-uv',
    event = 'VeryLazy',
}

---@type LazyPluginSpec
local neotest = {
    'nvim-neotest/neotest',
    dependencies = {
        'nvim-neotest/nvim-nio',
        'nvim-lua/plenary.nvim',
        'antoinemadec/FixCursorHold.nvim',
        'nvim-treesitter/nvim-treesitter',
        {
            'juliancoffee/neotest-python',
            branch = 'juliancoffee/uv-support',
        },
    },
    event = 'VeryLazy',
    config = function()
        local python = require('neotest-python')
        local neotest = require('neotest')
        ---@diagnostic disable-next-line: missing-fields
        neotest.setup {
            adapters = {
                python {
                    -- TODO: doesn't seem to work for me anyway
                    dap = {
                        -- justMyCode = true,
                    },
                    -- TODO: doesn't work, for some reason
                    env = { DJANGO_SETTINGS_MODULE = 'mysite.settings' },
                    runner = 'django',
                    is_test_file = function(file_path)
                        local Path = require('plenary.path')
                        local neotest_default = require('neotest-python.base')

                        -- first filter stupid stuff
                        local elems = vim.split(file_path, Path.path.sep)
                        if vim.tbl_contains(elems, '__pycache__') then
                            return false
                        end

                        -- then try the default matcher
                        if neotest_default.is_test_file(file_path) then
                            return true
                        end

                        -- if all else fails, try custom logic
                        local file_name = elems[#elems]
                        return file_name == 'tests.py'
                    end,
                },
            },

            icons = {
                child_indent = '│',
                child_prefix = '├─',
                collapsed = '▸',
                expanded = '▾',
                failed = '✗',
                final_child_indent = ' ',
                final_child_prefix = '└─',
                non_collapsible = '─',
                notify = '🔔',
                passed = '✓',
                running = '⏱',
                running_animated = {
                    '⠋',
                    '⠙',
                    '⠹',
                    '⠸',
                    '⠼',
                    '⠴',
                    '⠦',
                    '⠧',
                    '⠇',
                    '⠏',
                },
                skipped = '⏭',
                unknown = '❓',
                watching = '👀',
            },
        }

        vim.keymap.set(
            'n',
            '<F2>',
            neotest.summary.toggle,
            { desc = 'Test summary' }
        )
        vim.keymap.set('n', '<F3>', function()
            neotest.run.run { vim.fn.expand('%'), suite = false }
        end, { desc = 'Run the file' })
        -- run the test under debugger (if supported)
        vim.keymap.set('n', '<F3>d', function()
            neotest.run.run { strategy = 'dap', suite = false }
        end, { desc = 'Run the file under [d]ebugger' })
        -- run the whole suite
        vim.keymap.set('n', '<F3>s', function()
            neotest.run.run { suite = true }
        end, { desc = 'Run the whole [s]uite' })
    end,
}

return {
    vim_test,
    neotest,
}
