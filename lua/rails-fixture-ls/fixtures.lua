local M = {}

local _caches = {}

function M._reset_cache(root_dir)
  if root_dir then
    _caches[root_dir] = nil
  else
    _caches = {}
  end
end

local function get_cache(root_dir)
  if not _caches[root_dir] then
    _caches[root_dir] = {
      fixture_dirs = nil,
      files = nil,
      types = nil,
      type_to_file = nil,
      parsed = {},
    }
  end
  return _caches[root_dir]
end

function M.fixture_dirs(root_dir)
  local cache = get_cache(root_dir)
  if cache.fixture_dirs then
    return cache.fixture_dirs
  end

  local dirs = {}
  for _, dir_name in ipairs({ 'test', 'spec' }) do
    local fixture_dir = root_dir .. '/' .. dir_name .. '/fixtures'
    if vim.uv.fs_stat(fixture_dir) then
      table.insert(dirs, fixture_dir)
    end
  end

  cache.fixture_dirs = dirs
  return dirs
end

function M.scan_files(root_dir)
  local cache = get_cache(root_dir)
  if cache.files then
    return cache.files
  end

  local files = {}
  for _, dir in ipairs(M.fixture_dirs(root_dir)) do
    local pattern = dir .. '/**/*.{yml,yaml}'
    local found = vim.fn.glob(pattern, false, true)
    for _, file in ipairs(found) do
      table.insert(files, { path = file, dir = dir })
    end
  end

  cache.files = files
  return files
end

local function ensure_types(root_dir)
  local cache = get_cache(root_dir)
  if cache.type_to_file then
    return cache
  end

  local types = {}
  local type_to_file = {}

  for _, entry in ipairs(M.scan_files(root_dir)) do
    local relative = entry.path:sub(#entry.dir + 2)
    local type_name = relative:match('(.+)%.ya?ml$')
    if type_name then
      type_name = type_name:gsub('/', '_')
      if not type_to_file[type_name] then
        table.insert(types, type_name)
        type_to_file[type_name] = entry.path
      end
    end
  end

  cache.types = types
  cache.type_to_file = type_to_file
  return cache
end

function M.get_types(root_dir)
  return ensure_types(root_dir).types
end

function M.valid_type(root_dir, type_name)
  if not type_name or type_name == '' then
    return false
  end

  return ensure_types(root_dir).type_to_file[type_name] ~= nil
end

function M.get_type_file(root_dir, type_name)
  return ensure_types(root_dir).type_to_file[type_name]
end

--- Parse a fixture YAML file in a single pass, extracting names, line numbers,
--- and documentation blocks for each fixture entry.
local function parse_fixture_file(filename)
  local file = io.open(filename, 'r')
  if not file then
    return nil
  end

  local names = {}
  local docs = {}
  local lines = {}

  local current_name = nil
  local current_lines = nil
  local indent_level = nil
  local line_num = 0

  local ok, _ = pcall(function()
    for line in file:lines() do
      local name = line:match('^([%w_]+):')
      if name then
        -- Flush previous fixture
        if current_name then
          docs[current_name] = table.concat(current_lines, '\n')
        end
        -- Start new fixture
        table.insert(names, name)
        lines[name] = line_num
        current_name = name
        current_lines = { line }
        indent_level = nil
      elseif current_name then
        if line == '' or line == '--' then
          -- End of fixture block
          docs[current_name] = table.concat(current_lines, '\n')
          current_name = nil
          current_lines = nil
          indent_level = nil
        elseif indent_level == nil then
          indent_level = line:match('^(%s+)')
          if indent_level and #indent_level > 0 then
            table.insert(current_lines, line)
          else
            docs[current_name] = table.concat(current_lines, '\n')
            current_name = nil
            current_lines = nil
            indent_level = nil
          end
        else
          local current_indent = line:match('^(%s+)')
          if current_indent and #current_indent >= #indent_level then
            table.insert(current_lines, line)
          else
            docs[current_name] = table.concat(current_lines, '\n')
            current_name = nil
            current_lines = nil
            indent_level = nil
          end
        end
      end
      line_num = line_num + 1
    end
  end)

  file:close()

  if not ok then
    return nil
  end

  -- Flush last fixture
  if current_name then
    docs[current_name] = table.concat(current_lines, '\n')
  end

  return { names = names, docs = docs, lines = lines }
end

local function ensure_parsed(root_dir, type_name)
  local cache = get_cache(root_dir)
  if cache.parsed[type_name] then
    return cache.parsed[type_name]
  end

  local filename = M.get_type_file(root_dir, type_name)
  if not filename then
    return nil
  end

  local result = parse_fixture_file(filename)
  if not result then
    return nil
  end

  cache.parsed[type_name] = result
  return result
end

function M.get_names(root_dir, type_name)
  local parsed = ensure_parsed(root_dir, type_name)
  if not parsed then
    return {}
  end
  return parsed.names
end

function M.get_documentation(root_dir, type_name, name)
  local parsed = ensure_parsed(root_dir, type_name)
  if not parsed or not parsed.docs[name] then
    return ''
  end
  return parsed.docs[name] .. '\n'
end

function M.get_name_line(root_dir, type_name, name)
  local parsed = ensure_parsed(root_dir, type_name)
  if not parsed then
    return nil
  end
  return parsed.lines[name]
end

return M
