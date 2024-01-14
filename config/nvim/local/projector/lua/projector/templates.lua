local shared = require('projector.shared')
local ph = require('projector.templates.placeholders')
local u = require('pbogut.utils')
local fn = vim.fn

local M = {}

local templates_path = fn.stdpath('config') .. '/templates'
local engine = 'raw'

local function load_placeholder(placeholder)
  if ph[placeholder] then
    return ph[placeholder]
  end

  -- placeholder module
  local is_module, ph_module = pcall(require, 'projector.templates.placeholders.' .. placeholder)
  if is_module then
    return ph_module
  end

  -- placeholder collection module
  if placeholder:match('%.') then
    local fun = placeholder:gsub('.*%.(.-)$', '%1')
    local file = placeholder:gsub('(.*)%..-$', '%1')

    is_module, ph_module = pcall(require, 'projector.templates.placeholders.' .. file)
    if is_module and ph_module[fun] then
      return ph_module[fun]
    end
  end
end

local function collect_placeholders(lines)
  local result = {}
  for _, line in ipairs(lines) do
    for placeholder in line:gmatch('%[%[([%w%_%-%.]-)%]%]') do
      if not result[placeholder] then
        local ph_cfg = load_placeholder(placeholder)
        if ph_cfg then
          result[placeholder] = ph_cfg
        end
      end
    end
  end
  return result
end

local function replace_placeholders(lines, placeholders)
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

local function process_placeholders(lines)
  local placeholders = collect_placeholders(lines)
  local result = {}
  for name, config in pairs(placeholders) do
    local value = config()
    if value and value:len() > 0 then
      -- escape backslashes to unify behavior between templates and snippets
      result[name] = value:gsub([[\]], [[\\]])
    else
      result[name] = name
    end
  end

  return replace_placeholders(lines, result)
end

function M.file_template(name)
  local template = io.open(templates_path .. '/' .. name .. '.snippet', 'r')
  if template == nil then
    print('Template not found')
    return
  end
  local lines = vim.split(template:read('*a'), '\n')
  if lines[#lines] == '' then
    table.remove(lines)
  end
  if engine == 'luasnip' then
    local has_luasnip, ls = pcall(require, 'luasnip')
    if has_luasnip then
      lines = process_placeholders(lines)
      ls.snip_expand(ls.parser.parse_snippet('', vim.fn.join(lines, '\n')), {})
    else
      engine = 'raw'
      print('You dont have snippy installed, falling back to raw engine')
    end
  end
  if engine == 'snippy' then
    local has_snippy, snippy = pcall(require, 'snippy')
    if has_snippy then
      snippy.expand_snippet({
        body = process_placeholders(lines),
        kind = 'snipmate',
      })
    else
      engine = 'raw'
      print('You dont have snippy installed, falling back to raw engine')
    end
  end
  if engine == 'raw' then
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
  end
end

function M.setup(opts)
  if opts.templates and opts.templates.path then
    templates_path = opts.templates.path
  end
  if opts.templates and opts.templates.engine then
    engine = opts.templates.engine
  end
end

function M.template_list(lead)
  local part = #fn.split(lead, '/') + 1
  local result = {}
  local file_list = u.glob(templates_path .. '**/*.snippet')
  for _, file in ipairs(file_list) do
    file = file:gsub('^' .. templates_path .. '/', '')
    file = file:gsub('%.snippet$', '')

    local parts = fn.split(file, '/')

    if file:sub(1, lead:len()) == lead then
      table.insert(result, file)
    end
  end

  return result
end

function M.template_command(args)
  if args and args:len() > 0 then
    M.file_template(args)
  else
    M.do_template()
  end
end

-- create template
function M.do_template()
  -- Abort on non-empty buffer or extant file
  if fn.line('$') ~= 1 or fn.getline('$') ~= '' then
    print('You can use template only in empty file.')
    return
  end

  local file_config = shared.get_file_config()

  if type(file_config.template) == 'string' then
    return M.file_template(file_config.template)
  end
end

function M.process_placeholder(placeholder)
  local ph_cfg = load_placeholder(placeholder)
  if ph_cfg then
    return ph_cfg()
  else
    return placeholder
  end
end

return M
