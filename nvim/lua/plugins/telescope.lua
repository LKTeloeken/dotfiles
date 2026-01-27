return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function ()
      require('telescope').setup({
      defaults = {
        file_ignore_patterns = { ".git/", "node_modules/", "*.stories.*", "*.lock" },
        hidden = true,
        no_ignore = true, -- Search in .gitignore
        case_mode = "smart_case",
        theme = "dropdown",
        path_display = { "filename_first" }
      },
      pickers = {
        find_files = {
          theme = "dropdown",
        },
        live_grep = {
          theme = "dropdown",
        },
      }
    })
    require('telescope').load_extension('fzf')
  end,
  keys = {
    {
      "<leader>ff",
      "<cmd>Telescope find_files hidden=true<CR>",
      mode = "n"
    },
    {
      "<leader>fg",
      "<cmd>Telescope live_grep<CR>",
      mode = "n"
    },
    {
      "<leader>fb",
      "<cmd>Telescope buffers<CR>",
      mode = "n"
    },
    {
      "<leader>fh",
      "<cmd>Telescope help_tags<CR>",
      mode = "n"
    },
    {
      "gd",
      "<cmd>Telescope lsp_definitions<CR>",
      mode = "n"
    },
    {
      "gr",
      "<cmd>Telescope lsp_references<CR>",
      mode = "n"
    },
  },
}
