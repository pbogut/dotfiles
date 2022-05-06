local k = vim.keymap

local function config()
  k.set('n', '<c-_>', 'gcc<down>', { remap = true })
  k.set('n', '<c-/>', 'gcc<down>', { remap = true })
  k.set('v', '<c-_>', 'gc<down>', { remap = true })
  k.set('v', '<c-/>', 'gc<down>', { remap = true })

  require('Comment').setup({
    ignore = '^$',
    pre_hook = function(ctx)
      local U = require('Comment.utils')

      local location = nil
      if ctx.ctype == U.ctype.block then
        location =
          require('ts_context_commentstring.utils').get_cursor_location()
      elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
        location =
          require('ts_context_commentstring.utils').get_visual_start_location()
      end

      return require('ts_context_commentstring.internal').calculate_commentstring({
        key = ctx.ctype == U.ctype.line and '__default' or '__multiline',
        location = location,
      })
    end,
  })
end

return {
  config = config,
}
