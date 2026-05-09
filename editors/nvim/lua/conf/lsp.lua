--- INFO:
--- This module holds the plugin configuration for LSP and tool installation

---@module 'lazy'

local utils = require('conf._utils')
local codelens_method = vim.lsp.protocol.Methods.textDocument_codeLens
local codelens_namespace_prefix = 'nvim.lsp.codelens:'
local codelens_extmark_patch_installed = false

-- Return the namespace name for one extmark namespace id.
-- This lets us target Neovim's built-in codelens extmarks without touching
-- unrelated virtual text from other features.
local namespace_name = function(namespace)
    for name, id in pairs(vim.api.nvim_get_namespaces()) do
        if id == namespace then
            return name
        end
    end
end

-- Find the leading indentation for one line.
-- We reuse the line's own indentation so codelenses attach to the first
-- visible character instead of drifting to the exact symbol column.
local line_indent = function(buffer, line)
    local text = vim.api.nvim_buf_get_lines(buffer, line, line + 1, false)[1]

    if type(text) ~= 'string' then
        return ''
    end

    return string.match(text, '^%s*') or ''
end

-- Normalize Neovim's built-in codelens extmarks.
-- Neovim 0.12 pads codelenses to the symbol column, which makes them look
-- random in indented code. Replace that padding with the target line's
-- indentation so the lens attaches to the first non-empty character instead.
local normalize_codelens_extmark_opts = function(buffer, line, opts)
    if not (opts and opts.virt_lines and opts.virt_lines_above) then
        return opts
    end

    local virt_lines = vim.deepcopy(opts.virt_lines)
    local first_line = virt_lines[1]
    local first_chunk = first_line and first_line[1]
    local first_text = first_chunk and first_chunk[1]

    if type(first_text) == 'string' and string.match(first_text, '^%s+$') then
        local indent = line_indent(buffer, line)
        first_line[1] = { indent, first_chunk[2] }

        if vim.tbl_isempty(first_line) then
            table.insert(first_line, { '', 'LspCodeLens' })
        end
    end

    return vim.tbl_extend('force', opts, {
        virt_lines = virt_lines,
    })
end

-- Patch Neovim's codelens renderer once.
-- The built-in renderer uses a regular extmark call, so a tiny wrapper is the
-- least invasive way to keep codelenses readable until upstream exposes a real
-- layout option for them.
local patch_codelens_extmarks = function()
    if codelens_extmark_patch_installed then
        return
    end

    local original_set_extmark = vim.api.nvim_buf_set_extmark

    vim.api.nvim_buf_set_extmark = function(
        buffer,
        namespace,
        line,
        column,
        opts
    )
        local name = namespace_name(namespace)

        if
            name
            and vim.startswith(name, codelens_namespace_prefix)
            and opts
        then
            opts = normalize_codelens_extmark_opts(buffer, line, opts)
        end

        return original_set_extmark(buffer, namespace, line, column, opts)
    end

    codelens_extmark_patch_installed = true
end

-- Enable codelens for one buffer.
-- Neovim refreshes enabled codelenses automatically, so we only need to turn
-- the feature on for buffers that actually have supporting clients.
local enable_codelens = function(bufnr)
    local codelens_clients = vim.lsp.get_clients {
        bufnr = bufnr,
        method = codelens_method,
    }

    if vim.tbl_isempty(codelens_clients) then
        return
    end

    vim.lsp.codelens.enable(true, { bufnr = bufnr })
end

-- Run code on LSP attach
--
-- Mostly setting some useful keymaps
local on_attach = function(event)
    -- Shortcut to create commands
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
        '<leader>sl',
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

    if client and client:supports_method(codelens_method, event.buf) then
        map('grx', vim.lsp.codelens.run, 'Run Code Lens')
        enable_codelens(event.buf)
    end

    -- Disable semantic highlighting
    if client then
        client.server_capabilities.semanticTokensProvider = nil
    end

    -- Disable bashls on `.env` files, that's kind of hillarious
    local bufname = vim.api.nvim_buf_get_name(event.buf)
    if string.match(bufname, '%.env') then
        vim.diagnostic.enable(false, { bufnr = event.buf })
    end
end

---@type LazyPluginSpec
return {
    'neovim/nvim-lspconfig',
    -- NOTE: you can't lazyload LSP for some unfortunate reason :(
    lazy = false,
    -- Disable LSP if in termux or editing a git file
    --
    -- I also wanted to disable it for empty files, but it would disable it
    -- forever until I exit & re-open the editor
    cond = function()
        local is_gitfile = utils.is_gitfile()
        local is_termux = utils.is_termux()

        return not is_gitfile and not is_termux
    end,
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
        -- upstream JSON/YAML schema catalog helpers
        'b0o/SchemaStore.nvim',
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
        local schemastore = require('schemastore')

        patch_codelens_extmarks()

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
        local managed = {
            lua_ls = {},
            cssls = {},
            bashls = {},
            dockerls = {},
            jsonls = {
                settings = {
                    json = {
                        schemas = schemastore.json.schemas(),
                        validate = { enable = true },
                    },
                },
            },
            yamlls = {
                settings = {
                    yaml = {
                        -- Use SchemaStore.nvim as the single schema source.
                        schemaStore = {
                            enable = false,
                            url = '',
                        },
                        schemas = schemastore.yaml.schemas(),
                        validate = true,
                        keyOrdering = false,
                    },
                },
            },
            taplo = {
                cmd = (function()
                    local cargo_taplo = vim.fs.normalize(
                        vim.fn.expand '~/.cargo/bin/taplo'
                    )

                    if vim.uv.fs_stat(cargo_taplo) then
                        return {
                            cargo_taplo,
                            'lsp',
                            'stdio',
                        }
                    end
                end)(),
                settings = {
                    evenBetterToml = {
                        schema = {
                            enabled = true,
                        },
                    },
                },
            },
            vtsls = {},
            ocamllsp = {},
            rust_analyzer = {
                settings = {
                    ['rust-analyzer'] = {
                        check = {
                            command = 'clippy',
                        },
                    },
                },
            },
            basedpyright = {
                cmd = function(dispatchers, config)
                    local root = config.root_dir
                    local cmd

                    if utils.is_uv_project(root) then
                        cmd = {
                            'uv',
                            'run',
                            '--dev',
                            'basedpyright-langserver',
                            '--stdio',
                        }
                    else
                        cmd = {
                            'basedpyright-langserver',
                            '--stdio',
                        }
                    end

                    return vim.lsp.rpc.start(cmd, dispatchers)
                end,
                settings = {
                    -- let ruff/isort handle it
                    disableOrganizeImports = true,
                    basedpyright = {
                        analysis = {
                            -- let ruff/mypy handle it
                            typeCheckingMode = 'off',
                        },
                    },
                },
            },
            ruff = {},
        }
        local external = {
            fluent_lsp = {
                cmd = { 'fluent-lsp' },
                filetypes = { 'fluent' },
                root_markers = { 'fluent-lsp.toml', '.fluent-lsp.toml' },
                workspace_required = true,
            },
        }

        -- only load rust-analyzer if not banned
        if utils.find_at_root('nolsp', { type = 'file' }) then
            managed.rust_analyzer = nil
        end

        -- Install needed tools
        local ensure_installed = vim.tbl_keys(managed or {})
        vim.list_extend(ensure_installed, {
            'stylua',
            'isort',
            'prettier',
            'fixjson',
            'shfmt',
        })

        require('mason-tool-installer').setup {
            ensure_installed = ensure_installed,
        }

        -- Register servers for neovim
        local servers = vim.tbl_extend('force', managed, external)
        for name, server in pairs(servers) do
            server.capabilities = vim.tbl_deep_extend(
                'force',
                {},
                capabilities,
                server.capabilities or {}
            )
            vim.lsp.config(name, server)
            vim.lsp.enable(name)
        end
    end,
}
