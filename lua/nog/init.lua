local window = require("nog.window")

local M = {}

M.toggle = function()
  -- Check if window already exists, if so, close everything
  if M.backdrop_win and vim.api.nvim_win_is_valid(M.backdrop_win) then
    vim.api.nvim_win_close(M.backdrop_win, true)  -- Close backdrop
    vim.api.nvim_win_close(M.top_win, true)  -- Close top window
    vim.api.nvim_win_close(M.bot_win, true)  -- Close bottom window
    M.backdrop_win = nil
    M.top_buf = nil
    M.bot_buf = nil
    M.top_win = nil
    M.bot_win = nil
    return
  end

  -- Create backdrop FIRST
  M.backdrop_win = window.create_backdrop()

  -- Create top and bottom windows
  M.top_buf, M.top_win, M.bot_buf, M.bot_win = window.create_stacked_window()

  vim.bo[M.top_buf].buftype = 'nofile'
  vim.bo[M.bot_buf].buftype = 'nofile'

  vim.bo[M.top_buf].modifiable = false
  vim.bo[M.bot_buf].modifiable = true

  -- Load the nog.md file
  local nog_file = vim.fn.expand('~/nog.md')

  -- Check if the file exists, create if not
  if vim.fn.filereadable(nog_file) == 0 then
    vim.fn.writefile({"# Nog Todo List", "", "- [ ] First Task"}, nog_file)
  end

end

-- Setup method to
M.setup = function(opts)
  vim.api.nvim_create_user_command("NogToggle", function()
    M.toggle()
  end, {})

  -- Configure Keybinds to close
  vim.keymap.set("n", "q", function()
    if M.backdrop_win and vim.api.nvim_win_is_valid(M.backdrop_win) then
      M.toggle()
    end
  end, { silent = true })

  vim.keymap.set("n", "<Esc>", function()
    if M.backdrop_win and vim.api.nvim_win_is_valid(M.backdrop_win) then
      M.toggle()
    end
  end, { silent = true })
end

return M
