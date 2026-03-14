return {
  cmd = function(dispatchers)
    return require('rails-fixture-ls.server').create(dispatchers)
  end,
  filetypes = { 'ruby' },
  root_markers = { 'Gemfile', 'Rakefile', '.git' },
}
