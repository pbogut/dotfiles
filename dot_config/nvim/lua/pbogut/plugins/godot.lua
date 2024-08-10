---@type LazyPluginSpec
return {
  enabled = true,
  'lommix/godot.nvim',
  cmd = {
    'GodotDebug',
    'GodotBreakAtCursor',
    'GodotStep',
    'GodotQuit',
    'GodotContinue',
  },
  config = true,
}
