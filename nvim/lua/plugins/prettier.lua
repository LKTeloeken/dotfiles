return { -- Format on save with null-ls and prettier.nvim
  {
    'MunifTanjim/prettier.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      'nvimtools/none-ls.nvim', -- replacement for null-ls.nvim 
    },
    config = function()
      local null_ls = require("null-ls")

      -- Only let null-ls (prettierd/black) format; otherwise ts_ls competes and overwrites it
      local function format(bufnr, async)
        vim.lsp.buf.format({
          bufnr = bufnr,
          async = async,
          filter = function(client) return client.name == "null-ls" end,
        })
      end

      local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
      local event = "BufWritePre" -- or "BufWritePost"
      local async = event == "BufWritePost"

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.prettierd,
          null_ls.builtins.formatting.black,
        },
        on_attach = function(client, bufnr)
          if client:supports_method("textDocument/formatting") then
            vim.keymap.set("n", "<Leader>f", function()
              format(vim.api.nvim_get_current_buf(), false)
            end, { buffer = bufnr, desc = "[lsp] format" })

            -- format on save
            vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
            vim.api.nvim_create_autocmd(event, {
              buffer = bufnr,
              group = group,
              callback = function()
                format(bufnr, async)
              end,
              desc = "[lsp] format on save",
            })
          end

          if client:supports_method("textDocument/rangeFormatting") then
            vim.keymap.set("x", "<Leader>f", function()
              format(vim.api.nvim_get_current_buf(), false)
            end, { buffer = bufnr, desc = "[lsp] format" })
          end
        end,
      })

      local prettier = require("prettier")

      prettier.setup({
        bin = "prettierd",
        filetypes = {
          "css",
          "html",
          "javascript",
          "javascriptreact",
          "json",
          "less",
          "markdown",
          "scss",
          "typescript",
          "typescriptreact",
          "yaml",
        },
      })
    end,
  }
}
