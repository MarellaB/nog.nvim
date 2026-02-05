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
  view = nil, -- "tweet", "menu", "post", "browse_tweets", "browse_posts", "ref_picker", "view_content"
  backdrop_win = nil,
  backdrop_buf = nil,
  -- Current view windows/buffers
  main_buf = nil,
  main_win = nil,
  -- Overlay windows (menu, picker)
  overlay_buf = nil,
  overlay_win = nil,
  -- Browse state
  browse_items = {},
  browse_cursor = 1,
  browse_type = nil, -- "tweets" or "posts"
  -- Ref picker state
  picker_items = {},
  picker_cursor = 1,
  picker_type = "tweets", -- "tweets" or "posts"
  -- Post composer state (for returning from ref picker)
  post_buf_saved = nil,
  post_win_saved = nil,
  -- Content view state
  view_content_item = nil,
}

-- Status bar text for different views
local STATUS = {
  tweet = "[Ctrl+p] Publish   [Tab] Menu   [q] Close",
  menu = "[p] Post  [t] Tweets  [P] Posts  [q] Close",
  post = "[r] Insert Ref  [Ctrl+p] Publish  [q] Close",
  browse_tweets = "[Enter] View  [y] Copy ID  [j/k] Navigate  [q] Close",
  browse_posts = "[Enter] View  [y] Copy ID  [j/k] Navigate  [q] Close",
  ref_picker = "[Enter] Select  [Tab] Switch Type  [j/k] Navigate  [Esc] Cancel  [q] Close",
  view_content = "[q] Close",
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
  -- Save current draft if in tweet or post view
  if M.state.view == "tweet" and M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_tweet_draft(content)
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

-- Show tweet composer (default view)
function M.show_tweet()
  -- Close any overlay
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- If not open, create backdrop first
  if not M.is_open() then
    M.state.backdrop_win, M.state.backdrop_buf = window.create_backdrop()
  end

  -- Close existing main windows if different view
  if M.state.view ~= "tweet" then
    window.close_win(M.state.main_win)

    local pane = window.create_single_pane("Blurb", STATUS.tweet)
    M.state.main_buf = pane.main_buf
    M.state.main_win = pane.main_win
  end

  M.state.view = "tweet"

  -- Setup buffer for editing
  vim.bo[M.state.main_buf].filetype = "markdown"
  vim.bo[M.state.main_buf].buftype = ""
  vim.bo[M.state.main_buf].modifiable = true

  -- Load draft
  local draft = storage.load_tweet_draft()
  if draft and draft.content then
    set_buffer_content(M.state.main_buf, draft.content)
  end

  -- Setup keymaps
  keymaps.setup_tweet_keymaps(M.state.main_buf, {
    publish = function()
      M.publish_tweet()
    end,
    menu = function()
      M.show_menu()
    end,
    close = function()
      M.close_all()
    end,
  })
end

-- Show menu overlay
function M.show_menu()
  -- Save tweet draft before showing menu
  if M.state.view == "tweet" and M.state.main_buf then
    local content = get_buffer_content(M.state.main_buf)
    storage.save_tweet_draft(content)
  end

  local menu = window.create_menu_window("Menu")
  M.state.overlay_buf = menu.buf
  M.state.overlay_win = menu.win
  M.state.view = "menu"

  -- Render menu content
  local menu_lines = {
    "",
    "   [p] Write Post (current draft)",
    "",
    "   [t] Browse Tweets",
    "   [P] Browse Posts",
    "",
    "   [q] Close",
    "",
  }
  vim.bo[M.state.overlay_buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.overlay_buf, 0, -1, false, menu_lines)
  vim.bo[M.state.overlay_buf].modifiable = false
  vim.bo[M.state.overlay_buf].buftype = "nofile"

  -- Setup keymaps
  keymaps.setup_menu_keymaps(M.state.overlay_buf, {
    post = function()
      M.show_post()
    end,
    browse_tweets = function()
      M.show_browse("tweets")
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
    close = function()
      M.close_all()
    end,
  })
end

-- Show browse view (tweets or posts)
function M.show_browse(browse_type)
  -- Close overlay
  window.close_win(M.state.overlay_win)
  M.state.overlay_win = nil
  M.state.overlay_buf = nil

  -- Close existing main windows
  window.close_win(M.state.main_win)

  local title = browse_type == "tweets" and "Tweets" or "Posts"
  local footer = browse_type == "tweets" and STATUS.browse_tweets or STATUS.browse_posts

  local pane = window.create_browse_window(title, footer)
  M.state.main_buf = pane.main_buf
  M.state.main_win = pane.main_win
  M.state.view = "browse_" .. browse_type
  M.state.browse_type = browse_type

  -- Load items
  if browse_type == "tweets" then
    M.state.browse_items = storage.load_tweets_history()
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

  local title = M.state.browse_type == "tweets" and "Tweet #" .. (item.id or "?") or "Post #" .. (item.id or "?")
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
  local close_fn = function()
    M.close_all()
  end
  vim.keymap.set("n", "q", close_fn, { buffer = M.state.main_buf, noremap = true, silent = true })
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

  M.state.picker_type = "tweets"
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
  if M.state.picker_type == "tweets" then
    M.state.picker_items = storage.load_tweets_history()
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
  M.state.picker_type = M.state.picker_type == "tweets" and "posts" or "tweets"
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

  local ref_type = M.state.picker_type == "tweets" and "tweet" or "post"

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

-- Publish tweet
function M.publish_tweet()
  local content = get_buffer_content(M.state.main_buf)
  if not content or content == "" then
    vim.notify("Cannot publish empty tweet", vim.log.levels.WARN)
    return
  end

  local result = api.publish_tweet({ content = content })

  if result.success then
    -- Add to history
    storage.add_published_tweet({
      id = result.remote_id,
      content = content,
      published_at = os.time(),
    })
    -- Clear draft
    storage.clear_tweet_draft()
    set_buffer_content(M.state.main_buf, "")
    vim.notify("Tweet published!", vim.log.levels.INFO)
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
