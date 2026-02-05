-- nog.nvim - Blog Manager for Neovim
-- Write and publish blurbs and posts to your personal blog

local M = {}

-- Default configuration
M.config = {
  api = {
    base_url = nil,
    endpoints = {
      blurbs = "/api/blurbs", -- Internal: blurbs endpoint (maps to blurbs)
      posts = "/api/posts",
    },
  },
  storage_path = vim.fn.stdpath("data") .. "/nog",
  keymaps = {
    toggle = nil, -- Optional global keymap (set to e.g. "<leader>b")
  },
  ui = {
    width = 0.5,
    height = 0.3,
  },
}

-- Toggle the nog UI
function M.toggle()
  local ui = require("nog.ui")

  if ui.is_open() then
    ui.close_all()
  else
    ui.show_blurb()
  end
end

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Setup submodules
  local storage = require("nog.storage")
  storage.setup({ storage_path = M.config.storage_path })

  local api = require("nog.api")
  api.setup(M.config.api)

  local window = require("nog.window")
  window.setup(M.config.ui)

  -- Create user command
  vim.api.nvim_create_user_command("NogToggle", function()
    M.toggle()
  end, { desc = "Toggle Nog blog manager" })

  -- Create help command
  vim.api.nvim_create_user_command("NogHelp", function()
    M.show_help()
  end, { desc = "Show Nog keybindings" })

  -- Set up global keymap if configured
  if M.config.keymaps.toggle then
    vim.keymap.set("n", M.config.keymaps.toggle, function()
      M.toggle()
    end, { silent = true, desc = "Toggle Nog" })
  end
end

-- Show help with keybindings
function M.show_help()
  local help_text = [[
Nog - Blog Manager Keybindings
==============================

Blurb Composer (default view):
  <C-p>     - Publish blurb
  p         - Go to post composer
  t         - Browse published blurbs
  P         - Browse published posts
  q         - Close (auto-saves draft)

Post Composer:
  r         - Insert reference to blurb/post
  <C-p>     - Publish post
  <Esc>     - Back to blurb composer
  q         - Close (auto-saves draft)

Browse Views:
  j/k       - Navigate up/down
  <Enter>   - View full content
  y         - Copy ID to clipboard
  <Esc>     - Back to blurb composer
  q         - Close

View Content:
  <Esc>     - Back to browse list
  q         - Close

Reference Picker:
  <Tab>     - Switch between blurbs/posts
  j/k       - Navigate
  <Enter>   - Select and insert reference
  <Esc>     - Cancel

Reference Syntax:
  {{blurb:id}} - Reference a blurb
  {{post:id}}  - Reference a post
]]

  -- Display in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local lines = vim.split(help_text, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = 50
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Nog Help ",
    title_pos = "center",
  })

  -- Close on any key
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, noremap = true, silent = true })
end

return M
