-- nog.nvim API module
-- HTTP client stub for blog API integration

local M = {}

M.config = {
  base_url = nil,
  endpoints = {
    tweets = "/api/tweets",
    posts = "/api/posts",
  },
  auth_token = nil,
}

-- Check if API is configured
function M.is_configured()
  return M.config.base_url ~= nil and M.config.base_url ~= ""
end

-- Publish a tweet to the API
-- Returns: { success = bool, remote_id = string?, error = string? }
function M.publish_tweet(tweet)
  if not M.is_configured() then
    return {
      success = false,
      remote_id = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  -- TODO: HTTP POST to tweets endpoint
  -- local url = M.config.base_url .. M.config.endpoints.tweets
  -- For now, return a stub response
  return {
    success = false,
    remote_id = nil,
    error = "API integration not yet implemented.",
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

  -- TODO: HTTP POST to posts endpoint
  -- local url = M.config.base_url .. M.config.endpoints.posts
  -- For now, return a stub response
  return {
    success = false,
    remote_id = nil,
    error = "API integration not yet implemented.",
  }
end

-- Fetch published tweets from API (for syncing)
-- Returns: { success = bool, tweets = table?, error = string? }
function M.fetch_tweets()
  if not M.is_configured() then
    return {
      success = false,
      tweets = nil,
      error = "API not configured. Set base_url in setup().",
    }
  end

  -- TODO: HTTP GET from tweets endpoint
  return {
    success = false,
    tweets = nil,
    error = "API integration not yet implemented.",
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

  -- TODO: HTTP GET from posts endpoint
  return {
    success = false,
    posts = nil,
    error = "API integration not yet implemented.",
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
