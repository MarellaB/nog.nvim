local M = {}

M.create_backdrop = function()
  local backdrop_buffer = vim.api.nvim_create_buf(false, true)

  -- Make it cover the entire screen
  local backdrop_win = vim.api.nvim_open_win(backdrop_buffer, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = 40,         -- Low z-index so it's behind other windows
  })

  -- Set the background to a dimmed color
  vim.wo[backdrop_win].winblend = 30
  vim.wo[backdrop_win].winhighlight = "Normal:Normal"

  return backdrop_win
end

M.create_stacked_window = function()
  local bottom_height = 3
  local width = vim.o.columns
  local height = vim.o.lines

  local win_width = math.floor(width * 0.4)
  local win_height = math.floor(height * 0.6)

  local top_row = math.floor((height - win_height) / 2 - 10)
  local bottom_row = top_row + (win_height - bottom_height) + 1
  local col = math.floor((width - win_width) / 2)

  local top_buf = vim.api.nvim_create_buf(false, true)
  local bottom_buf = vim.api.nvim_create_buf(false, true)

  local top_opts = {
    relative = "editor",
    width = win_width,
    height = win_height - 20,
    row = top_row,
    col = col,
    style = 'minimal',
    title = 'Todo Items',
    title_pos = 'center',
    border = 'rounded',
    zindex = 51
  }

  local bottom_opts = {
    relative = "editor",
    width = win_width,
    height = bottom_height,
    row = bottom_row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    zindex = 51
  }

  local top_win = vim.api.nvim_open_win(top_buf, false, top_opts)
  local bottom_win = vim.api.nvim_open_win(bottom_buf, true, bottom_opts)

  return top_buf, top_win, bottom_buf, bottom_win
end

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
    title = 'My New Window',
    title_pos = 'center',
    border = 'rounded',
    zindex = 5000000
  }

  -- Create the Window
  local win = vim.api.nvim_open_win(buf, true, opts)

  return buf, win
end

return M
