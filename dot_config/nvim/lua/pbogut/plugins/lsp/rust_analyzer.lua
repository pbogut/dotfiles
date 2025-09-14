local opts = {
  cmd = { 'rust-analyzer' },
}
lspconfig.rust_analyzer.setup = function(_) end

return opts
