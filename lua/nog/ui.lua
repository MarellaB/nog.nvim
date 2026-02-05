-- nog.nvim UI module
-- View state machine and rendering

local window = require("nog.window")
local keymaps = require("nog.keymaps")
local storage = require("nog.storage")
local api = require("nog.api")
local references = require("nog.references")

local M = {}

-- UI State
M.state = {
  view = nil, -- "blurb", "post", "browse_blurbs", "browse_posts", "ref_picker", "view_content"
  backdrop_win = nil,
  backdrop_buf = nil,
  -- Current view windows/buffers
  main_buf = nil,
  main_win = nil,
  -- Overlay windows (picker)
  overlay_buf = nil,
  overlay_win = nil,
  -- Browse state
  browse_items = {},
  browse_cursor = 1,
  browse_type = nil, -- "blurbs" or "posts"
  -- Ref picker state
  picker_items = {},
  picker_cursor = 1,
  picker_type = "blurbs", -- "blurbs" or "posts" (internal: keeping as blurbs for API compatibility)
  -- Post composer state (for returning from ref picker)
  post_buf_saved = nil,
  post_win_saved = nil,
  -- Content view state
  view_content_item = nil,
}

-- Status bar text for different views
local STATUS = {
  blurb = "[Ctrl+p] Publish   [p] Post   [t] Blurbs   [P] Posts   [q] Close",
  post = "[r] Insert Ref   [Ctrl+p] Publish   [Esc] Back   [q] Close",
  browse_blurbs = "[Enter] View   [y] Copy ID   [j/k] Navigate   [Esc] Back   [q] Close",
  browse_posts = "[Enter] View   [y] Copy ID   [j/k] Navigate   [Esc] Back   [q] Close",
  ref_picker = "[Enter] Select  [Tab] Switch Type  [j/k] Navigate  [Esc] Cancel  [q] Close",
  view_content = "[Esc] Back   [q] Close",
}

-- Helper to get buffer content as string
local function get_buffer_content(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Helper to set buffer content from string
local function set_buffer_content(bufnr, content)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local lines = vim.split(content or "", "\n", { plain = true })
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

-- Close all UI windows
function M.close_all()
  -- Save current draft if in blurb or post view
  if M.state.view == "blurb" and M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_blurb_draft(content)
  elseif M.state.view == "post" and M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_post_draft(content)
  end

  -- Close overlay if exists
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- Close main windows
  window.close_win(M.state.main_win)
  window.close_win(M.state.backdrop_win)

  M.state.main_buf = nil
  M.state.main_win = nil
  M.state.backdrop_win = nil
  M.state.backdrop_buf = nil
  M.state.view = nil
end

-- Check if UI is open
function M.is_open()
  return M.state.backdrop_win ~= nil and vim.api.nvim_win_is_valid(M.state.backdrop_win)
end

-- Show blurb composer (default view)
function M.show_blurb()
  -- Close any overlay
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- If not open, create backdrop first
  if not M.is_open() then
    M.state.backdrop_win, M.state.backdrop_buf = window.create_backdrop()
  end

  -- Close existing main windows if different view
  if M.state.view ~= "blurb" then
    window.close_win(M.state.main_win)

    local pane = window.create_single_pane("Blurb", STATUS.blurb)
    M.state.main_buf = pane.main_buf
    M.state.main_win = pane.main_win
  end

  M.state.view = "blurb"

  -- Setup buffer for editing
  vim.bo[M.state.main_buf].filetype = "markdown"
  vim.bo[M.state.main_buf].buftype = ""
  vim.bo[M.state.main_buf].modifiable = true

  -- Load draft
  local draft = storage.load_blurb_draft()
  if draft and draft.content then
    set_buffer_content(M.state.main_buf, draft.content)
  end

  -- Setup keymaps
  keymaps.setup_blurb_keymaps(M.state.main_buf, {
    publish = function()
      M.publish_blurb()
    end,
    post = function()
      M.show_post()
    end,
    browse_blurbs = function()
      M.show_browse("blurbs")
    end,
    browse_posts = function()
      M.show_browse("posts")
    end,
    close = function()
      M.close_all()
    end,
  })
end


-- Show post composer
function M.show_post()
  -- Save blurb draft if coming from blurb view
  if M.state.view == "blurb" and M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_blurb_draft(content)
  end

  -- Close overlay
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- Close existing main windows
  window.close_win(M.state.main_win)

  local pane = window.create_single_pane("Post", STATUS.post)
  M.state.main_buf = pane.main_buf
  M.state.main_win = pane.main_win
  M.state.view = "post"

  -- Setup buffer for editing
  vim.bo[M.state.main_buf].filetype = "markdown"
  vim.bo[M.state.main_buf].buftype = ""
  vim.bo[M.state.main_buf].modifiable = true

  -- Load draft
  local draft = storage.load_post_draft()
  if draft and draft.content then
    set_buffer_content(M.state.main_buf, draft.content)
  end

  -- Setup keymaps
  keymaps.setup_post_keymaps(M.state.main_buf, {
    publish = function()
      M.publish_post()
    end,
    insert_ref = function()
      M.show_ref_picker()
    end,
    back = function()
      M.show_blurb()
    end,
    close = function()
      M.close_all()
    end,
  })
end

-- Show browse view (blurbs or posts)
function M.show_browse(browse_type)
  -- Close overlay
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- Close existing main windows
  window.close_win(M.state.main_win)

  local title = browse_type == "blurbs" and "Blurbs" or "Posts"
  local footer = browse_type == "blurbs" and STATUS.browse_blurbs or STATUS.browse_posts

  local pane = window.create_browse_window(title, footer)
  M.state.main_buf = pane.main_buf
  M.state.main_win = pane.main_win
  M.state.view = "browse_" .. browse_type
  M.state.browse_type = browse_type

  -- Load items
  if browse_type == "blurbs" then
    M.state.browse_items = storage.load_blurbs_history()
  else
    M.state.browse_items = storage.load_posts_history()
  end
  M.state.browse_cursor = 1

  -- Render browse list
  M.render_browse_list()

  -- Setup buffer as non-editable
  vim.bo[M.state.main_buf].modifiable = false
  vim.bo[M.state.main_buf].buftype = "nofile"

  -- Setup keymaps
  keymaps.setup_browse_keymaps(M.state.main_buf, {
    nav_down = function()
      M.browse_navigate(1)
    end,
    nav_up = function()
      M.browse_navigate(-1)
    end,
    view = function()
      M.view_browse_item()
    end,
    copy_id = function()
      M.copy_browse_id()
    end,
    back = function()
      M.show_blurb()
    end,
    close = function()
      M.close_all()
    end,
  })
end

-- Render browse list
function M.render_browse_list()
  local lines = {}
  if #M.state.browse_items == 0 then
    table.insert(lines, "")
    table.insert(lines, "  No " .. M.state.browse_type .. " published yet.")
    table.insert(lines, "")
  else
    for i, item in ipairs(M.state.browse_items) do
      local prefix = i == M.state.browse_cursor and " > " or "   "
      local date = item.published_at and os.date("%Y-%m-%d", item.published_at) or "Unknown"
      local preview = (item.content or ""):sub(1, 30):gsub("\n", " ")
      if #(item.content or "") > 30 then
        preview = preview .. "..."
      end
      local id_str = item.id and ("#" .. item.id) or ""
      table.insert(lines, string.format("%s%s  \"%s\"  %s", prefix, date, preview, id_str))
    end
  end

  vim.bo[M.state.main_buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.main_buf, 0, -1, false, lines)
  vim.bo[M.state.main_buf].modifiable = false
end

-- Navigate browse list
function M.browse_navigate(delta)
  local new_cursor = M.state.browse_cursor + delta
  if new_cursor >= 1 and new_cursor <= #M.state.browse_items then
    M.state.browse_cursor = new_cursor
    M.render_browse_list()
    -- Move vim cursor to match
    vim.api.nvim_win_set_cursor(M.state.main_win, { M.state.browse_cursor, 0 })
  end
end

-- View full content of browse item
function M.view_browse_item()
  local item = M.state.browse_items[M.state.browse_cursor]
  if not item then
    return
  end

  M.state.view_content_item = item

  -- Close existing windows
  window.close_win(M.state.main_win)

  local title = M.state.browse_type == "blurbs" and "Blurb #" .. (item.id or "?") or "Post #" .. (item.id or "?")
  local pane = window.create_single_pane(title, STATUS.view_content)
  M.state.main_buf = pane.main_buf
  M.state.main_win = pane.main_win

  local prev_view = M.state.view
  M.state.view = "view_content"

  -- Set content
  set_buffer_content(M.state.main_buf, item.content or "")
  vim.bo[M.state.main_buf].modifiable = false
  vim.bo[M.state.main_buf].buftype = "nofile"
  vim.bo[M.state.main_buf].filetype = "markdown"

  -- Setup keymaps
  vim.keymap.set("n", "q", function()
    M.close_all()
  end, { buffer = M.state.main_buf, noremap = true, silent = true })
  vim.keymap.set("n", "<Esc>", function()
    M.show_browse(M.state.browse_type)
  end, { buffer = M.state.main_buf, noremap = true, silent = true })
end

-- Copy ID of current browse item to clipboard
function M.copy_browse_id()
  local item = M.state.browse_items[M.state.browse_cursor]
  if not item or not item.id then
    vim.notify("No ID to copy", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", item.id)
  vim.fn.setreg("*", item.id)
  vim.notify("Copied ID: " .. item.id, vim.log.levels.INFO)
end

-- Show reference picker
function M.show_ref_picker()
  -- Save post draft first
  if M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_post_draft(content)
  end

  -- Store current post buffer/win to return to
  M.state.post_buf_saved = M.state.main_buf
  M.state.post_win_saved = M.state.main_win

  local picker = window.create_picker_window("Insert Reference")
  M.state.overlay_buf = picker.buf
  M.state.overlay_win = picker.win

  M.state.picker_type = "blurbs"
  M.state.picker_cursor = 1

  -- Load items
  M.reload_picker_items()
  M.render_picker()

  local prev_view = M.state.view
  M.state.view = "ref_picker"

  -- Setup keymaps
  keymaps.setup_ref_picker_keymaps(M.state.overlay_buf, {
    select = function()
      M.select_reference()
    end,
    cancel = function()
      M.close_ref_picker()
    end,
    nav_down = function()
      M.picker_navigate(1)
    end,
    nav_up = function()
      M.picker_navigate(-1)
    end,
    switch_type = function()
      M.picker_switch_type()
    end,
    close = function()
      M.close_all()
    end,
  })
end

-- Reload picker items based on current type
function M.reload_picker_items()
  if M.state.picker_type == "blurbs" then
    M.state.picker_items = storage.load_blurbs_history()
  else
    M.state.picker_items = storage.load_posts_history()
  end
  M.state.picker_cursor = 1
end

-- Render picker
function M.render_picker()
  local lines = {
    "",
    "  Type: [" .. M.state.picker_type .. "] (Tab to switch)",
    "",
  }

  if #M.state.picker_items == 0 then
    table.insert(lines, "  No " .. M.state.picker_type .. " available.")
  else
    for i, item in ipairs(M.state.picker_items) do
      local prefix = i == M.state.picker_cursor and " > " or "   "
      local preview = (item.content or ""):sub(1, 40):gsub("\n", " ")
      if #(item.content or "") > 40 then
        preview = preview .. "..."
      end
      local id_str = item.id or "?"
      table.insert(lines, string.format("%s#%s: %s", prefix, id_str, preview))
    end
  end

  vim.bo[M.state.overlay_buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.overlay_buf, 0, -1, false, lines)
  vim.bo[M.state.overlay_buf].modifiable = false
  vim.bo[M.state.overlay_buf].buftype = "nofile"
end

-- Navigate picker
function M.picker_navigate(delta)
  local new_cursor = M.state.picker_cursor + delta
  if new_cursor >= 1 and new_cursor <= #M.state.picker_items then
    M.state.picker_cursor = new_cursor
    M.render_picker()
  end
end

-- Switch picker type
function M.picker_switch_type()
  M.state.picker_type = M.state.picker_type == "blurbs" and "posts" or "blurbs"
  M.reload_picker_items()
  M.render_picker()
end

-- Select reference and insert
function M.select_reference()
  local item = M.state.picker_items[M.state.picker_cursor]
  if not item or not item.id then
    vim.notify("No item selected", vim.log.levels.WARN)
    M.close_ref_picker()
    return
  end

  local ref_type = M.state.picker_type == "blurbs" and "blurb" or "post"

  -- Close picker
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil
  M.state.view = "post"

  -- Focus back on post buffer and insert reference
  if M.state.post_win_saved and vim.api.nvim_win_is_valid(M.state.post_win_saved) then
    vim.api.nvim_set_current_win(M.state.post_win_saved)
  end

  if M.state.post_buf_saved and vim.api.nvim_buf_is_valid(M.state.post_buf_saved) then
    vim.bo[M.state.post_buf_saved].modifiable = true
    references.insert_reference_at_cursor(M.state.post_buf_saved, ref_type, item.id)
  end

  M.state.post_buf_saved = nil
  M.state.post_win_saved = nil
end

-- Close reference picker
function M.close_ref_picker()
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil
  M.state.view = "post"

  -- Focus back on post buffer
  if M.state.post_win_saved and vim.api.nvim_win_is_valid(M.state.post_win_saved) then
    vim.api.nvim_set_current_win(M.state.post_win_saved)
  end

  M.state.post_buf_saved = nil
  M.state.post_win_saved = nil
end

-- Publish blurb
function M.publish_blurb()
  local content = get_buffer_content(M.state.main_buf)
  if not content or content == "" then
    vim.notify("Cannot publish empty blurb", vim.log.levels.WARN)
    return
  end

  local result = api.publish_blurb({ content = content })

  if result.success then
    -- Add to history
    storage.add_published_blurb({
      id = result.remote_id,
      content = content,
      published_at = os.time(),
    })
    -- Clear draft
    storage.clear_blurb_draft()
    set_buffer_content(M.state.main_buf, "")
    vim.notify("Blurb published!", vim.log.levels.INFO)
  else
    vim.notify("Publish failed: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
  end
end

-- Publish post
function M.publish_post()
  local content = get_buffer_content(M.state.main_buf)
  if not content or content == "" then
    vim.notify("Cannot publish empty post", vim.log.levels.WARN)
    return
  end

  -- Parse references
  local refs = references.parse_references(content)
  local flat_refs = references.flatten_references(refs)

  local result = api.publish_post({ content = content, references = flat_refs })

  if result.success then
    -- Add to history
    storage.add_published_post({
      id = result.remote_id,
      content = content,
      references = flat_refs,
      published_at = os.time(),
    })
    -- Clear draft
    storage.clear_post_draft()
    set_buffer_content(M.state.main_buf, "")
    vim.notify("Post published!", vim.log.levels.INFO)
  else
    vim.notify("Publish failed: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
  end
end

return M
