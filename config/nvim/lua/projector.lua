--[[ projector module -- its like... projectionist I guess ]]

--[[ handles themplates and alternate files based on some patterns
     unlike projectionist it uses full patternmatching (lua one) so you have
     more freedom in configuration
     alternate file uses fzf if more then one candidate returned
     templates can be ultisnip snippets or files with placeholders ]]

local u = require('utils')
local s = require('snippy')
local shared = require('snippy.shared')
local ph = require('template.placeholders')

local t = u.termcodes
local g = vim.g
local b = vim.b
local fn = vim.fn
local cmd = vim.cmd

local a = {}
local l = {}

-- how many lines from botton and top to search for alternate annotation
local search_lines = 10
local templates_path = os.getenv('HOME') .. '/.config/nvim/templates'
local configuration = require('plugins.projector')

function a.ultisnip_template(name)
  cmd("silent! normal! i_t" .. name .. t'<c-r>=UltiSnips#ExpandSnippet()<cr>')
  if not g.ulti_expand_res or g.ulti_expand_res == 0 then
    cmd("silent! undo")
  end
  return g.ulti_expand_res and g.ulti_expand_res ~= 0
end

function a.expand_snippet()
  for _, snippets in pairs(shared.cache) do
    for _, snippet in pairs(snippets) do
      snippet.body = l.placeholders_to_eval(snippet.body)
    end
  end

  s.expand_or_advance()
end

function a.file_template(name)
    local template = io.open(templates_path .. '/' .. name .. '.snippet', 'r')
    local lines = vim.split(template:read('*a'), '\n')
    if lines[#lines] == '' then
        table.remove(lines)
    end
    s.expand_snippet({
      body = a.process_placeholders(lines),
      kind = 'snipmate'
    })
end

function a.process_placeholder(placeholder)
  local ph_cfg = l.load_placeholder(placeholder)
  if ph_cfg then
    return ph_cfg.value()
  else
    return placeholder
  end
end

function a.process_placeholders(lines)
  local placeholders = l.collect_placeholders(lines)
  local result = {}
  for name, config in pairs(placeholders) do
    local value = config.value()
    if value and value:len() > 0 then
      -- escape backslashes to unify behavior between templates and snippets
      result[name] = value:gsub([[\]], [[\\]])
    else
      result[name] = name
    end
  end

  return l.replace_placeholders(lines, result)
end

function a.template_list()
  local result = {}
  local file_list = u.glob(templates_path .. "**/*.snippet")
  for _, file in ipairs(file_list) do
    file = file:gsub('^' .. templates_path .. '/', '')
    file = file:gsub('%.snippet$', '')
    table.insert(result, file)
  end

  return table.concat(result, '\n')
end

function a.template_from_cmd(args)
  print(args)
  if args and args:len() > 0 then
    a.file_template(args)
  else
    a.do_template();
  end
end

-- create template
function a.generate(generator_name)
  local generators = l.get_project_generators()
  if not generators[generator_name] then
    print('Generator ' .. generator_name .. ' not found');
  end

  -- generators[generator_name].variables

end

-- create template
function a.do_template()
  -- Abort on non-empty buffer or extant file
  if fn.line('$') ~= 1 or fn.getline('$') ~= '' then
    print("You can use template only in empty file.")
    return
  end

  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local file_configs = l.get_file_configs(cwd, relative)
  -- print(vim.inspect(file_configs))

  for _, config in u.spairs(file_configs, l.sort) do
    if type(config.template) == 'string' and config.template:match('^%_') then
      -- print('ulti', config.template);
      if a.ultisnip_template(config.template) then -- try till it lands
        return true
      end
    elseif type(config.template) == 'string' then
      -- print('file', config.template);
      return a.file_template(config.template)
    end
  end
end

-- member functions
function a.go_alternate()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local file_configs = l.get_file_configs(cwd, relative)
  local result = {}

  for _, cfg in u.spairs(file_configs) do
    if type(cfg.alternate) == 'string' then
      local file, _ = relative:gsub(cfg.pattern, cfg.alternate)
      result[#result+1] = file
    elseif type(cfg.alternate) == 'table' then
      for _, alternate_item in ipairs(cfg.alternate) do
        local file, _ = relative:gsub(cfg.pattern, alternate_item)
        result[#result+1] = file
      end
    elseif type(cfg.alternate) == 'function' then
      local match = {relative:match(cfg.pattern)}
      result = u.merge_tables(result, cfg.alternate(relative, {
        match = match, file = filename, dir = cwd
      }))
    end
  end

  result = u.unique(result)

  -- only existing files if any --
  local existing = {}
  for _, file in ipairs(result) do
    if fn.filereadable(fn.getcwd() .. '/' .. file) > 0 then
      existing[#existing+1] = file
    end
  end

  existing = u.unique(existing)

  if #existing > 0 then
    l.select_alternate(existing)
  else
    l.select_alternate(result)
  end
end

function l.placeholders_to_eval(lines)
  local result = {}
  for _, line in ipairs(lines) do
      result[#result+1] = line:gsub('%[%[(.-)%]%]', [[`v:lua.projector.placeholder('%1')`]])
  end
  return result
end

function l.select_alternate(files)
  if #files == 1 then
    cmd('e ' .. files[1])
    return true
  elseif #files > 1 then
    l.ask(files)
    return true
  end
end

function a.find_alternate()
  local start_line = 1
  local end_line = fn.line('$')
  local lines = math.max(end_line, search_lines)

  local alternate_mark = '.- alternate: (.*)'

  for i = start_line, lines, 1 do
    local line = fn.getline(i)
    if line:match(alternate_mark) then
      local result, _ = line:gsub(alternate_mark, '%1')
      return ">>>" .. result
    end
  end
  for i = end_line, lines, -1 do
    local line = fn.getline(i)
    if line:match(alternate_mark) then
      local result, _ = line:gsub(alternate_mark, '%1')
      return ">>>" .. result
    end
  end

  if b.db_input then
    return b.db_input
  end

  if b.alternate_from then
    return b.alternate_from
  end
end

-- local functions
function l.ask(list)
  local options = {
    source = list,
    options = '--prompt "Select Alternate> " ' .. g.fzf_preview,
    sink = 'e',
  }
  fn['fzf#run'](fn['fzf#wrap'](options))
end

function l.init_project()
  local cwd = fn.getcwd()
  for project_pattern, project_config in u.spairs(configuration, l.sort) do
    if l.check_project(cwd, project_pattern) then
      if type(project_config.project_init) == 'function' then
        return project_config.project_init()
      end
    end
  end
end

function l.get_project_patterns(cwd)
  local result = {}
  for project_pattern, project_config in u.spairs(configuration, l.sort) do
    if l.check_project(cwd, project_pattern) then
      -- first on the list has priority
      result = u.merge_tables(project_config.patterns, result)
    end
  end

  return result
end

function l.get_project_generators(cwd)
  local result = {}
  for project_pattern, project_config in u.spairs(configuration, l.sort) do
    if l.check_project(cwd, project_pattern) then
      -- first on the list has priority
      result = u.merge_tables(project_config.generators, result)
    end
  end

  return result
end

function l.get_file_configs(cwd, relative)
  local project_config = l.get_project_patterns(cwd)
  local result = {}
  for file_pattern, file_config in u.spairs(project_config, l.sort) do
    -- let match many file patterns, or should we - first come first win even without alternate file?
    if l.check_file(relative, file_pattern) then
      -- assign pattern as we dont pass key otherwise
      file_config.pattern = file_pattern
      -- collect all matching ones into list
      result[#result+1] = file_config
    end
  end

  return result
end

function l.check_project(path, pattern)
  if pattern == "*" then
    return true
  end
  if pattern:match('%|') then
    local or_checks = u.split_string(pattern, '|')
    local check = nil
    for _, or_check in ipairs(or_checks) do
      if check == nil then
        check = l.check_project(path, or_check)
      else
        check = check or l.check_project(path, or_check)
      end
    end
    return check
  elseif pattern:match('%&') then
    local and_checks = u.split_string(pattern, '&')
    local check = true
    for _, and_check in ipairs(and_checks) do
      if check == nil then
        check = l.check_project(path, and_check)
      else
        check = check and l.check_project(path, and_check)
      end
    end
    return check
  end

  local check_fn = fn.filereadable
  if pattern:match('%/$') then
    check_fn = fn.isdirectory
  end
  if pattern:match('^%!') then
    return check_fn(path .. '/' .. pattern:gsub('^%!', '')) == 0
  else
    return check_fn(path .. '/' .. pattern) > 0
  end
end

function l.check_file(relative, pattern)
  return relative:match(pattern)
end

function l.replace_placeholders(lines, placeholders)
  local result = {}
  for _, line in ipairs(lines) do
    for placeholder, value in pairs(placeholders) do
      line = line:gsub('%[%[' .. placeholder .. '%]%]', value)
      -- print('%s/' .. placeholder .. '/' .. value .. '/g')
    end
    table.insert(result, line)
  end

  return result
end

function l.load_placeholder(placeholder)
  if  ph[placeholder] then
    return ph[placeholder]
  end

  -- placeholder module
  local is_module, ph_module = pcall(require, 'template.placeholder.' .. placeholder)
  if is_module then
    return ph_module
  end

    -- placeholder collection module
  if placeholder:match('%.') then
    local fun = placeholder:gsub('.*%.(.-)$', '%1')
    local file = placeholder:gsub('(.*)%..-$', '%1')

    is_module, ph_module = pcall(require, 'template.placeholder.' .. file)
    if is_module and ph_module[fun] then
      return ph_module[fun]
    end
  end
end

function l.collect_placeholders(lines)
  local result = {}
  for _, line in ipairs(lines) do
    for placeholder in line:gmatch('%[%[(.-)%]%]') do
      if not result[placeholder] then
        local ph_cfg = l.load_placeholder(placeholder)
        if ph_cfg then
          result[placeholder] = ph_cfg
        end
      end
    end
  end
  return result
end

-- ascending with nil's at the end
function l.sort(tab, key1, key2)
  if not tab[key1].priority then
    return false
  end
  if not tab[key2].priority then
    return true
  end
  return tab[key1].priority < tab[key2].priority
end

u.augroup('x_tttemplates', {
  VimEnter = {'*', l.init_project},
})

_G.projector = _G.projector or {}
_G.projector.temp_completion = a.template_list
_G.projector.placeholder = a.process_placeholder

return a
