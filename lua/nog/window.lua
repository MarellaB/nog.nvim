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
    zindex = 40, -- Low z-index so it's behind other windows (40 seems to still be above the explorer in LazyVim though)
  })

  -- Set the background to a dimmed color
  vim.wo[backdrop_win].winblend = 30
  vim.wo[backdrop_win].winhighlight = "Normal:Normal"

  return backdrop_win
end

M.create_stacked_window = function()
  local bottom_height = 1
  local top_height = 30
  local border_size = 2
  local width = vim.o.columns
  local height = vim.o.lines

  local win_width = math.floor(width * 0.4)
  local win_height = math.floor(height * 0.6)

  local top_row = math.floor((height - win_height) / 2)
  local bottom_row = top_row + top_height + border_size
  local col = math.floor((width - win_width) / 2)

  local top_buf = vim.api.nvim_create_buf(false, true)
  local bottom_buf = vim.api.nvim_create_buf(false, true)

  local top_opts = {
    relative = "editor",
    width = win_width,
    height = top_height,
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

return M
