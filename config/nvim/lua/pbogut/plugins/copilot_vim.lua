---@type LazyPluginSpec
return {
  enabled = false,
  'github/copilot.vim',
  event = 'InsertEnter',
  config = function()
    local has_ls, ls = pcall(require, 'luasnip')
    local k = vim.keymap

    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true

    local function accept_one_line()
      local s = vim.fn['copilot#GetDisplayedSuggestion']()
      vim.fn['copilot#Accept']('')
      local bar = vim.fn['copilot#TextQueuedForInsertion']()

      local outdent = vim.api.nvim_replace_termcodes(vim.fn['repeat']('<left><del>', s.outdentSize), true, false, true)
      local delete = vim.api.nvim_replace_termcodes(vim.fn['repeat']('<del>', s.deleteSize), true, false, true)

      local lines = vim.split(bar, '\n')
      vim.api.nvim_feedkeys(outdent, 'i', false)

      if lines[1]:len() == 0 then
        local fix_indent = vim.api.nvim_replace_termcodes('<cr><c-w>', true, false, true)
        if lines[3] == nil then
          vim.api.nvim_feedkeys(delete, 'i', false)
        end
        return fix_indent .. lines[2]
      else
        if lines[2] == nil then
          vim.api.nvim_feedkeys(delete, 'i', false)
        end
        return lines[1]
      end
    end

    local function accept_one_word()
      vim.fn['copilot#Accept']('')
      local bar = vim.fn['copilot#TextQueuedForInsertion']()
      return vim.fn.split(bar, [[[ .]\zs]])[1]
    end

    local function accept_all()
      local suggestion = vim.fn['copilot#Accept']('')
      return suggestion
    end

    k.set('i', '<C-e>', accept_one_line, { expr = true, remap = false, replace_keycodes = false })
    k.set('i', '<C-l>', accept_one_word, { expr = true, remap = false, replace_keycodes = false })
    k.set('i', '<C-f>', accept_all, { expr = true, remap = false, replace_keycodes = false })

    if has_ls then
      k.set('i', '<c-j>', function()
        if ls.jumpable(1) then
          ls.jump(1)
        else
          vim.fn['copilot#Next']()
        end
      end)
    else
      k.set('i', '<c-j>', '<Plug>(copilot-next)')
    end
  end,
}
