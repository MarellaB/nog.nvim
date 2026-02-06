-- nog.nvim - Blog Manager for Neovim
-- Write and publish blurbs and posts to your personal blog

local M = {}

-- Default configuration
M.config = {
  api = {
    base_url = nil,
    endpoints = {
      blurbs = "/api/blurbs",
      posts = "/api/posts",
    },
  },
  storage_path = vim.fn.stdpath("data") .. "/nog",
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
end

return M
