-- projector module -- its like... projectionist I guess
--
-- handles themplates and alternate files based on some patterns
-- unlike projectionist it uses full patternmatching (lua one) so you have
-- more freedom in configuration
-- alternate file uses fzf if more then one candidate returned
-- templates can be ultisnip snippets or files with placeholders

local u = require('utils')
local ph = require('template.placeholders')

local t = u.termcodes
local g = vim.g
local b = vim.b
local fn = vim.fn
local cmd = vim.cmd

local a = {}
local l = {}

u.map('n', '<space>ta', ':lua require"alternate".go_alternate()<cr>', { silent = true })

u.augroup('x_templates', {
    BufNewFile = {
      {'*', function()
          -- initially ft is not available and ultisnip is not working correctly
          -- so we deffer to next loop when ft is set properly
          vim.schedule(function()
            cmd('silent! lua require"alternate".do_template()')
          end)
      end},
    },
})

-- how many lines from botton and top to search for alternate annotation
local search_lines = 10
local fallback = ':A'
local templates_path = os.getenv('HOME') .. '/.config/nvim/templates'

local configuration = {
  -- magento2 project
  ["composer.json&bin/magento"] = {
    order = 100,
    patterns = {
      ['.*/web/templates?/.*/[^/]*%.html$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/templates?/.*/(.-)%.html', '%1/web/%*%*/%2.js')
          return u.glob(glob)
        end
      },
      ['.*/web/js/.*/[^/]*%.js$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/js/.*/(.-)%.js', '%1/web/%*%*/%2.html')
          return u.glob(glob)
        end
      },
      ['app/code/.*/etc/.*/?di.xml'] = {
        template = "_magento2_di",
        order = 100,
      },
      ['app/code/.*/registration.php'] = {
        template = "_magento2_registration",
        order = 100,
      },
      ['.*%.php'] = {
        template = "_magento2_class",
        order = 1000,
      },
    }
  },
  -- match anything
  ["*"] = {
    order = 5000,
    patterns = {
      ['.*%.php'] = {
        template = "file.php",
        order = 5000,
      },
      ['.*'] = {
        template = "_skel",
        order = 5000,
      },
    }
  }
}

function a.ultisnip_template(name)
  cmd("normal! i_t" .. name .. t'<c-r>=UltiSnips#ExpandSnippet()<cr>')

  if not g.ulti_expand_res or g.ulti_expand_res == 0 then
    cmd("silent! undo")
  end

  return g.ulti_expand_res and g.ulti_expand_res ~= 0
end

function a.file_template(name)
    cmd('0r ' .. templates_path .. '/' .. name)
    cmd('$delete') -- remove last line
    a.process_placeholders()
end

-- create template
function a.do_template()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local file_config = l.get_file_config(cwd, relative)

  if type(file_config.template) == 'string' and file_config.template:match('^%_') then
    a.ultisnip_template(file_config.template)
  elseif type(file_config.template) == 'string' then
    a.file_template(file_config.template)
  end
end

function a.process_placeholders()
  local placeholders = a.collect_placeholders()
  local result = {}
  for name, config in pairs(placeholders) do
    result[name] = config.value()
  end
  a.replace_placeholders(result)
  if result['_'] then
    local pos = fn.searchpos('\\[\\[coursor_position\\]\\]', 'n')
    cmd([[silent! %s/\[\[coursor_position\]\]//g]])
    fn.cursor(pos[1], pos[2])
  else
    fn.cursor(fn.line('$'),1)
  end
end

function a.replace_placeholders(placeholders)
  for placeholder, value in pairs(placeholders) do
    print('%s/' .. placeholder .. '/' .. value .. '/g')
    cmd([[silent! %s/\[\[]] .. placeholder .. [[\]\]/]] .. fn.escape(value, '/\\') .. '/g')
  end
end

function a.load_placeholder(placeholder)
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
function a.collect_placeholders()
  local result = {}
  for _, line in ipairs(fn.getline(1, fn.line('$'))) do
    for placeholder in line:gmatch('%[%[(.-)%]%]') do
      if not result[placeholder] then
        local ph_cfg = a.load_placeholder(placeholder)
        if ph_cfg then
          result[placeholder] = ph_cfg
        end
      end
    end
  end
  return result
end

-- member functions
function a.go_alternate()
  local cwd = fn.getcwd()

  for project_pattern, project_config in pairs(configuration) do
    if l.check_project(cwd, project_pattern) and l.handle_project(project_config)then
      return true
    end
  end

  local res, _ = pcall(cmd,fallback)
  if not res then
    cmd([[echo "No alternate file found."]])
  end
  return res
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

function l.get_project_config(cwd)
  local result = {}
  for project_pattern, project_config in u.spairs(configuration, l.sort) do
    if l.check_project(cwd, project_pattern) then
      -- first on the list has priority
      result = u.merge_tables(project_config.patterns, result)
    end
  end

  return result
end

function l.get_file_config(cwd, relative)
  local project_config = l.get_project_config(cwd)
  local result = {}
  for file_pattern, file_config in u.spairs(project_config, l.sort) do
    -- let match many file patterns, or should we - first come first win even without alternate file?
    if l.check_file(relative, file_pattern) then
      -- first on the list has priority, we can fall down with something
      -- like *.js at the end
      result = u.merge_tables(file_config, result)
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

  if pattern:match('^%!') then
    return fn.filereadable(path .. '/' .. pattern:gsub('^%!', '')) == 0
  else
    return fn.filereadable(path .. '/' .. pattern) > 0
  end
end

function l.check_file(relative, pattern)
  return relative:match(pattern)
end

function l.handle_alternate(config)
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local result = config.alternate(relative, {file = filename, dir = cwd})

  if not config.alternate then
    result = {}
  end

  if #result == 1 then
    cmd('e ' .. result[1])
    return true
  elseif #result > 1 then
    l.ask(result)
    return true
  end

  return false
end

function l.handle_project(project_patterns)
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')

  for file_pattern, file_config in pairs(project_patterns) do
    -- let match many file patterns, or should we - first come first win even without alternate file?
    if l.check_file(relative, file_pattern) and l.handle_alternate(file_config) then
      return true
    end
  end

  return false
end

-- ascending with nil's at the end
function l.sort(tab, key1, key2)
  if not tab[key1].order then
    return false
  end
  if not tab[key2].order then
    return true
  end
  return tab[key1].order < tab[key2].order
end

return a
