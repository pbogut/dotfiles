---@type LazyPluginSpec
return {
  enabled = true,
  'gpanders/nvim-parinfer',
  ft = {
    'clojure',
    'scheme',
    'lisp',
    'racket',
    'hy',
    'fennel',
    'janet',
    'carp',
    'wast',
    'yuck',
    'dune',
  },
  cmd = {
    'ParinferOn',
    'ParinferOff',
    'ParinferToggle',
    'ParinferLog',
  },
}
