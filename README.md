# rails-fixture-ls.nvim

An in-process Neovim LSP server for Rails test fixture completion, hover, and
go-to-definition. Runs entirely as Lua inside your Neovim session with no
external process.

## 📋 Requirements

- **Neovim 0.11+**
- Fixture files in `test/fixtures/` or `spec/fixtures/`

## 🛠️ Installation

Install via your preferred plugin manager. The following example uses [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  'wassimk/rails-fixture-ls.nvim',
  version = '*',
  ft = 'ruby',
  config = function()
    vim.lsp.enable('rails_fixture_ls')
  end,
}
```

## 💻 Features

All features are scoped to test files (paths containing `/test/` or `/spec/`).

| Feature | On fixture name (`:bob`) | On fixture type (`users`) |
|---|---|---|
| **Completion** | Names with YAML attribute preview | Type names, inserts `users(` |
| **Hover** | Fixture's YAML attributes | Available fixture names and file path |
| **Go-to-definition** | Jumps to entry in YAML file | Jumps to YAML file |

## 🔍 How It Works

The server uses Neovim's in-process LSP support, passing a Lua function as the
`cmd` parameter instead of spawning an external process. It only activates in
projects that have a `test/fixtures/` or `spec/fixtures/` directory under the
project root (`Gemfile`, `Rakefile`, or `.git`). If no fixture directory exists,
the server does not start.

Fixture YAML files are parsed in a single pass with simple pattern matching.
Data is cached per project root, so multi-project workspaces are fully
supported. Files using ERB (`<%= %>` tags) work correctly since ERB only appears
in attribute values, not fixture names.

## 🔧 Development

Run tests and lint:

```shell
make test
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
