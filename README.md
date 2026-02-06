# nog.nvim

A Neovim-based blog manager for writing and publishing content to your personal
blog, entirely from within Neovim.

## Features

- **Blurb Composer** - Quick, short-form posts (primary interface)
- **Post Composer** - Full blog posts with Markdown support
- **Reference System** - Link blurbs and posts using `{{blurb:id}}` or `{{post:id}}`
- **Draft Persistence** - Drafts auto-save and persist across sessions
- **Browse Blurbs** - View and copy IDs from published blurbs

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "marellab/nog.nvim",
  keys = {
    { "<leader>ng", "<cmd>NogToggle<cr>", desc = "Toggle Nog blog manager" },
  },
  opts = {
    api = {
      base_url = "https://yourblog.com",
      endpoints = {
        blurbs = "/api/blurbs",
        posts = "/api/posts",
      },
    },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "marellab/nog.nvim",
  config = function()
    require("nog").setup({
      -- Configuration
    })

    -- Set up keybindings
    vim.keymap.set("n", "<leader>ng", "<cmd>NogToggle<cr>", { desc = "Toggle Nog blog manager" })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'marellab/nog.nvim'
```

Then in your `init.lua` or `init.vim`:

```lua
require("nog").setup({
  -- Configuration
})

-- Set up keybindings
vim.keymap.set("n", "<leader>ng", "<cmd>NogToggle<cr>", { desc = "Toggle Nog blog manager" })
```

## Configuration

```lua
require("nog").setup({
  -- API configuration
  api = {
    base_url = "https://yourblog.com",
    endpoints = {
      blurbs = "/api/blurbs",
      posts = "/api/posts",
    },
    auth_token = "mYs3cr3tCo0lT0ken" -- Or something better
  },

  -- Storage location (default: ~/.local/share/nvim/nog/)
  storage_path = vim.fn.stdpath("data") .. "/nog",

  -- UI dimensions (as percentage of screen)
  ui = {
    width = 0.5,   -- 50% of screen width
    height = 0.3,  -- 30% of screen height
  },
})
```

## Usage

### Commands

- `:NogToggle` - Open/close the blog manager

### Post & Blurb Syntax

Posts and Blurbs are just assumed to be Markdown syntax, then if you want you
can support linked posts with the below format which in Nog will render with
the post name and it's associated ID. Render it however you'd like on your
end.

```markdown
Check out my earlier thought: {{blurb:123}}

As I mentioned in {{post:456}}, this is important.
```

## Storage

Local data is stored in `~/.local/share/nvim/nog/` by default:

```
~/.local/share/nvim/nog/
├── blurb_draft.md      # Current blurb draft
├── post_draft.md       # Current post draft
├── blurbs.json         # Published blurbs history
└── posts.json          # Published posts history
```

## API Integration

The API module is currently stubbed for future implementation. When configured
with a `base_url`, it will POST to your blog's API endpoints.

Expected API contract:

```
POST /api/blurbs
Content-Type: application/json
{ "content": "markdown string" }

POST /api/posts
Content-Type: application/json
{ "content": "markdown string", "references": ["blurb:123", "post:456"] }
```

## Why Nog?

It was an easy name forming from Neovim and Blog, and I came up with
the idea around Christmas time so it fit.

## License

MIT
