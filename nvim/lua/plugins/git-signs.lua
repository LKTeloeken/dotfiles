return { -- Git related, signs, blame...
  "lewis6991/gitsigns.nvim",
  lazy = false,
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 200,
    },

    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
  },

  keys = {
    {
      "<leader>gb",
      function() require("gitsigns").blame() end,
      desc = "[G]it [B]lame",
    },
  },
}
