--- INFO: this module manages testing support for neovim
---@module 'lazy'

local utils = require('conf._utils')

---@type LazyPluginSpec
local vim_test = {
    -- it's arguably much less pretty one, but at least it works
    'vim-test/vim-test',
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
        'nvim-neotest/neotest-python',
    },
    event = 'VeryLazy',
    config = function()
        local python = require('neotest-python')
        local neotest = require('neotest')
        local root = utils.get_root {
            'uv.lock',
            'pyproject.toml',
            'manage.py',
            'pytest.toml',
            '.pytest.toml',
            'pytest.ini',
            '.pytest.ini',
            'tox.ini',
            'setup.cfg',
            'conftest.py',
        }
        local runner = 'unittest'
        local django_settings_module

        if root and utils.is_pytest_project(root) then
            runner = 'pytest'
        elseif root and utils.is_django_project(root) then
            runner = 'django'
            django_settings_module = utils.get_django_settings_module(root)
        end

        ---@diagnostic disable-next-line: missing-fields
        neotest.setup {
            ---@diagnostic disable-next-line: missing-fields
            run = {
                augment = function(tree, args)
                    utils.fake_use(tree)

                    if django_settings_module then
                        args.env = args.env or {}
                        args.env.DJANGO_SETTINGS_MODULE = django_settings_module
                    end

                    return args
                end,
            },
            adapters = {
                python {
                    -- TODO: doesn't seem to work for me anyway
                    dap = {
                        justMyCode = false,
                    },
                    runner = runner,
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
                final_child_indent = ' ',
                final_child_prefix = '└─',
                collapsed = '▸',
                expanded = '▾',
                non_collapsible = '─',
                passed = '✓',
                failed = '✗',
                notify = '🔔',
                test = '🔔',
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
        -- run the whole file
        vim.keymap.set('n', '<F3>', function()
            neotest.run.run { vim.fn.expand('%'), suite = false }
        end, { desc = 'Run the file' })

        -- run single individual nearest test
        vim.keymap.set('n', '<F3>i', function()
            neotest.run.run()
        end, { desc = 'Run the [i]ndividual test' })

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
