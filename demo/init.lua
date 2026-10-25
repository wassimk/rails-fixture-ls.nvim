--
-- Minimal config for recording the README demo with VHS (see demo/rails-fixture-ls.tape)
--

local demo_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local plugin_dir = vim.fn.fnamemodify(demo_dir, ':h')

local function clone(url, dir, ref)
  if vim.fn.isdirectory(dir) == 0 then
    local cmd = { 'git', 'clone', '--depth', '1' }
    if ref then
      vim.list_extend(cmd, { '--branch', ref })
    end
    vim.list_extend(cmd, { url, dir })
    vim.fn.system(cmd)
  end
end

local onedark_dir = os.getenv('ONEDARK_DIR') or '/tmp/onedark.nvim'
local blink_dir = os.getenv('BLINK_DIR') or '/tmp/blink.cmp-v1.10.2'

clone('https://github.com/navarasu/onedark.nvim', onedark_dir)
clone('https://github.com/saghen/blink.cmp', blink_dir, 'v1.10.2')

vim.opt.rtp:prepend(plugin_dir)
vim.opt.rtp:append(onedark_dir)
vim.opt.rtp:append(blink_dir)

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.shortmess:append('I')
-- Paths relative to the project, since go-to-definition opens files by absolute path
vim.opt.statusline = " %{expand('%:.')} %m%=%l:%c "
vim.opt.winborder = 'rounded'
-- Keys pressed for mappings stay off screen, so popups appear without showing how
vim.opt.showcmd = false

require('onedark').setup({ style = 'darker' })
require('onedark').load()

require('blink.cmp').setup({
  keymap = { preset = 'enter' },
  -- Pure Lua matcher, so no prebuilt binary is downloaded. Ties sort by label, so the
  -- menu order is the same on every render
  fuzzy = { implementation = 'lua', sorts = { 'score', 'sort_text', 'label' } },
  completion = {
    -- Label only: VHS draws Nerd Font kind icons wider than one cell
    menu = { draw = { columns = { { 'label' } } } },
    -- Show each fixture's YAML next to the menu
    documentation = { auto_show = true, auto_show_delay_ms = 0 },
    list = { selection = { preselect = true, auto_insert = false } },
  },
  signature = { enabled = false },
  sources = { default = { 'lsp' } },
})

vim.lsp.enable('rails_fixture_ls')

-- K (hover) is a Neovim default; gd matches the common go-to-definition mapping
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'go to definition' })
