return {
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
    -- {'zbirenbaum/copilot-cmp', after = 'copilot.lua'},
    { 'pbogut/copilot-cmp', branch = 'single-line-suggestion', after = 'copilot.lua' },
    'kristijanhusak/vim-dadbod-completion',
  },
  event = 'InsertEnter',
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    local lspkind = require('lspkind')
    local has_copilot, copilot_cmp = pcall(require, 'copilot_cmp')

    local src = {
      lsp = { name = 'nvim_lsp' },
      lua = { name = 'nvim_lua' },
      ts = { name = 'treesitter' },
      db = { name = 'vim-dadbod-completion' },
      tn = { name = 'cmp_tabnine' },
      snip = { name = 'luasnip', keyword_length = 2 },
      path = { name = 'path' },
      tag = { name = 'tags', max_item_count = 15 },
      buf = { name = 'buffer' },
      copilot = { name = 'copilot' },
      cody = { name = 'cody' },
      emo = { name = 'emoji' },
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
      mapping = cmp.mapping.preset.insert({
        -- this is annoying as fuck, but cmp is retarded, why the fuck you force
        -- yorself on my keybindings you fucking cunt ?
        ['<c-n>'] = cmp.mapping(function()
          if luasnip.jumpable(1) then
            luasnip.jump(1)
          end
        end),
        ['<c-p>'] = cmp.mapping(function()
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end),
        -- rant over
        ['<c-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ['<c-k>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        ['<c-u>'] = cmp.mapping.scroll_docs(-4),
        ['<c-d>'] = cmp.mapping.scroll_docs(4),
        ['<c-e>'] = cmp.config.disable,
        ['<c-space>'] = cmp.mapping.complete(),
        ['<c-y>S'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ['<c-o>'] = cmp.mapping(function(_)
          if cmp.visible() then
            cmp.close()
          end
        end),
        ['<tab>'] = cmp.mapping(function(_fallback)
          local entry = cmp.core.view:get_selected_entry()
          if cmp.visible() and entry then
            local item = entry:get_completion_item()
            if
              item.data
              and type(item.data) == 'table'
              and item.data.snippet
              and item.data.snippet.kind == 'snipmate'
            then
              local placeholders_to_eval = function(lines)
                local result = {}
                for _, line in ipairs(lines) do
                  result[#result + 1] = line:gsub('%[%[([%w%_%-%.]-)%]%]', [[`v:lua.projector.placeholder('%1')`]])
                end
                return result
              end
              for _, snippets in pairs(luasnip.snippets) do
                for _, snippet in pairs(snippets) do
                  if snippet.body then
                    snippet.body = placeholders_to_eval(snippet.body)
                  end
                end
              end
              luasnip.expand_or_advance()
            else
              cmp.confirm({
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
              })
            end
          elseif luasnip.expandable() then
            luasnip.expand()
          else
            -- fallback() -- this is broken for some reason
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[	]], true, true, true), 'n', true)
          end
        end, { 'i', 's' }),
      }),
      sources = {
        src.lsp,
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
          -- fancy icons and a name of kind
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
            cody = '[Cody]',
            ['vim-dadbod-completion'] = '[DB]',
          })[entry.source.name]
          return vim_item
        end,
      },
    })
    local augroup = vim.api.nvim_create_augroup('x_cmp', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'sql,mysql,plsql',
      callback = function()
        cmp.setup.buffer({
          sources = {
            src.db,
            src.lsp,
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
    })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'lua',
      callback = function()
        cmp.setup.buffer({
          sources = {
            src.lua,
            src.lsp,
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
    })
  end,
}
