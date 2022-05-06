local u = require("utils")
local k = vim.keymap
local dap = require("dap")
local defaults = {}

local function debug_test()
  local line = vim.fn.line('.')
  local file = vim.fn.expand('%')
  local test_pos = file .. ":" .. line

  dap.run(vim.tbl_extend('keep', {
    name = "test near",
    taskArgs = {"--trace", test_pos},
    startApps = true,
    requireFiles = {
      "test/**/test_helper.exs",
      file
    }
  }, defaults))
end

local function setup(opts)
  defaults = opts.defaults
  k.set('n', '<space>dt', debug_test, { buffer = true })
end

return {
  setup = setup,
  debug_test = debug_test
}
