-- nog.nvim post module
-- Post composition and management

local storage = require("nog.storage")
local api = require("nog.api")
local references = require("nog.references")

local M = {}

-- Create a new post object
function M.new(content)
  return {
    content = content or "",
    created_at = os.time(),
  }
end

-- Publish a post
-- Returns: { success = bool, id = string?, error = string? }
function M.publish(content)
  if not content or content == "" then
    return { success = false, error = "Cannot publish empty post" }
  end

  -- Parse references from content
  local refs = references.parse_references(content)
  local flat_refs = references.flatten_references(refs)

  local result = api.publish_post({
    content = content,
    references = flat_refs,
  })

  if result.success then
    -- Add to local history
    storage.add_published_post({
      id = result.remote_id,
      content = content,
      references = flat_refs,
      published_at = os.time(),
    })
    -- Clear draft
    storage.clear_post_draft()
  end

  return {
    success = result.success,
    id = result.remote_id,
    error = result.error,
  }
end

return M
