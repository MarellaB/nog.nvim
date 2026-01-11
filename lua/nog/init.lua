local window = require("nog.window")

local M = {}

M.toggle = function()
  -- Check if window already exists, if so, close it
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    M.buf = nil
    return
  end

  -- Create new window
  M.buf, M.win = window.create_centered_window()

  -- Load the nog.md file
  local nog_file = vim.fn.expand('~/nog.md')

  -- Check if the file exists, create if not
  if vim.fn.filereadable(nog_file) == 0 then
    vim.fn.writefile({"# Nog Todo List", "", "- [ ] First Task"}, nog_file)
  end

  -- Load file into buffer
  vim.bo[M.buf].buftype = ""
  -- vim.api.nvim_buf_set_name(M.buf, nog_file)
  vim.cmd("edit " .. nog_file)

  -- Set filetype
  vim.bo[M.buf].filetype = 'markdown'

  -- Keybinds to close
  vim.keymap.set("n", "q", function() M.toggle() end, { buffer = M.buf, silent = true })
  vim.keymap.set("n", "<Esc>", function() M.toggle() end, { buffer = M.buf, silent = true })
end

M.setup = function(opts)
  vim.notify("Nog plugin loaded!", vim.log.levels.INFO)

  vim.api.nvim_create_user_command("NogToggle", function()
    M.toggle()
  end, {})
end

return M
