# nog.nvim

A Neovim-based blog manager for writing and publishing content to your personal blog, entirely from within Neovim.

## Features

- **Tweet Composer** - Quick, short-form posts (primary interface)
- **Post Composer** - Full blog posts with Markdown support
- **Reference System** - Link tweets and posts using `{{tweet:id}}` or `{{post:id}}`
- **Draft Persistence** - Drafts auto-save and persist across sessions
- **Browse History** - View and copy IDs from published content
- **Keyboard-Driven** - Modal interface similar to lazygit

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/nog.nvim",
  config = function()
    require("nog").setup({
      -- Optional configuration
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "your-username/nog.nvim",
  config = function()
    require("nog").setup()
  end
}
```

## Configuration

```lua
require("nog").setup({
  -- API configuration (for future HTTP integration)
  api = {
    base_url = "https://yourblog.com",
    endpoints = {
      tweets = "/api/tweets",
      posts = "/api/posts",
    },
  },

  -- Storage location (default: ~/.local/share/nvim/nog/)
  storage_path = vim.fn.stdpath("data") .. "/nog",

  -- Optional global keymap
  keymaps = {
    toggle = "<leader>b",
  },

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
- `:NogHelp` - Show keybinding reference

### Keybindings

#### Tweet Composer (default view)

| Key | Action |
|-----|--------|
| `<Tab>` | Open menu |
| `<C-p>` | Publish tweet |
| `<Esc>` / `q` | Close (auto-saves draft) |

#### Menu

| Key | Action |
|-----|--------|
| `p` | Write/edit post draft |
| `t` | Browse published tweets |
| `P` | Browse published posts |
| `<Esc>` | Back to tweet composer |
| `q` | Close entirely |

#### Post Composer

| Key | Action |
|-----|--------|
| `r` | Insert reference to tweet/post |
| `<C-p>` | Publish post |
| `<Esc>` / `q` | Back to menu (auto-saves draft) |

#### Browse Views

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up/down |
| `<Enter>` | View full content |
| `y` | Copy ID to clipboard |
| `<Esc>` / `q` | Back to menu |

#### Reference Picker

| Key | Action |
|-----|--------|
| `<Tab>` | Switch between tweets/posts |
| `j` / `k` | Navigate |
| `<Enter>` | Select and insert reference |
| `<Esc>` / `q` | Cancel |

### Reference Syntax

In post content, you can reference other tweets or posts:

```markdown
Check out my earlier thought: {{tweet:123}}

As I mentioned in {{post:456}}, this is important.
```

## Storage

Local data is stored in `~/.local/share/nvim/nog/` by default:

```
~/.local/share/nvim/nog/
├── tweet_draft.md      # Current tweet draft
├── post_draft.md       # Current post draft
├── tweets.json         # Published tweets history
└── posts.json          # Published posts history
```

## API Integration

The API module is currently stubbed for future implementation. When configured with a `base_url`, it will POST to your blog's API endpoints.

Expected API contract:

```
POST /api/tweets
Content-Type: application/json
{ "content": "markdown string" }

POST /api/posts
Content-Type: application/json
{ "content": "markdown string", "references": ["tweet:123", "post:456"] }
```

## Why Nog?

It was an easy name forming from **N**e**o**vim and Bl**og**, and I came up with the idea around Christmas time so it fit.

## License

MIT
