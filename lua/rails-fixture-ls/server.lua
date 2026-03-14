local M = {}

local fixtures = require('rails-fixture-ls.fixtures')

local capabilities = {
  textDocumentSync = vim.lsp.protocol.TextDocumentSyncKind.None,
  completionProvider = {
    triggerCharacters = { ':' },
  },
  hoverProvider = true,
  definitionProvider = true,
}

--- Parse fixture reference at cursor position.
--- @param line string
--- @param col integer 0-indexed cursor column
--- @return { type_name: string, fixture_name: string? }?
local function parse_fixture_at_cursor(line, col)
  -- Expand from cursor to find the word boundary
  local left = col + 1
  while left > 1 and line:sub(left - 1, left - 1):match('[%w_]') do
    left = left - 1
  end
  local right = col + 1
  while right < #line and line:sub(right + 1, right + 1):match('[%w_]') do
    right = right + 1
  end

  local word = line:sub(left, right)
  if word == '' then
    return nil
  end

  -- Check if preceded by : (fixture name like :bob in users(:bob))
  local char_before = left > 1 and line:sub(left - 1, left - 1) or ''
  if char_before == ':' then
    local before = line:sub(1, left - 2)
    local type_name = before:match('([%w_]+)%([^)]*$')
    if type_name then
      return { type_name = type_name, fixture_name = word }
    end
  end

  -- Check if followed by ( (fixture type like users in users(:bob))
  local char_after = right < #line and line:sub(right + 1, right + 1) or ''
  if char_after == '(' then
    return { type_name = word }
  end

  return nil
end

local function is_test_file(uri)
  local path = vim.uri_to_fname(uri)
  return path:find('/test/') ~= nil or path:find('/spec/') ~= nil
end

function M.create(dispatchers)
  local root_dir
  local closing = false
  local request_id = 0

  local methods = {}

  function methods.initialize(params, callback)
    root_dir = params.rootUri and vim.uri_to_fname(params.rootUri) or nil
    return callback(nil, { capabilities = capabilities })
  end

  function methods.shutdown(_, callback)
    return callback(nil, nil)
  end

  methods['textDocument/completion'] = function(params, callback)
    if not root_dir or not is_test_file(params.textDocument.uri) then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1]
    if not line then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    local col = params.position.character
    local before = line:sub(1, col)

    -- Name completion: type_name(:partial
    local type_name, partial = before:match('([%w_]+)%(:([%w_]*)$')
    if type_name and fixtures.valid_type(root_dir, type_name) then
      local names = fixtures.get_names(root_dir, type_name)
      if #names > 0 then
        local colon_pos = col - #partial - 1

        local items = {}
        for _, name in ipairs(names) do
          local doc = fixtures.get_documentation(root_dir, type_name, name)
          local item = {
            filterText = ':' .. name,
            label = ':' .. name,
            textEdit = {
              newText = ':' .. name,
              range = {
                start = { line = params.position.line, character = colon_pos },
                ['end'] = { line = params.position.line, character = col },
              },
            },
          }
          if doc ~= '' then
            item.documentation = doc
          end
          table.insert(items, item)
        end

        return callback(nil, { isIncomplete = false, items = items })
      end
    end

    -- Don't return type completions inside a fixture call
    local enclosing_type = before:match('([%w_]+)%([^)]*$')
    if enclosing_type and fixtures.valid_type(root_dir, enclosing_type) then
      return callback(nil, { isIncomplete = false, items = {} })
    end

    -- Type completions
    local types = fixtures.get_types(root_dir)
    if #types > 0 then
      local items = {}
      for _, t in ipairs(types) do
        table.insert(items, {
          label = t,
          insertText = t .. '(',
        })
      end
      return callback(nil, { isIncomplete = false, items = items })
    end

    callback(nil, { isIncomplete = false, items = {} })
  end

  methods['textDocument/hover'] = function(params, callback)
    if not root_dir or not is_test_file(params.textDocument.uri) then
      return callback(nil, nil)
    end

    local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1]
    if not line then
      return callback(nil, nil)
    end

    local ref = parse_fixture_at_cursor(line, params.position.character)
    if not ref then
      return callback(nil, nil)
    end

    if not fixtures.valid_type(root_dir, ref.type_name) then
      return callback(nil, nil)
    end

    local value
    if ref.fixture_name then
      local doc = fixtures.get_documentation(root_dir, ref.type_name, ref.fixture_name)
      if doc == '' then
        return callback(nil, nil)
      end
      value = '```yaml\n' .. doc .. '```'
    else
      -- Hovering over the type name: show available fixtures
      local names = fixtures.get_names(root_dir, ref.type_name)
      if #names == 0 then
        return callback(nil, nil)
      end
      local file = fixtures.get_type_file(root_dir, ref.type_name)
      local parts = { '**' .. ref.type_name .. '** fixtures' }
      if file then
        local display_path = file:sub(#root_dir + 2)
        table.insert(parts, '')
        table.insert(parts, '`' .. display_path .. '`')
      end
      table.insert(parts, '')
      for _, n in ipairs(names) do
        table.insert(parts, '- `' .. n .. '`')
      end
      value = table.concat(parts, '\n')
    end

    callback(nil, {
      contents = {
        kind = vim.lsp.protocol.MarkupKind.Markdown,
        value = value,
      },
    })
  end

  methods['textDocument/definition'] = function(params, callback)
    if not root_dir or not is_test_file(params.textDocument.uri) then
      return callback(nil, nil)
    end

    local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1]
    if not line then
      return callback(nil, nil)
    end

    local ref = parse_fixture_at_cursor(line, params.position.character)
    if not ref then
      return callback(nil, nil)
    end

    local file = fixtures.get_type_file(root_dir, ref.type_name)
    if not file then
      return callback(nil, nil)
    end

    local target_line = 0
    if ref.fixture_name then
      local name_line = fixtures.get_name_line(root_dir, ref.type_name, ref.fixture_name)
      if name_line then
        target_line = name_line
      end
    end

    callback(nil, {
      uri = vim.uri_from_fname(file),
      range = {
        start = { line = target_line, character = 0 },
        ['end'] = { line = target_line, character = 0 },
      },
    })
  end

  -- Dispatch table
  local res = {}

  function res.request(method, params, callback)
    local handler = methods[method]
    if handler then
      handler(params, callback)
    end
    request_id = request_id + 1
    return true, request_id
  end

  function res.notify(method, _)
    if method == 'exit' then
      dispatchers.on_exit(0, 15)
    end
    return false
  end

  function res.is_closing()
    return closing
  end

  function res.terminate()
    closing = true
  end

  return res
end

return M
