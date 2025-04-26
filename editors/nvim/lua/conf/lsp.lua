--- INFO:
--- This module holds the plugin configuration for LSP and tool installation

---@module 'lazy'

-- Run code on LSP attach
--
-- Mostly setting some useful keymaps
local on_attach = function(event)
    -- Shorcut to create commands
    local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, {
            buffer = event.buf,
            desc = 'LSP: ' .. desc,
        })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- Find references for the word under your cursor.
    map(
        'grr',
        require('telescope.builtin').lsp_references,
        '[G]oto [R]eferences'
    )

    -- Jump to the implementation of the word under your cursor.
    --  Useful when your language has ways of declaring types without
    --  an actual implementation.
    map(
        'gri',
        require('telescope.builtin').lsp_implementations,
        '[G]oto [I]mplementation'
    )

    -- Jump to the definition of the word under your cursor.
    --  This is where a variable was first declared, or where a function
    --  is defined, etc.
    --  To jump back, press <C-t>.
    map(
        'gd',
        require('telescope.builtin').lsp_definitions,
        '[G]oto [D]efinition'
    )

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- Fuzzy find all the symbols in your current document.
    --  Symbols are things like variables, functions, types, etc.
    map(
        'gO',
        require('telescope.builtin').lsp_document_symbols,
        'Open Document Symbols'
    )

    -- Fuzzy find all the symbols in your current workspace.
    --  Similar to document symbols, except searches over your entire project.
    map(
        'gW',
        require('telescope.builtin').lsp_dynamic_workspace_symbols,
        'Open Workspace Symbols'
    )

    -- Jump to the type of the word under the cursor.
    --  Useful when you're not sure what type a variable is and you want to see
    --  the definition of its *type*, not where it was *defined*.
    map(
        'grt',
        require('telescope.builtin').lsp_type_definitions,
        '[G]oto [T]ype Definition'
    )

    -- Going for fun stuff
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Highlight references when not moving the cursor
    if
        client
        and client:supports_method(
            vim.lsp.protocol.Methods.textDocument_documentHighlight,
            event.buf
        )
    then
        local highlight_augroup = vim.api.nvim_create_augroup(
            'kickstart-lsp-highlight',
            { clear = false }
        )

        -- Actual event callback
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
        })

        -- Reset on move
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
        })

        -- Reset when LSP is detached
        vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup(
                'kickstart-lsp-detach',
                { clear = true }
            ),
            callback = function(detach_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds {
                    group = 'kickstart-lsp-highlight',
                    buffer = detach_event.buf,
                }
            end,
        })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if
        client
        and client:supports_method(
            vim.lsp.protocol.Methods.textDocument_inlayHint,
            event.buf
        )
    then
        map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {
                bufnr = event.buf,
            })
        end, '[T]oggle Inlay [H]ints')
    end
end

---@type LazyPluginSpec
return {
    'neovim/nvim-lspconfig',
    dependencies = {
        -- to install other LSPs
        { 'williamboman/mason.nvim', opts = {} },
        -- mason lspconfig bridge
        'williamboman/mason-lspconfig.nvim',
        -- install additional tools
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        -- status UI
        { 'j-hui/fidget.nvim', opts = {} },
        -- more completion capabilities
        'saghen/blink.cmp',
        {
            -- Add vim info to lua lsp
            'folke/lazydev.nvim',
            ft = 'lua',
            ---@module 'lazydev'
            ---@type lazydev.Config
            ---@diagnostic disable-next-line: missing-fields
            opts = {
                library = {
                    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
                },
            },
        },
    },
    config = function()
        -- Add autocommand for LSP attach event
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-attach', {
                clear = true,
            }),
            callback = on_attach,
        })

        -- Diagnostics configuration
        vim.diagnostic.config {
            -- Use virtual text to display errors
            virtual_text = true,
            -- And not signs, because they shift the number line
            signs = false,
        }

        -- Configuring servers and capabilities
        local capabilities = require('blink.cmp').get_lsp_capabilities()
        local servers = {
            lua_ls = {},
            ruff = {},
        }

        -- Install needed tools
        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
            'stylua',
        })

        require('mason-tool-installer').setup {
            ensure_installed = ensure_installed,
        }

        -- configure ... stuff?
        require('mason-lspconfig').setup {
            -- set this to empty, install via tool-insaller instead
            ensure_installed = {},
            automatic_installation = false,
            handlers = {
                function(server_name)
                    local server = servers[server_name] or {}
                    -- merge default capabilities and server capabilities
                    -- to potentially disabled unneded stuff
                    server.capabilities = vim.tbl_deep_extend(
                        'force',
                        {},
                        capabilities,
                        server.capabilities or {}
                    )
                    require('lspconfig')[server_name].setup(server)
                end,
            },
        }
    end,
}
