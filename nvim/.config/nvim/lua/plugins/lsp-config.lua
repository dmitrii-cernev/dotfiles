return {
    {
        "mason-org/mason.nvim",
        opts = {}
    },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {
            ensure_installed = { "lua_ls", "pyright", "ruff", "jsonls" },
            automatic_installation = true,
        },
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
        },
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")
            -- lspconfig.lua_ls.setup({})
            -- lspconfig.pyright.setup({})
            vim.lsp.enable('lua_ls')
            vim.lsp.enable('pyright')
            vim.lsp.enable('ruff')
            vim.lsp.enable('jsonls')
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local bufnr = args.buf
                    local opts = { buffer = bufnr, noremap = true, silent = true }

                    -- Go to definition
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    -- Go to declaration
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    -- Show hover information
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                    -- Show signature help
                    vim.keymap.set('n', 'gK', vim.lsp.buf.signature_help, opts)
                    -- Rename symbol
                    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, opts, { desc = "LSP Rename" })
                    -- Show code actions
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts, { desc = "LSP Code Action" })
                    -- Format buffer
                    vim.keymap.set('n', '<leader>cf', function()
                        vim.lsp.buf.format({ async = true })
                    end, opts, { desc = "LSP Format Buffer" })
                    -- Show diagnostics
                    vim.keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
                    -- Navigate diagnostics
                    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
                    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
                end,
            })
        end
    }
}
