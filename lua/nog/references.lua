-- nog.nvim references module
-- Handles parsing and insertion of tweet/post references

local M = {}

-- Reference pattern: {{tweet:id}} or {{post:id}}
local TWEET_PATTERN = "{{tweet:([^}]+)}}"
local POST_PATTERN = "{{post:([^}]+)}}"

-- Parse all references from content
-- Returns: { tweets = { id1, id2, ... }, posts = { id1, id2, ... } }
function M.parse_references(content)
  local refs = {
    tweets = {},
    posts = {},
  }

  if not content then
    return refs
  end

  -- Find all tweet references
  for id in string.gmatch(content, TWEET_PATTERN) do
    table.insert(refs.tweets, id)
  end

  -- Find all post references
  for id in string.gmatch(content, POST_PATTERN) do
    table.insert(refs.posts, id)
  end

  return refs
end

-- Create a tweet reference string
function M.create_tweet_ref(id)
  return "{{tweet:" .. id .. "}}"
end

-- Create a post reference string
function M.create_post_ref(id)
  return "{{post:" .. id .. "}}"
end

-- Get all references as a flat list for storage
-- Returns: { "tweet:123", "post:456", ... }
function M.flatten_references(refs)
  local flat = {}
  for _, id in ipairs(refs.tweets or {}) do
    table.insert(flat, "tweet:" .. id)
  end
  for _, id in ipairs(refs.posts or {}) do
    table.insert(flat, "post:" .. id)
  end
  return flat
end

-- Insert a reference at the current cursor position in a buffer
function M.insert_reference_at_cursor(bufnr, ref_type, id)
  local ref_str
  if ref_type == "tweet" then
    ref_str = M.create_tweet_ref(id)
  elseif ref_type == "post" then
    ref_str = M.create_post_ref(id)
  else
    return false
  end

  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- 0-indexed
  local col = cursor[2]

  -- Get the current line
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  if #lines == 0 then
    -- Insert at new line if buffer is empty
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { ref_str })
  else
    local line = lines[1]
    -- Insert reference at cursor position
    local new_line = string.sub(line, 1, col) .. ref_str .. string.sub(line, col + 1)
    vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { new_line })
    -- Move cursor after the inserted reference
    vim.api.nvim_win_set_cursor(0, { row + 1, col + #ref_str })
  end

  return true
end

return M
