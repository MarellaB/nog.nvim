# nog.nvim

A Neovim-based blog manager for writing and publishing content to your personal blog, entirely from within Neovim.

## Features

- **Blurb Composer** - Quick, short-form posts (primary interface)
- **Post Composer** - Full blog posts with Markdown support
- **Reference System** - Link blurbs and posts using `{{blurb:id}}` or `{{post:id}}`
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
      blurbs = "/api/blurbs",
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

#### Blurb Composer (default view)

| Key | Action |
|-----|--------|
| `<C-p>` | Publish blurb |
| `p` | Go to post composer |
| `t` | Browse published blurbs |
| `P` | Browse published posts |
| `q` | Close (auto-saves draft) |

#### Post Composer

| Key | Action |
|-----|--------|
| `r` | Insert reference to blurb/post |
| `<C-p>` | Publish post |
| `<Esc>` | Back to blurb composer |
| `q` | Close (auto-saves draft) |

#### Browse Views

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up/down |
| `<Enter>` | View full content |
| `y` | Copy ID to clipboard |
| `<Esc>` | Back to blurb composer |
| `q` | Close |

#### View Content

| Key | Action |
|-----|--------|
| `<Esc>` | Back to browse list |
| `q` | Close |

#### Reference Picker

| Key | Action |
|-----|--------|
| `<Tab>` | Switch between blurbs/posts |
| `j` / `k` | Navigate |
| `<Enter>` | Select and insert reference |
| `<Esc>` | Cancel |

### Reference Syntax

In post content, you can reference other blurbs or posts:

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

The API module is currently stubbed for future implementation. When configured with a `base_url`, it will POST to your blog's API endpoints.

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

It was an easy name forming from **N**e**o**vim and Bl**og**, and I came up with the idea around Christmas time so it fit.

## License

MIT
