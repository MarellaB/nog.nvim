local M = {}

M.create_centered_window = function()
  -- Get editor dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- Calculate popup size (60% of screen)
  local win_width = math.floor(width * 0.6)
  local win_height = math.floor(height * 0.6)

  -- Calculate starting position (centers the window)
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  -- Create a buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Window options
  local opts = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  }

  -- Create the Window
  local win = vim.api.nvim_open_win(buf, true, opts)

  return buf, win
end

return M
