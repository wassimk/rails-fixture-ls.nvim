return {
  cmd = function(dispatchers)
    return require('rails-fixture-ls.server').create(dispatchers)
  end,
  filetypes = { 'ruby' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'Gemfile', 'Rakefile', '.git' })
    if not root then
      return on_dir()
    end

    for _, dir in ipairs({ 'test/fixtures', 'spec/fixtures' }) do
      if vim.uv.fs_stat(root .. '/' .. dir) then
        return on_dir(root)
      end
    end

    on_dir()
  end,
}
