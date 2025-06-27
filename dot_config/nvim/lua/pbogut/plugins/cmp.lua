return {
  enabled = true,
  'hrsh7th/nvim-cmp',
  dependencies = {
    { 'tzachar/cmp-tabnine', build = './install.sh', after = 'nvim-cmp' },
    'l3mon4d3/luasnip',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lua',
    'hrsh7th/cmp-emoji',
    'ray-x/cmp-treesitter',
    'onsails/lspkind-nvim',
    'saadparwaiz1/cmp_luasnip',
    'kristijanhusak/vim-dadbod-completion',
    'luckasRanarison/tailwind-tools.nvim',
    { 'zbirenbaum/copilot-cmp', after = 'copilot.lua' },
  },
  event = 'InsertEnter',
  config = function()
    local cmp = require('cmp')

    -- Accept one line suggestion hack {{{
    cmp.confirm_line = cmp.sync(function(option, callback)
      option = option or {}
      option.select = option.select or false
      option.behavior = option.behavior or cmp.get_config().confirmation.default_behavior or cmp.ConfirmBehavior.Insert
      callback = callback or function() end

      if cmp.core.view:visible() then
        local e = cmp.core.view:get_selected_entry()
        if not e and option.select then
          e = cmp.core.view:get_first_entry()
        end
        if e then
          if e.completion_item.textEdit and e.completion_item.textEdit.newText then
            e.completion_item.textEdit.newText = vim.split(e.completion_item.textEdit.newText, '\n')[1]
          end
          cmp.core:confirm(e, {
            behavior = option.behavior,
          }, function()
            callback()
            cmp.core:complete(cmp.core:get_context({ reason = cmp.ContextReason.TriggerOnly }))
          end)
          return true
        end
      elseif vim.fn.pumvisible() == 1 then
        local index = vim.fn.complete_info({ 'selected' }).selected
        if index == -1 and option.select then
          index = 0
        end
        if index ~= -1 then
          vim.api.nvim_select_popupmenu_item(index, true, true, {})
          return true
        end
      end
      return false
    end)
    cmp.mapping.confirm_line = function(option)
      return function(fallback)
        if not require('cmp').confirm_line(option) then
          fallback()
        end
      end
    end
    -- Accept one line suggestion hack }}}

    local luasnip = require('luasnip')
    local lspkind = require('lspkind')
    local has_copilot, copilot_cmp = pcall(require, 'copilot_cmp')

    local src = {
      lsp = { name = 'nvim_lsp' },
      lua = { name = 'nvim_lua' },
      ts = { name = 'treesitter' },
      tn = { name = 'cmp_tabnine' },
      snip = { name = 'luasnip', keyword_length = 2 },
      path = { name = 'path' },
      tag = { name = 'tags', max_item_count = 15 },
      buf = { name = 'buffer' },
      copilot = { name = 'copilot' },
      supermaven = { name = 'supermaven' },
      cody = { name = 'cody' },
      emo = { name = 'emoji' },
      dadbod = { name = 'vim-dadbod-completion' },
    }

    if has_copilot then
      copilot_cmp.setup()
    end

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      preselect = cmp.PreselectMode.None,
      experimental = {
        ghost_text = true,
      },
      mapping = cmp.mapping.preset.insert({
        ['<c-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ['<c-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        ['<c-u>'] = cmp.mapping.scroll_docs(-4),
        ['<c-d>'] = cmp.mapping.scroll_docs(4),
        ['<c-e>'] = cmp.config.disable,
        ['<c-space>'] = cmp.mapping.complete(),
        ['<c-l>'] = cmp.mapping.confirm_line({
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        }),
        ['<c-y>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        }),
        ['<c-r>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ['<c-o>'] = cmp.mapping(function(_)
          if cmp.visible() then
            cmp.close()
          end
        end),
        ['<tab>'] = cmp.mapping(function(_fallback)
          if luasnip.expandable() then
            luasnip.expand()
          else
            -- fallback() -- this is broken for some reason
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[	]], true, true, true), 'n', true)
          end
        end, { 'i', 's' }),
      }),
      sources = {
        src.lsp,
        src.supermaven,
        src.copilot,
        src.cody,
        src.ts,
        src.tn,
        src.snip,
        src.path,
        src.tag,
        src.buf,
        src.emo,
      },
      sorting = {
        priority_weight = 2,
      },
      completion = {
        completeopt = 'menu,menuone,noinsert,noselect',
      },
      formatting = {
        format = function(entry, vim_item)
          if vim.g.tailwind_tools_loaded then
            vim_item = require('tailwind-tools.cmp').lspkind_format(entry, vim_item)
            if vim_item.kind == 'Color' then
              vim_item.kind = '󰝤'
            end
          end
          local kind = lspkind.presets.default[vim_item.kind]
          if not kind then
            kind = vim_item.kind
          end
          if kind == 'Copilot' then
            kind = ''
          end
          if kind == 'CopLine' then
            kind = ''
          end
          if kind == 'TabNine' then
            kind = ''
          end
          if kind == 'Supermaven' then
            kind = ''
          end
          vim_item.kind = kind

          -- set a name for each source
          vim_item.menu = ({
            buffer = '[Buf]',
            nvim_lsp = '[LSP]',
            nvim_lua = '[Lua]',
            cmp_tabnine = '[TN]',
            treesitter = '[TS]',
            snippy = '[Snippy]',
            luasnip = '[LSnip]',
            path = '[Path]',
            emoji = '[Emoji]',
            tags = '[Tag]',
            spell = '[Spell]',
            copilot = '[Copilot]',
            supermaven = '[SMV]',
            cody = '[Cody]',
            dadbod = '[DB]',
          })[entry.source.name]
          return vim_item
        end,
      },
    })
    cmp.setup.filetype({ 'sql', 'mysql', 'plsql' }, {
      sources = {
        src.dadbod,
        src.supermaven,
        src.copilot,
        src.cody,
        src.ts,
        src.tn,
        src.snip,
        src.path,
        src.buf,
        src.emo,
      },
    })
    cmp.setup.filetype({ 'lua' }, {
      sources = {
        src.lua,
        src.lsp,
        src.supermaven,
        src.copilot,
        src.cody,
        src.ts,
        src.tn,
        src.snip,
        src.path,
        src.buf,
        src.emo,
      },
    })
  end,
}
