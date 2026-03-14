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
      names = {},
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
    if vim.fn.isdirectory(fixture_dir) == 1 then
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
    for _, ext in ipairs({ 'yml', 'yaml' }) do
      local pattern = dir .. '/**/*.' .. ext
      local found = vim.fn.glob(pattern, false, true)
      for _, file in ipairs(found) do
        table.insert(files, { path = file, dir = dir })
      end
    end
  end

  cache.files = files
  return files
end

function M.get_types(root_dir)
  local cache = get_cache(root_dir)
  if cache.types then
    return cache.types
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
  return types
end

function M.valid_type(root_dir, type_name)
  if not type_name or type_name == '' then
    return false
  end

  local cache = get_cache(root_dir)
  if not cache.type_to_file then
    M.get_types(root_dir)
    cache = get_cache(root_dir)
  end

  return cache.type_to_file[type_name] ~= nil
end

function M.get_type_file(root_dir, type_name)
  local cache = get_cache(root_dir)
  if not cache.type_to_file then
    M.get_types(root_dir)
    cache = get_cache(root_dir)
  end

  return cache.type_to_file[type_name]
end

function M.get_names(root_dir, type_name)
  local cache = get_cache(root_dir)
  if cache.names[type_name] then
    return cache.names[type_name]
  end

  local filename = M.get_type_file(root_dir, type_name)
  if not filename then
    return {}
  end

  local names = {}
  local ok, _ = pcall(function()
    local file = io.open(filename, 'r')
    if not file then
      return
    end

    for line in file:lines() do
      local name = line:match('^([%w_]+):')
      if name then
        table.insert(names, name)
      end
    end

    file:close()
  end)

  if not ok then
    return {}
  end

  cache.names[type_name] = names
  return names
end

function M.get_documentation(root_dir, type_name, name)
  local filename = M.get_type_file(root_dir, type_name)
  if not filename then
    return ''
  end

  local documentation = ''
  local ok, _ = pcall(function()
    local file = io.open(filename, 'r')
    if not file then
      return
    end

    local matched = false
    local indent_level = nil

    for line in file:lines() do
      if not matched then
        if line:match('^' .. name .. ':') then
          matched = true
          documentation = name .. ':\n'
          indent_level = nil
        end
      else
        if line == '' or line == '--' then
          matched = false
        elseif indent_level == nil then
          indent_level = line:match('^(%s+)')
          if indent_level and #indent_level > 0 then
            documentation = documentation .. line .. '\n'
          else
            matched = false
          end
        else
          local current_indent = line:match('^(%s+)')
          if current_indent and #current_indent >= #indent_level then
            documentation = documentation .. line .. '\n'
          else
            matched = false
          end
        end
      end
    end

    file:close()
  end)

  if not ok then
    return ''
  end

  return documentation
end

function M.get_name_line(root_dir, type_name, name)
  local filename = M.get_type_file(root_dir, type_name)
  if not filename then
    return nil
  end

  local line_num = nil
  local ok, _ = pcall(function()
    local file = io.open(filename, 'r')
    if not file then
      return
    end

    local i = 0
    for line in file:lines() do
      if line:match('^' .. name .. ':') then
        line_num = i
        break
      end
      i = i + 1
    end

    file:close()
  end)

  if not ok then
    return nil
  end

  return line_num
end

return M
