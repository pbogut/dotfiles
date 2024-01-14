local ls = require('luasnip')
local sn = ls.sn
local t = ls.t
local f = ls.f
local d = ls.d
local i = ls.i

local M = {}

-- Dynamic Function
M.df = function(n, fn)
  local fun = function()
    return sn(nil, { i(1, fn()) })
  end
  return d(n, fun)
end

function M.visual()
  return f(function(_, snip)
    return snip.env.TM_SELECTED_TEXT or '' -- {}
  end)
end

function M.get_relative_line(num)
  num = num or 0
  local cur_line = vim.fn.line('.')

  return vim.fn.getline(cur_line + num)
end

function M.is_in_comment()
  local line = M.get_relative_line(0)

  local str = M.get_comment_string()
  str = str:gsub('%%s', '.*')
  if line:match(str:gsub('%%s', '.*')) then
    return true
  else
    return false
  end
end

function M.get_comment_string()
  local str = require('ts_context_commentstring.internal').calculate_commentstring({
    key = '__default',
    location = require('ts_context_commentstring.utils').get_cursor_location(),
  })
  if str == nil then
    str = require('Comment.ft').lang(vim.o.ft)[1]
  end
  if str == nil then
    str = vim.bo.commentstring
  end

  return str
end

function M.wrap_in_comment(elements)
  if M.is_in_comment() then
    return sn(nil, elements)
  end

  local str = M.get_comment_string()

  local parts = vim.split(str, '%%s')
  if #parts == 2 then
    local before, after = unpack(parts)
    return sn(nil, { t(vim.trim(before) .. ' '), unpack(elements), t(vim.trim(after)) })
  else
    return sn(nil, { t(vim.trim(str) .. ' '), unpack(elements) })
  end
end

return M
