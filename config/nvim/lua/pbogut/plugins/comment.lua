---@type LazyPluginSpec
return {
  'numtostr/comment.nvim',
  dependencies = { 'joosepalviste/nvim-ts-context-commentstring' },
  keys = {
    { '<c-_>', 'gcc<down>', remap = true },
    { '<c-/>', 'gcc<down>', remap = true },
    { '<c-_>', 'gc<down>', mode = 'v', remap = true },
    { '<c-/>', 'gc<down>', mode = 'v', remap = true },
  },
  opts = {
    comment_strings = {
      asm = '//%s',
      heex = { '<%# %s #%>', '<%# %s #%>' },
      devicetree = { '// %s', '/* %s */' },
      swayconfig = '# %s',
      openscad = '// %s',
      kdl = '// %s',
      query = '; %s',
    },
  },
  config = function(_, opts)
    require('Comment').setup({
      ignore = '^$',
      pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
    })

    local ft = require('Comment.ft')
    for file_type, comment_string in pairs(opts.comment_strings) do
      ft[file_type] = comment_string
    end
  end,
}
