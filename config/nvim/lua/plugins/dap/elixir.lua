local u = require("utils")
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
  u.buf_map(0, 'n', '<space>dt', debug_test)
end

return {
  setup = setup,
  debug_test = debug_test
}
