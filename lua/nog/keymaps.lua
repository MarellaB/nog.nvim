-- nog.nvim keymaps module
-- Centralized keymap definitions for all views

local M = {}

-- Default keymap definitions (can be overridden via setup)
M.defaults = {
  -- Tweet composer keymaps
  tweet = {
    publish = "<C-p>",
    menu = "<Tab>",
    close = "q",
  },
  -- Menu view keymaps
  menu = {
    post = "p",
    browse_tweets = "t",
    browse_posts = "P",
    close = "q",
  },
  -- Post composer keymaps
  post = {
    publish = "<C-p>",
    insert_ref = "r",
    close = "q",
  },
  -- Browse views keymaps
  browse = {
    nav_down = "j",
    nav_up = "k",
    view = "<CR>",
    copy_id = "y",
    close = "q",
  },
  -- Reference picker keymaps
  ref_picker = {
    select = "<CR>",
    cancel = "<Esc>",
    nav_down = "j",
    nav_up = "k",
    switch_type = "<Tab>",
    close = "q",
  },
}

-- Current keymaps (after user overrides)
M.keymaps = vim.deepcopy(M.defaults)

-- Helper to set buffer-local keymap
local function buf_keymap(bufnr, mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { noremap = true, silent = true, buffer = bufnr }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Helper to set multiple keys for the same action
local function set_keys(bufnr, mode, keys, action, opts)
  if type(keys) == "table" then
    for _, key in ipairs(keys) do
      buf_keymap(bufnr, mode, key, action, opts)
    end
  else
    buf_keymap(bufnr, mode, keys, action, opts)
  end
end

-- Setup keymaps for tweet composer view
function M.setup_tweet_keymaps(bufnr, callbacks)
  -- Publish tweet
  buf_keymap(bufnr, "n", M.keymaps.tweet.publish, callbacks.publish)
  buf_keymap(bufnr, "i", M.keymaps.tweet.publish, callbacks.publish)

  -- Open menu
  buf_keymap(bufnr, "n", M.keymaps.tweet.menu, callbacks.menu)

  -- Close plugin
  set_keys(bufnr, "n", M.keymaps.tweet.close, callbacks.close)
end

-- Setup keymaps for menu view
function M.setup_menu_keymaps(bufnr, callbacks)
  -- Navigation options
  buf_keymap(bufnr, "n", M.keymaps.menu.post, callbacks.post)
  buf_keymap(bufnr, "n", M.keymaps.menu.browse_tweets, callbacks.browse_tweets)
  buf_keymap(bufnr, "n", M.keymaps.menu.browse_posts, callbacks.browse_posts)

  -- Close plugin
  buf_keymap(bufnr, "n", M.keymaps.menu.close, callbacks.close)
end

-- Setup keymaps for post composer view
function M.setup_post_keymaps(bufnr, callbacks)
  -- Publish post
  buf_keymap(bufnr, "n", M.keymaps.post.publish, callbacks.publish)
  buf_keymap(bufnr, "i", M.keymaps.post.publish, callbacks.publish)

  -- Insert reference
  buf_keymap(bufnr, "n", M.keymaps.post.insert_ref, callbacks.insert_ref)

  -- Close plugin
  set_keys(bufnr, "n", M.keymaps.post.close, callbacks.close)
end

-- Setup keymaps for browse views (tweets/posts)
function M.setup_browse_keymaps(bufnr, callbacks)
  -- Navigation
  buf_keymap(bufnr, "n", M.keymaps.browse.nav_down, callbacks.nav_down)
  buf_keymap(bufnr, "n", M.keymaps.browse.nav_up, callbacks.nav_up)

  -- View full content
  buf_keymap(bufnr, "n", M.keymaps.browse.view, callbacks.view)

  -- Copy ID to clipboard
  buf_keymap(bufnr, "n", M.keymaps.browse.copy_id, callbacks.copy_id)

  -- Close plugin
  set_keys(bufnr, "n", M.keymaps.browse.close, callbacks.close)
end

-- Setup keymaps for reference picker
function M.setup_ref_picker_keymaps(bufnr, callbacks)
  -- Select reference
  buf_keymap(bufnr, "n", M.keymaps.ref_picker.select, callbacks.select)

  -- Cancel picker
  set_keys(bufnr, "n", M.keymaps.ref_picker.cancel, callbacks.cancel)

  -- Navigation
  buf_keymap(bufnr, "n", M.keymaps.ref_picker.nav_down, callbacks.nav_down)
  buf_keymap(bufnr, "n", M.keymaps.ref_picker.nav_up, callbacks.nav_up)

  -- Switch between tweets/posts
  buf_keymap(bufnr, "n", M.keymaps.ref_picker.switch_type, callbacks.switch_type)

  -- Close plugin
  set_keys(bufnr, "n", M.keymaps.ref_picker.close, callbacks.close)
end

-- Setup function to merge user keymap overrides
function M.setup(opts)
  if opts then
    M.keymaps = vim.tbl_deep_extend("force", M.defaults, opts)
  end
end

return M
