# rails-fixture-ls.nvim

An in-process Neovim LSP server for Rails test fixtures. Provides completion,
hover, and go-to-definition for fixture references in your test files.

No external process needed. The server runs entirely as Lua inside your Neovim
session using the in-process LSP pattern introduced in Neovim 0.11.

## 📋 Requirements

- **Neovim 0.11+**
- Fixture files in `test/fixtures/` or `spec/fixtures/` (standard Rails locations)

## 🛠️ Installation

Install via your preferred plugin manager. The following example uses [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  'wassimk/rails-fixture-ls.nvim',
  ft = 'ruby',
  config = function()
    vim.lsp.enable('rails_fixture_ls')
  end,
}
```

> [!IMPORTANT]
> This plugin is actively developed on the `main` branch. I recommend using
> versioned releases with the *version* key to avoid unexpected breaking changes.

## 💻 Features

All features are scoped to test files (paths containing `/test/` or `/spec/`).

### Completion

Type completions and name completions are triggered automatically as you type.

| Trigger | Completion |
|---|---|
| `users` | Fixture type names derived from YAML filenames, inserts `users(` |
| `users(:` | Individual fixture names (`:bob`, `:alice`) with YAML attribute preview |

### Hover

| Target | Result |
|---|---|
| `:bob` in `users(:bob)` | Floating window with the fixture's YAML attributes |
| `users` in `users(:bob)` | Lists all available fixture names and the file path |

### Go-to-Definition

| Target | Result |
|---|---|
| `:bob` in `users(:bob)` | Jumps to the fixture entry in the YAML file |
| `users` in `users(:bob)` | Jumps to the fixture YAML file |

## ⚙️ Configuration

The default LSP configuration:

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

## 🔍 How It Works

This plugin uses Neovim's support for in-process LSP servers. Instead of
spawning an external process, it passes a Lua function as the `cmd` parameter
to `vim.lsp.start()`. That function returns a dispatch table implementing the
LSP protocol entirely in Lua within your Neovim session.

The server activates for Ruby files in projects with a `Gemfile`, `Rakefile`,
or `.git` directory. Fixture data is cached per project root, so multi-project
workspaces are fully supported.

Fixture YAML files are parsed with simple pattern matching. Files using ERB
(`.yml` with embedded `<%= %>` tags) work correctly since ERB only appears in
attribute values, not fixture names.

## 🔧 Development

Run lint:

```shell
make lint
```

Generate vimdoc from README:

```shell
make docs
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```

This activates a pre-commit hook that checks stylua formatting and
auto-generates `doc/rails-fixture-ls.nvim.txt` from `README.md` whenever the
README is staged. Requires [pandoc](https://pandoc.org/installing.html).
