local k = vim.keymap

return {
  'tpope/vim-dadbod',
  dependencies = { 'pbogut/vim-dadbod-ssh' },
  keys = {
    { '<space>fd', '<plug>(dadbod-select-database)' },
    { '<space>d', '<plug>(dadbod-run-query-selection)', mode = { 'n', 'v' } },
    { '<space>D', '<plug>(dadbod-run-query-file)', mode = { 'n', 'v' } },
  },
  cmd = 'DB',
  init = function()
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('x_dadbod', { clear = true }),
      pattern = '*.dbout',
      callback = function()
        vim.cmd.wincmd('L')
        -- alternate file override for dbout && sql file
        k.set('n', '<space>ta', function()
          local dbout = vim.fn.expand('%')
          local db = vim.b.db
          vim.cmd.edit(vim.b.db_input)
          vim.defer_fn(function()
            k.set('n', '<space>ta', function()
              vim.cmd.edit(dbout)
            end, { buffer = true })
            k.set('n', 'q', '<c-w>q', { buffer = true })
            vim.b.db = db
          end, 100)
        end, { buffer = true })
      end,
    })
  end,
  config = function()
    local function load_connections()
      local config = require('pbogut.config')
      for _, connection in pairs(config.get('dadbod.connections', {})) do
        local name = connection.name
        local uri = connection.uri
        vim.g[name] = uri
      end
    end

    local function run_query_region(firstline, lastline)
      local db = vim.b.db or ''
      local db_selected = vim.b.db_selected or ''

      if firstline == 0 then
        vim.notify('No query selected', vim.log.levels.ERROR, { title = 'dadbod' })
      end

      if db == '' then
        vim.notify('No DB selected', vim.log.levels.ERROR, { title = 'dadbod' })
        return
      elseif db_selected == '' then
        vim.notify('Unknown DB selected, be careful what you are doing.', vim.log.levels.WARN, { title = 'dadbod' })
      elseif db_selected:match('_prod$') then
        vim.notify('Production DB selected, be careful what you are doing.', vim.log.levels.WARN, { title = 'dadbod' })
      end

      local has_change = false
      for _, line in ipairs(vim.fn.getline(firstline, lastline)) do
        local checks = {
          ' insert ',
          '^insert ',
          ' insert$',
          ' update ',
          '^update ',
          ' update$',
          ' delete ',
          '^delete ',
          ' delete$',
          ' upsert ',
          '^upsert ',
          ' upsert$',
          ' truncate ',
          '^truncate ',
          ' truncate$',
          ' alter ',
          '^alter ',
          ' alter$',
          ' drop ',
          '^drop ',
          ' drop$',
        }
        if not line:match('^%s*%-%-') then -- skip if comment
          for _, pattern in ipairs(checks) do
            if line:lower():match(pattern) then
              has_change = true
            end
          end
        end
      end

      local halt = false -- perform query
      if has_change then
        halt = 1
          ~= vim.fn.confirm(
            'You are about to do some changes, are you sure you know what you are doing?',
            'Yes\nNo',
            'No'
          )
        if not halt and db_selected:match('_prod$') then
          halt = 1
            ~= vim.fn.confirm(
              'You know this is Production DB right? Are you sure you want to continue?',
              'Yes\nNo',
              'No'
            )
        end
      end

      if not halt then
        vim.fn['db#execute_command']('', false, firstline, lastline, '')
      end
    end

    k.set({ 'n', 'v' }, '<plug>(dadbod-run-query-selection)', function()
      vim.h.send_esc()
      local firstline = vim.fn.line("'<")
      local lastline = vim.fn.line("'>")
      run_query_region(firstline, lastline)
    end)

    k.set({ 'n', 'v' }, '<plug>(dadbod-run-query-file)', function()
      local firstline = 1
      local lastline = vim.fn.line('$')
      run_query_region(firstline, lastline)
    end)

    k.set('n', '<plug>(dadbod-select-database)', function()
      local actions = require('telescope.actions')
      local finders = require('telescope.finders')
      local pickers = require('telescope.pickers')
      local action_state = require('telescope.actions.state')
      local conf = require('telescope.config').values
      load_connections()
      pickers
        .new({
          prompt_title = 'Database',
          finder = finders.new_table({
            results = vim.fn['db#url_complete']('g:') or {},
            -- entry_maker = ''
          }),
          sorter = conf.file_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              if selection == nil then
                return
              end
              actions.close(prompt_bufnr)
              vim.b.db = vim.api.nvim_eval(selection[1])
              vim.b.db_selected = selection[1]
              vim.schedule(function()
                vim.fn['db#adapter#ssh#create_tunnel'](vim.b.db)
                vim.o.filetype = vim.o.filetype -- make sure cmp loads dadbod
              end)
            end)
            return true
          end,
        }, {})
        :find()
    end)
  end,
}
