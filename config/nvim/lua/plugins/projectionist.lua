local cmd = vim.cmd
local fn = vim.fn
local g = vim.g
local p = {}

local transformations = {
  mag_rm_pool = function(input, _)
    return fn.substitute(input, [[^\(core/\|community/\|local/\)]], '', '')
  end,
  mag_add_block = function(input, _)
    return input:gsub('^([^/]*/[^/]*)', '%1/Block')
  end,
}

-- mapping - disabled in favour of alternate.lua
-- u.map('n', '<space>ta', ':A<cr>', { silent = false })

-- heuristics
local magento_module = {
    ['*'] = {
        ['project_root'] = 1,
    },
    ['app/code/**/Block/*.php'] = {
        alternate = "app/design/frontend/base/default/template/{mag_rm_pool|snakecase}.phtml"
    },
    ['app/design/frontend/base/default/template/*.phtml'] = {
        alternate = {
            "app/code/core/{camelcase|capitalize|mag_add_block}.php",
            "app/code/community/{camelcase|capitalize|mag_add_block}.php",
            "app/code/local/{camelcase|capitalize|mag_add_block}.php"
        }
    }
}
local magento2_module =
         {
           ['*'] = {
             ['project_root'] = 1,
           }
        }
local laravel =
         {
           ['*'] = {
             project = "laravel",
             env = {APP_ENV = 'testing'},
           },
         }
local phoenixframework =
         {
           ['*'] = {
             start = "iex --sname phoenix -S mix phoenix.server",
             console = "iex --sname relp",
           },
         }
g.projectionist_heuristics = {
    ["composer.json&app/Mage.php"] = magento_module,
    ["composer.json&bin/magento"] = magento2_module,
    ["artisan&composer.json"] = laravel,
    ["mix.exs&deps/phoenix/"] = phoenixframework,
}

-- call proper lua transformation define in transformations table
function p.transformation(transformation, input, options)
  return transformations[transformation](input, options)
end

-- generate vim functions for transformations list end result looks like this:
--
-- function! g:projectionist_transformations.fn_name(i, o) abort
-- return luaeval("require'plugins.projectionist'.transformation(_A[1], _A[2], _A[3])", ["fn_name", a:i, a:o])
-- endfunction
cmd([[let g:projectionist_transformations = get(g:, "projectionist_transformations", {})]])
for t_name, _ in pairs(transformations) do
  local def = 'function! g:projectionist_transformations.' .. t_name .. '(i, o) abort\n'
    .. [[return luaeval("require'plugins.projectionist'.transformation]]
    .. '(_A[1], _A[2], _A[3])", ["' .. t_name .. '", a:i, a:o])\n'
    .. 'endfunction\n'

  cmd(def)
end

return p
