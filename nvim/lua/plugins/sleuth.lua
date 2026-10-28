return { -- Detect tabstop/shiftwidth from the file or the surrounding project
  --
  -- Keeps typing indentation in sync with whatever the project already uses
  -- (prettier, gofmt, black), instead of falling back to Neovim's 8-wide tab.
  "tpope/vim-sleuth",
}
