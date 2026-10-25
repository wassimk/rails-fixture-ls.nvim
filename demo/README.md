# Demo GIF

`demo.gif` in the repo root is generated from `rails-fixture-ls.tape` with [VHS](https://github.com/charmbracelet/vhs). Regenerate it whenever the plugin's behavior or the README demo should change.

## Requirements

- [VHS](https://github.com/charmbracelet/vhs#installation) (`brew install vhs`)
- Neovim >= 0.11, git, and bash
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) (optional, the tape tries MonoLisaCode first and VHS falls back to a default font)
- Network access on the first run, to clone [onedark.nvim](https://github.com/navarasu/onedark.nvim) and [blink.cmp](https://github.com/saghen/blink.cmp) into `/tmp`

## Regenerate

From the repo root:

```shell
vhs demo/rails-fixture-ls.tape
```

This overwrites `demo.gif`. Commit it along with any tape changes.

## How it works

- `sample/` is a tiny Rails-style project: a `Gemfile` for root detection, a few fixture files, and a model test. The demo edits the test in the buffer but never saves it.
- `init.lua` is a minimal config with blink.cmp (pinned, Lua matcher so no binary download), onedark, and `rails_fixture_ls` enabled. The completion menu shows labels only, because VHS draws Nerd Font kind icons wider than one cell, and shows each fixture's YAML in the documentation window.
- Hover (`K`) and go-to-definition (`gd`) run through keymaps with `showcmd` off, so popups appear without commands on screen.
- The statusline shows paths relative to the project, since go-to-definition opens fixture files by absolute path.
- Steps wait on screen text (`Wait+Screen`), so if the plugin's behavior changes the render fails instead of recording a broken demo.
