---@type LazyPluginSpec
return {
  'l3mon4d3/luasnip',
  dependencies = {
    'honza/vim-snippets',
  },
  event = 'InsertEnter',
  config = function()
    local ls = require('luasnip')
    local select_choice = require('luasnip.extras.select_choice')
    local types = require('luasnip.util.types')
    local from_cursor = require('luasnip.extras.filetype_functions').from_cursor_pos

    ls.config.setup({
      history = true,
      delete_check_events = 'TextChanged,InsertLeave',
      update_events = 'TextChanged,TextChangedI',
      store_selection_keys = '<tab>',
      ft_func = function()
        local fts = from_cursor()

        fts[#fts + 1] = vim.bo.filetype
        fts[#fts + 1] = vim.fn.expand('%:e')

        return fts
      end,
      ext_opts = {
        [types.choiceNode] = {
          active = { virt_text = { { '     select choice <c-s>', 'DiagnosticInfo' } } },
        },
      },
    })

    vim.keymap.set({ 'i', 's' }, '<c-n>', function()
      if ls.jumpable(1) then
        ls.jump(1)
      end
    end)

    vim.keymap.set({ 'i', 's' }, '<c-p>', function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end)

    vim.keymap.set({ 'i', 's' }, '<c-s>', function()
      if ls.choice_active() then
        if #ls.get_current_choices() > 3 then
          select_choice()
        else
          ls.change_choice(1)
        end
      end
    end)

    local function re_require(module_name)
      package.loaded[module_name] = nil
      return require(module_name)
    end

    -- clean up default snippets, dont care about them
    ls.cleanup()

    -- load per project snippets {{{
    local projector = require('projector')
    local paths = projector.get_config('luasnip.paths', {})

    require('luasnip.loaders.from_snipmate').lazy_load({
      paths = paths,
      override_priority = 1500,
    })
    require('luasnip.loaders.from_snipmate').lazy_load({
      override_priority = 1250,
    })

    re_require('pbogut.plugins.luasnip.helper')
    re_require('pbogut.plugins.luasnip.common')
    re_require('pbogut.plugins.luasnip.emojis')
    re_require('pbogut.plugins.luasnip.phtml')
    re_require('pbogut.plugins.luasnip.php')
    re_require('pbogut.plugins.luasnip.js')
    re_require('pbogut.plugins.luasnip.lua')
    re_require('pbogut.plugins.luasnip.magento2')
    re_require('pbogut.plugins.luasnip.rust')
    re_require('pbogut.plugins.luasnip.elixir')
    re_require('pbogut.plugins.luasnip.go')

    local command = vim.api.nvim_create_user_command
    command('LuaSnipReload', function(_)
      re_require('pbogut.plugins.luasnip').config()
    end, {})
  end,
}
