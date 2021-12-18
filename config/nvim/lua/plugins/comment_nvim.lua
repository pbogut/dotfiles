local u = require('utils')

local function config()
  u.map('n', '<c-_>', 'gcc<down>', { noremap = false })
  u.map('n', '<c-/>', 'gcc<down>', { noremap = false })
  u.map('v', '<c-_>', 'gc<down>', { noremap = false })
  u.map('v', '<c-/>', 'gc<down>', { noremap = false })

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
