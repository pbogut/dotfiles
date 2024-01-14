---@type LazyPluginSpec
return {
  'wansmer/treesj',
  keys = {
    { 'gS', '<cmd>TSJSplit<cr>', silent = true },
    { 'gJ', '<cmd>TSJJoin<cr>', silent = true },
  },
  opts = {
    use_default_keymaps = false,
    check_syntax_error = false,
    max_join_length = 120,
    cursor_behavior = 'hold',
    notify = true,
    langs = {
      php = {
        arguments = {
          both = {
            last_separator = false,
          },
        },
      },
      elixir = {
        arguments = {
          both = {
            separator = ',',
            last_separator = false,
          },
        },
        tuple = {
          both = {
            separator = ',',
            last_separator = false,
          },
        },
        keywords = {
          both = {
            separator = ',',
            last_separator = false,
            non_bracket_node = true,
            recursive = false,
          },
        },
        map_content = {
          both = {
            separator = ',',
            last_separator = false,
            non_bracket_node = true,
          },
        },
      },
    },
    dot_repeat = true,
  },
  cmd = { 'TSJSplit', 'TSJJoin' },
}
