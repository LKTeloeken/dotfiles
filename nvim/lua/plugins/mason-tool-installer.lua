return { -- Make sure the formatters/linters used by none-ls are installed
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require("mason").setup({})
      require("mason-tool-installer").setup({
        -- LSP servers live in mason-lspconfig's ensure_installed (plugins/lsp-config.lua);
        -- this list is only for tools used as none-ls sources (plugins/prettier.lua)
        ensure_installed = {
          "prettierd",
          "black",
        },
        run_on_start = true,
      })
    end,
  }
}
