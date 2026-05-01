--- INFO:
--- This module holds the plugin configuration for linters

---@module 'lazy'
---@module 'null-ls'

---@type LazyPluginSpec
return {
    'nvimtools/none-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = { 'BufWritePre' },
    opts = function()
        local null_ls = require('null-ls')
        local config_utils = require('conf._utils')
        local null_ls_utils = require('null-ls.utils')
        return {
            sources = {
                null_ls.builtins.diagnostics.mypy.with {
                    command = function(params)
                        if config_utils.is_uv_project(params.root) then
                            return 'uv'
                        else
                            return 'mypy'
                        end
                    end,
                    args = function(params)
                        -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/1208
                        local args = {}
                        if config_utils.is_uv_project(params.root) then
                            vim.list_extend(args, {
                                'run',
                                '--dev',
                                'mypy',
                            })
                        end

                        vim.list_extend(args, {
                            '--hide-error-context',
                            '--no-color-output',
                            '--show-column-numbers',
                            '--show-error-codes',
                            '--no-error-summary',
                            '--no-pretty',
                            '--shadow-file',
                            params.bufname,
                            params.temp_path,
                            params.bufname,
                        })
                        return args
                    end,
                    -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/1208#issuecomment-1345356975
                    runtime_condition = function(params)
                        return null_ls_utils.path.exists(params.bufname)
                    end,
                },
            },
        }
    end,
}
