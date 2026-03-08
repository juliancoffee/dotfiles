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
        local utils = require('null-ls.utils')
        return {
            sources = {
                null_ls.builtins.diagnostics.mypy.with {
                    command = 'uv',
                    args = function(params)
                        -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/1208
                        return {
                            'run',
                            '--dev',
                            'mypy',
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
                        }
                    end,
                    -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/1208#issuecomment-1345356975
                    runtime_condition = function(params)
                        return utils.path.exists(params.bufname)
                    end,
                },
            },
        }
    end,
}
