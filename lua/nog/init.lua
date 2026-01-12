local window = require("nog.window")

local M = {}

local function drawBorderWindow(width, height)
  local windowWidth = '---'
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {
    "---"
  })
end

local function drawLine()
  vim.bo[M.buf].modifiable = true

  drawBorderWindow()

  vim.bo[M.buf].modifiable = false
end

M.toggle = function()
-- Check if window already exists, if so, close everything
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    if M.backdrop_win and vim.api.nvim_win_is_valid(M.backdrop_win) then
      vim.api.nvim_win_close(M.backdrop_win, true)  -- Close backdrop too
    end
    M.win = nil
    M.buf = nil
    M.backdrop_win = nil
    return
  end

  -- Create backdrop FIRST
  M.backdrop_win = window.create_backdrop()

  -- Then create your main window
  M.buf, M.win = window.create_centered_window()

  -- Load the nog.md file
  local nog_file = vim.fn.expand('~/nog.md')

  -- Check if the file exists, create if not
  if vim.fn.filereadable(nog_file) == 0 then
    vim.fn.writefile({"# Nog Todo List", "", "- [ ] First Task"}, nog_file)
  end

  vim.bo[M.buf].buftype = "nofile"
  vim.bo[M.buf].modifiable = false

  -- Set filetype
  vim.bo[M.buf].filetype = 'markdown'

  drawLine()

  -- Keybinds to close
  vim.keymap.set("n", "q", function() M.toggle() end, { buffer = M.buf, silent = true })
  vim.keymap.set("n", "<Esc>", function() M.toggle() end, { buffer = M.buf, silent = true })
end

-- Setup method to
M.setup = function(opts)
  vim.notify("Nog plugin loaded!", vim.log.levels.INFO)

  vim.api.nvim_create_user_command("NogToggle", function()
    M.toggle()
  end, {})
end

return M
