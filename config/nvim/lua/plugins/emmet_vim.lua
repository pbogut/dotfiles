local u = require('utils')

u.map('i', '<m-tab>', '<c-y>,', {noremap = false})
u.map('i', '<m-n>', '<c-y>n', {noremap = false})
u.map('i', '<m-N>', '<c-y>N', {noremap = false})

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local function expand()
  feedkey("<C-y>,", "i") -- Emmet expand
end

local function can_expand()
  local exts = {'phtml', 'html%.eex', 'heex', 'blade%.php',
    'xml', 'html', 'vue'}

  local is_expandable = has_words_before()
    and vim.g.emmet_debug == 0
    and vim.fn['emmet#isExpandable']() == 1

  if is_expandable then
    local file_name = vim.fn.expand('%:t')

    for _, ext in pairs(exts) do
      if file_name:match(ext .. '$') then
        return true
      end
    end
  end

  return false
end

return {
  expand = expand,
  can_expand = can_expand,
}
