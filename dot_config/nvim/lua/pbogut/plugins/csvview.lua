---@type LazyPluginSpec
return {
  enabled = true,
  'hat0uma/csvview.nvim',
  ---@module "csvview"
  ---@type CsvView.Options
  opts = {},
  ft = { 'csv', 'tsv' },
  cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
}
