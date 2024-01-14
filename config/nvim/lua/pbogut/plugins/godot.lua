---@type LazyPluginSpec
return {
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
