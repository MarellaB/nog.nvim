-- nog.nvim storage module
-- Handles local draft persistence and published history

local M = {}

M.config = {
  storage_path = vim.fn.stdpath("data") .. "/nog",
}

-- Ensure storage directory exists
local function ensure_storage_dir()
  local path = M.config.storage_path
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

-- File paths
local function blurb_draft_path()
  return M.config.storage_path .. "/blurb_draft.md"
end

local function post_draft_path()
  return M.config.storage_path .. "/post_draft.md"
end

local function blurbs_history_path()
  return M.config.storage_path .. "/blurbs.json"
end

local function posts_history_path()
  return M.config.storage_path .. "/posts.json"
end

-- Read file contents
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

-- Write file contents
local function write_file(path, content)
  ensure_storage_dir()
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(content)
  file:close()
  return true
end

-- JSON encode/decode helpers
local function json_encode(data)
  return vim.fn.json_encode(data)
end

local function json_decode(str)
  if not str or str == "" then
    return nil
  end
  local ok, result = pcall(vim.fn.json_decode, str)
  if ok then
    return result
  end
  return nil
end

-- Blurb draft operations
function M.load_blurb_draft()
  local content = read_file(blurb_draft_path())
  if content then
    return {
      content = content,
      updated_at = vim.fn.getftime(blurb_draft_path()),
    }
  end
  return nil
end

function M.save_blurb_draft(content)
  return write_file(blurb_draft_path(), content or "")
end

function M.clear_blurb_draft()
  local path = blurb_draft_path()
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

-- Post draft operations
function M.load_post_draft()
  local content = read_file(post_draft_path())
  if content then
    return {
      content = content,
      updated_at = vim.fn.getftime(post_draft_path()),
    }
  end
  return nil
end

function M.save_post_draft(content)
  return write_file(post_draft_path(), content or "")
end

function M.clear_post_draft()
  local path = post_draft_path()
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

-- Published blurbs history
function M.load_blurbs_history()
  local content = read_file(blurbs_history_path())
  local data = json_decode(content)
  return data or {}
end

function M.save_blurbs_history(blurbs)
  return write_file(blurbs_history_path(), json_encode(blurbs))
end

function M.add_published_blurb(blurb)
  local history = M.load_blurbs_history()
  table.insert(history, 1, blurb) -- Insert at beginning (newest first)
  return M.save_blurbs_history(history)
end

-- Published posts history
function M.load_posts_history()
  local content = read_file(posts_history_path())
  local data = json_decode(content)
  return data or {}
end

function M.save_posts_history(posts)
  return write_file(posts_history_path(), json_encode(posts))
end

function M.add_published_post(post)
  local history = M.load_posts_history()
  table.insert(history, 1, post) -- Insert at beginning (newest first)
  return M.save_posts_history(history)
end

-- Setup function to configure storage path
function M.setup(opts)
  if opts and opts.storage_path then
    M.config.storage_path = opts.storage_path
  end
  ensure_storage_dir()
end

return M
