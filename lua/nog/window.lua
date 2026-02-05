-- nog.nvim window module
-- Window/buffer management for various views

local M = {}

-- UI configuration (set via setup)
M.config = {
  width = 0.5,  -- 50% of screen width
  height = 0.4, -- 70% of screen height
}

-- Calculate window dimensions based on config
local function get_dimensions()
  local width = vim.o.columns
  local height = vim.o.lines

  local win_width = math.floor(width * M.config.width)
  local win_height = math.floor(height * M.config.height)

  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  return {
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }
end

-- Create backdrop window (dims the background)
function M.create_backdrop()
  -- Create custom backdrop highlight group if it doesn't exist
  vim.api.nvim_set_hl(0, "NogBackdrop", { bg = "#000000", default = true })

  local backdrop_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[backdrop_buffer].bufhidden = "wipe"

  local backdrop_win = vim.api.nvim_open_win(backdrop_buffer, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = 40,
  })

  vim.wo[backdrop_win].winblend = 60
  vim.wo[backdrop_win].winhighlight = "Normal:NogBackdrop"

  return backdrop_win, backdrop_buffer
end

-- Parse footer keys from text like "[key] desc [key2] desc2"
-- Returns formatted footer table for nvim_open_win
local function parse_footer(footer_text)
  if not footer_text then
    return nil
  end

  -- Define highlight groups (matching snacks.nvim style)
  vim.api.nvim_set_hl(0, "NogFooterKey", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "NogFooterDesc", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "NogFooter", { link = "FloatFooter", default = true })

  local footer = { { " ", "NogFooter" } }

  -- Match patterns like [key] description
  for key, desc in footer_text:gmatch("%[([^%]]+)%]%s*([^%[]+)") do
    table.insert(footer, { " " .. key .. " ", "NogFooterKey" })
    table.insert(footer, { " " .. desc:match("^%s*(.-)%s*$") .. " ", "NogFooterDesc" })
  end

  table.insert(footer, { " ", "NogFooter" })
  return footer
end

-- Create a single-pane window with title and footer
-- Returns: { main_buf, main_win }
function M.create_single_pane(title, footer_text)
  local dims = get_dimensions()

  -- Create main content buffer
  local main_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[main_buf].bufhidden = "wipe"

  -- Main window options
  local main_opts = {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    row = dims.row,
    col = dims.col,
    style = "minimal",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = parse_footer(footer_text),
    footer_pos = "center",
    border = "rounded",
    zindex = 51,
  }

  -- Create window
  local main_win = vim.api.nvim_open_win(main_buf, true, main_opts)

  -- Use Normal background like snacks.nvim scratch
  vim.wo[main_win].winhighlight = "NormalFloat:Normal"
  vim.wo[main_win].winblend = 0
  vim.wo[main_win].number = true

  return {
    main_buf = main_buf,
    main_win = main_win,
  }
end

-- Create a content-only window (no status bar, for menu overlay)
function M.create_menu_window(title)
  local dims = get_dimensions()
  -- Menu is smaller
  local menu_width = math.min(50, dims.width)
  local menu_height = 10
  local menu_row = math.floor((vim.o.lines - menu_height) / 2)
  local menu_col = math.floor((vim.o.columns - menu_width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local win_opts = {
    relative = "editor",
    width = menu_width,
    height = menu_height,
    row = menu_row,
    col = menu_col,
    style = "minimal",
    title = " " .. title .. " ",
    title_pos = "center",
    border = "rounded",
    zindex = 52, -- Above other nog windows
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Use Normal background like snacks.nvim scratch
  vim.wo[win].winhighlight = "NormalFloat:Normal"
  vim.wo[win].winblend = 0

  return {
    buf = buf,
    win = win,
  }
end

-- Create a browse list window
function M.create_browse_window(title, footer_text)
  return M.create_single_pane(title, footer_text)
end

-- Create reference picker window (smaller overlay)
function M.create_picker_window(title)
  local dims = get_dimensions()
  local picker_width = math.min(60, dims.width)
  local picker_height = 15
  local picker_row = math.floor((vim.o.lines - picker_height) / 2)
  local picker_col = math.floor((vim.o.columns - picker_width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local win_opts = {
    relative = "editor",
    width = picker_width,
    height = picker_height,
    row = picker_row,
    col = picker_col,
    style = "minimal",
    title = " " .. title .. " ",
    title_pos = "center",
    border = "rounded",
    zindex = 53, -- Above everything else
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Use Normal background like snacks.nvim scratch
  vim.wo[win].winhighlight = "NormalFloat:Normal"
  vim.wo[win].winblend = 0

  return {
    buf = buf,
    win = win,
  }
end

-- Close a window safely
function M.close_win(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- Close a buffer safely
function M.close_buf(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Setup function to configure window dimensions
function M.setup(opts)
  if opts then
    if opts.width then
      M.config.width = opts.width
    end
    if opts.height then
      M.config.height = opts.height
    end
  end
end

return M
