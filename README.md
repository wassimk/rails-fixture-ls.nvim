# rails-fixture-ls.nvim

An in-process Neovim LSP server for Rails test fixtures. Provides completion,
hover, and go-to-definition for fixture references in your test files.

No external process needed. The server runs as pure Lua inside your Neovim
session.

## Requirements

- Neovim 0.11+
- Fixture files in `test/fixtures/` or `spec/fixtures/` (standard Rails locations)

## Installation

```lua
-- lazy.nvim
{
  'wassimk/rails-fixture-ls.nvim',
  ft = 'ruby',
  config = function()
    vim.lsp.enable('rails_fixture_ls')
  end,
}
```

## Features

### Completion

- **Type completions**: Suggests fixture type names (`users`, `posts`) derived
  from YAML filenames. Selecting a type inserts `type_name(`.
- **Name completions**: After typing `fixture_type(:`, suggests individual
  fixture names (`:bob`, `:alice`) with YAML documentation previews.

### Hover

- **On a fixture name** (`:bob` in `users(:bob)`): Shows the fixture's YAML
  attributes in a floating window.
- **On a fixture type** (`users` in `users(:bob)`): Lists all available fixture
  names and the file path.

### Go-to-Definition

- **On a fixture name**: Jumps to the fixture entry in the YAML file.
- **On a fixture type**: Jumps to the fixture YAML file.

## Configuration

The default configuration:

```lua
{
  filetypes = { 'ruby' },
  root_markers = { 'Gemfile', 'Rakefile', '.git' },
}
```

Override via `vim.lsp.config()` before enabling:

```lua
vim.lsp.config('rails_fixture_ls', {
  root_markers = { 'Gemfile' },
})
vim.lsp.enable('rails_fixture_ls')
```

## How It Works

This plugin uses Neovim's support for in-process LSP servers. Instead of
spawning an external process, it passes a Lua function as the `cmd` parameter
to `vim.lsp.start()`. That function returns a dispatch table implementing the
LSP protocol entirely in Lua within your Neovim session.

The server activates for Ruby files in projects with a `Gemfile`, `Rakefile`,
or `.git` directory. Completions, hover, and definitions are scoped to test
files (paths containing `/test/` or `/spec/`).
