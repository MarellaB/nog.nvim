-- nog.nvim blurb module
-- Blurb composition and management

local storage = require("nog.storage")
local api = require("nog.api")

local M = {}

-- Create a new blurb object
function M.new(content)
  return {
    content = content or "",
    created_at = os.time(),
  }
end

-- Publish a blurb
-- Returns: { success = bool, id = string?, error = string? }
function M.publish(content)
  if not content or content == "" then
    return { success = false, error = "Cannot publish empty blurb" }
  end

  local result = api.publish_blurb({ content = content })

  if result.success then
    -- Add to local history
    storage.add_published_blurb({
      id = result.remote_id,
      content = content,
      published_at = os.time(),
    })
    -- Clear draft
    storage.clear_blurb_draft()
  end

  return {
    success = result.success,
    id = result.remote_id,
    error = result.error,
  }
end

return M
