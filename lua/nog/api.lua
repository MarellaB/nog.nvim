-- nog.nvim API module
-- HTTP client for blog API integration

local M = {}

M.config = {
  base_url = "localhost:3000",
  endpoints = {
    blurbs = "/api/blurbs",
    posts = "/api/posts",
  },
  auth_token = nil,
}

-- Check if API is configured
function M.is_configured()
  return M.config.base_url ~= nil and M.config.base_url ~= ""
end

-- Helper: Make HTTP request using curl
-- @param method string HTTP method (GET, POST, etc.)
-- @param url string Full URL
-- @param data table|nil Request body (will be JSON encoded)
-- @return table { success = bool, body = string?, status = number?, error = string? }
local function make_request(method, url, data)
  local curl_args = {
    "curl",
    "-s", -- Silent mode
    "-X", method,
    "-H", "Content-Type: application/json",
    "-w", "\n%{http_code}", -- Write status code on new line
  }

  -- Add auth token if configured
  if M.config.auth_token then
    table.insert(curl_args, "-H")
    table.insert(curl_args, "Authorization: Bearer " .. M.config.auth_token)
  end

  -- Add request body if provided
  if data then
    local json_data = vim.json.encode(data)
    table.insert(curl_args, "-d")
    table.insert(curl_args, json_data)
  end

  -- Add URL
  table.insert(curl_args, url)

  -- Execute curl command
  local result = vim.system(curl_args, { text = true }):wait()

  if result.code ~= 0 then
    return {
      success = false,
      error = "Curl command failed: " .. (result.stderr or "Unknown error"),
    }
  end

  -- Parse response: last line is status code, rest is body
  local output = result.stdout or ""
  local lines = vim.split(output, "\n")
  local status_code = tonumber(lines[#lines]) or 0
  table.remove(lines, #lines) -- Remove status code line
  local body = table.concat(lines, "\n")

  -- Check if request was successful (2xx status)
  if status_code >= 200 and status_code < 300 then
    return {
      success = true,
      body = body,
      status = status_code,
    }
  else
    return {
      success = false,
      status = status_code,
      error = string.format("HTTP %d: %s", status_code, body),
    }
  end
end

-- Publish a blurb to the API
-- Returns: { success = bool, remote_id = string?, error = string? }
function M.publish_blurb(blurb)
  if not M.is_configured() then
    return {
      success = false,
      remote_id = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  local url = M.config.base_url .. M.config.endpoints.blurbs
  vim.notify(url, 2)
  local result = make_request("POST", url, { content = blurb.content })



  if not result.success then
    return {
      success = false,
      remote_id = nil,
      error = result.error,
    }
  end

  -- Parse response to get remote ID
  local ok, response_data = pcall(vim.json.decode, result.body)
  if not ok then
    return {
      success = false,
      remote_id = nil,
      error = "Failed to parse API response",
    }
  end

  return {
    success = true,
    remote_id = response_data.id or tostring(os.time()),
    error = nil,
  }
end

-- Publish a post to the API
-- Returns: { success = bool, remote_id = string?, error = string? }
function M.publish_post(post)
  if not M.is_configured() then
    return {
      success = false,
      remote_id = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  local url = M.config.base_url .. M.config.endpoints.posts
  local payload = {
    content = post.content,
    references = post.references or {},
  }
  local result = make_request("POST", url, payload)

  if not result.success then
    return {
      success = false,
      remote_id = nil,
      error = result.error,
    }
  end

  -- Parse response to get remote ID
  local ok, response_data = pcall(vim.json.decode, result.body)
  if not ok then
    return {
      success = false,
      remote_id = nil,
      error = "Failed to parse API response",
    }
  end

  return {
    success = true,
    remote_id = response_data.id or tostring(os.time()),
    error = nil,
  }
end

-- Fetch published blurbs from API (for syncing)
-- Returns: { success = bool, blurbs = table?, error = string? }
function M.fetch_blurbs()
  if not M.is_configured() then
    return {
      success = false,
      blurbs = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  local url = M.config.base_url .. M.config.endpoints.blurbs
  local result = make_request("GET", url, nil)

  if not result.success then
    return {
      success = false,
      blurbs = nil,
      error = result.error,
    }
  end

  -- Parse response
  local ok, blurbs_data = pcall(vim.json.decode, result.body)
  if not ok then
    return {
      success = false,
      blurbs = nil,
      error = "Failed to parse API response",
    }
  end

  return {
    success = true,
    blurbs = blurbs_data,
    error = nil,
  }
end

-- Fetch published posts from API (for syncing)
-- Returns: { success = bool, posts = table?, error = string? }
function M.fetch_posts()
  if not M.is_configured() then
    return {
      success = false,
      posts = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  local url = M.config.base_url .. M.config.endpoints.posts
  local result = make_request("GET", url, nil)

  if not result.success then
    return {
      success = false,
      posts = nil,
      error = result.error,
    }
  end

  -- Parse response
  local ok, posts_data = pcall(vim.json.decode, result.body)
  if not ok then
    return {
      success = false,
      posts = nil,
      error = "Failed to parse API response",
    }
  end

  return {
    success = true,
    posts = posts_data,
    error = nil,
  }
end

-- Setup function to configure API
function M.setup(opts)
  if opts then
    if opts.base_url then
      M.config.base_url = opts.base_url
    end
    if opts.endpoints then
      M.config.endpoints = vim.tbl_extend("force", M.config.endpoints, opts.endpoints)
    end
    if opts.auth_token then
      M.config.auth_token = opts.auth_token
    end
  end
end

return M
