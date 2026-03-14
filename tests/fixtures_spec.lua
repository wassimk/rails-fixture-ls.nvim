describe('rails-fixture-ls.fixtures', function()
  local fixtures
  local root_dir

  before_each(function()
    package.loaded['rails-fixture-ls.fixtures'] = nil
    fixtures = require('rails-fixture-ls.fixtures')

    -- Use the test fixture files shipped with the project
    local source = debug.getinfo(1, 'S').source:sub(2)
    root_dir = vim.fn.fnamemodify(source, ':h') .. '/fixtures'

    fixtures._reset_cache()
  end)

  describe('fixture_dirs', function()
    it('finds test/fixtures directory', function()
      local dirs = fixtures.fixture_dirs(root_dir)

      assert.equals(1, #dirs)
      assert.truthy(dirs[1]:find('test/fixtures$'))
    end)

    it('returns empty for a directory without fixtures', function()
      local dirs = fixtures.fixture_dirs('/tmp')

      assert.equals(0, #dirs)
    end)
  end)

  describe('get_types', function()
    it('returns fixture type names from YAML filenames', function()
      local types = fixtures.get_types(root_dir)

      assert.truthy(vim.tbl_contains(types, 'users'))
      assert.truthy(vim.tbl_contains(types, 'posts'))
    end)

    it('does not include non-yaml files', function()
      local types = fixtures.get_types(root_dir)

      for _, t in ipairs(types) do
        assert.falsy(t:find('%.'))
      end
    end)
  end)

  describe('valid_type', function()
    it('returns true for known fixture types', function()
      assert.is_true(fixtures.valid_type(root_dir, 'users'))
      assert.is_true(fixtures.valid_type(root_dir, 'posts'))
    end)

    it('returns false for unknown fixture types', function()
      assert.is_false(fixtures.valid_type(root_dir, 'comments'))
      assert.is_false(fixtures.valid_type(root_dir, ''))
      assert.is_false(fixtures.valid_type(root_dir, nil))
    end)
  end)

  describe('get_type_file', function()
    it('returns the file path for a known type', function()
      local file = fixtures.get_type_file(root_dir, 'users')

      assert.is_not_nil(file)
      assert.truthy(file:find('users%.yml$'))
    end)

    it('returns nil for an unknown type', function()
      assert.is_nil(fixtures.get_type_file(root_dir, 'comments'))
    end)
  end)

  describe('get_names', function()
    it('returns fixture names from a YAML file', function()
      local names = fixtures.get_names(root_dir, 'users')

      assert.equals(3, #names)
      assert.truthy(vim.tbl_contains(names, 'alice'))
      assert.truthy(vim.tbl_contains(names, 'bob'))
      assert.truthy(vim.tbl_contains(names, 'charlie'))
    end)

    it('returns fixture names for posts', function()
      local names = fixtures.get_names(root_dir, 'posts')

      assert.equals(2, #names)
      assert.truthy(vim.tbl_contains(names, 'hello_world'))
      assert.truthy(vim.tbl_contains(names, 'draft_post'))
    end)

    it('returns empty for unknown types', function()
      local names = fixtures.get_names(root_dir, 'comments')

      assert.equals(0, #names)
    end)
  end)

  describe('get_documentation', function()
    it('returns YAML block for a fixture name', function()
      local doc = fixtures.get_documentation(root_dir, 'users', 'alice')

      assert.truthy(doc:find('alice:'))
      assert.truthy(doc:find('name: Alice Smith'))
      assert.truthy(doc:find('email: alice@example.com'))
    end)

    it('returns empty string for unknown fixture name', function()
      local doc = fixtures.get_documentation(root_dir, 'users', 'unknown')

      assert.equals('', doc)
    end)

    it('returns empty string for unknown type', function()
      local doc = fixtures.get_documentation(root_dir, 'comments', 'alice')

      assert.equals('', doc)
    end)

    it('does not include attributes from other fixtures', function()
      local doc = fixtures.get_documentation(root_dir, 'users', 'alice')

      assert.falsy(doc:find('Bob Jones'))
      assert.falsy(doc:find('bob:'))
    end)
  end)

  describe('get_name_line', function()
    it('returns the 0-indexed line number for a fixture', function()
      local line = fixtures.get_name_line(root_dir, 'users', 'alice')

      assert.equals(0, line)
    end)

    it('returns correct line for non-first fixture', function()
      local line = fixtures.get_name_line(root_dir, 'users', 'bob')

      assert.equals(5, line)
    end)

    it('returns nil for unknown fixture name', function()
      local line = fixtures.get_name_line(root_dir, 'users', 'unknown')

      assert.is_nil(line)
    end)

    it('returns nil for unknown type', function()
      local line = fixtures.get_name_line(root_dir, 'comments', 'alice')

      assert.is_nil(line)
    end)
  end)

  describe('caching', function()
    it('returns same results on repeated calls', function()
      local types1 = fixtures.get_types(root_dir)
      local types2 = fixtures.get_types(root_dir)

      assert.same(types1, types2)
    end)

    it('clears cache for a specific root', function()
      fixtures.get_types(root_dir)
      fixtures._reset_cache(root_dir)

      -- Should still work after reset (re-scans)
      local types = fixtures.get_types(root_dir)
      assert.truthy(#types > 0)
    end)
  end)
end)
