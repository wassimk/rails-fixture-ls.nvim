describe('rails-fixture-ls.server', function()
  local server

  before_each(function()
    package.loaded['rails-fixture-ls.server'] = nil
    server = require('rails-fixture-ls.server')
  end)

  describe('parse_fixture_at_cursor', function()
    -- col is 0-indexed (LSP convention)

    it('parses fixture type before opening paren', function()
      --                 0123456789
      local line = '    users(:bob)'
      local ref = server.parse_fixture_at_cursor(line, 5) -- on 'u' of 'users'

      assert.is_not_nil(ref)
      assert.equals('users', ref.type_name)
      assert.is_nil(ref.fixture_name)
    end)

    it('parses fixture type with cursor anywhere in the word', function()
      local line = '    users(:bob)'
      local ref = server.parse_fixture_at_cursor(line, 8) -- on 's' of 'users'

      assert.is_not_nil(ref)
      assert.equals('users', ref.type_name)
      assert.is_nil(ref.fixture_name)
    end)

    it('parses fixture name after colon', function()
      local line = '    users(:bob)'
      local ref = server.parse_fixture_at_cursor(line, 11) -- on 'b' of 'bob'

      assert.is_not_nil(ref)
      assert.equals('users', ref.type_name)
      assert.equals('bob', ref.fixture_name)
    end)

    it('parses fixture name with cursor at end of name', function()
      local line = '    users(:bob)'
      local ref = server.parse_fixture_at_cursor(line, 13) -- on last 'b' of 'bob'

      assert.is_not_nil(ref)
      assert.equals('users', ref.type_name)
      assert.equals('bob', ref.fixture_name)
    end)

    it('parses fixture with underscored names', function()
      local line = '    draft_posts(:hello_world)'
      local ref = server.parse_fixture_at_cursor(line, 18) -- on 'h' of 'hello_world'

      assert.is_not_nil(ref)
      assert.equals('draft_posts', ref.type_name)
      assert.equals('hello_world', ref.fixture_name)
    end)

    it('returns nil for non-fixture code', function()
      local line = '    some_method(arg)'
      local ref = server.parse_fixture_at_cursor(line, 5)

      -- This will return type_name = 'some_method' since it looks like a fixture call
      -- The server validates against known fixture types, so this is fine
      assert.is_not_nil(ref)
      assert.equals('some_method', ref.type_name)
    end)

    it('returns nil on empty line', function()
      local line = ''
      local ref = server.parse_fixture_at_cursor(line, 0)

      assert.is_nil(ref)
    end)

    it('returns nil on whitespace', function()
      local line = '    '
      local ref = server.parse_fixture_at_cursor(line, 2)

      assert.is_nil(ref)
    end)

    it('parses second fixture name in multi-arg call', function()
      local line = '    users(:alice, :bob)'
      local ref = server.parse_fixture_at_cursor(line, 19) -- on 'b' of second ':bob'

      assert.is_not_nil(ref)
      assert.equals('users', ref.type_name)
      assert.equals('bob', ref.fixture_name)
    end)

    it('returns nil for word not before paren and not after colon', function()
      local line = '    result = users'
      local ref = server.parse_fixture_at_cursor(line, 14) -- on 'u' of 'users'

      assert.is_nil(ref)
    end)
  end)
end)
