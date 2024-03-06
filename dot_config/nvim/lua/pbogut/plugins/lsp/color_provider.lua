local bit = require('bit')

local function lsp_color_to_hex(color)
  local function to256(c)
    return math.floor(c * color.alpha * 255)
  end
  return bit.tohex(bit.bor(bit.lshift(to256(color.red), 16), bit.lshift(to256(color.green), 8), to256(color.blue)), 6)
end

-- Determine whether to use black or white text
-- Ref: https://stackoverflow.com/a/1855903/837964
-- https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
local function color_is_bright(r, g, b)
  -- Counting the perceptive luminance - human eye favors green color
  local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
  if luminance > 0.5 then
    return true -- Bright colors, black font
  else
    return false -- Dark colors, white font
  end
end

local NAMESPACE = vim.api.nvim_create_namespace('lsp_documentColor')
local EXT_NAMESPACE = vim.api.nvim_create_namespace('lsp_documentColor_extmarks')
local HIGHLIGHT_NAME_PREFIX = 'lsp_documentColor'
local HIGHLIGHT_MODE_NAMES = { background = 'mb', foreground = 'mf', virt_text = 'mf' }

local HIGHLIGHT_CACHE = {}

--- Make a deterministic name for a highlight given these attributes
local function make_highlight_name(rgb, mode)
  return table.concat({ HIGHLIGHT_NAME_PREFIX, HIGHLIGHT_MODE_NAMES[mode], rgb }, '_')
end

local function create_highlight(rgb_hex, options)
  local mode = options.mode or 'background'
  local cache_key = table.concat({ HIGHLIGHT_MODE_NAMES[mode], rgb_hex }, '_')
  local highlight_name = HIGHLIGHT_CACHE[cache_key]

  if highlight_name then
    return highlight_name
  end

  -- Create the highlight
  highlight_name = make_highlight_name(rgb_hex, mode)
  if mode == 'foreground' or mode == 'virt_text' then
    vim.api.nvim_command(string.format('highlight %s guifg=#%s', highlight_name, rgb_hex))
  else
    local r, g, b = rgb_hex:sub(1, 2), rgb_hex:sub(3, 4), rgb_hex:sub(5, 6)
    r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
    local fg_color
    if color_is_bright(r, g, b) then
      fg_color = 'Black'
    else
      fg_color = 'White'
    end
    vim.api.nvim_command(string.format('highlight %s guifg=%s guibg=#%s', highlight_name, fg_color, rgb_hex))
  end
  HIGHLIGHT_CACHE[cache_key] = highlight_name

  return highlight_name
end

local ATTACHED_BUFFERS = {}

local function buf_set_highlights(bufnr, colors, options)
  dump('>> set_highlights')
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)

  local all_extmarks = vim.api.nvim_buf_get_extmarks(bufnr, EXT_NAMESPACE, 0, -1, {})
  local extmark_at_position = {}
  local extmark_ids = {}
  for _, extmark in pairs(all_extmarks) do
    local extmark_id = extmark[1]
    local line = extmark[2]
    local col = extmark[3]
    extmark_at_position[line .. 'x' .. col] = extmark_id
    extmark_ids[extmark_id] = true
    dump('>C> ' .. line .. 'x' .. col .. ':' .. extmark_id)
  end

  for _, color_info in pairs(colors) do
    local rgb_hex = lsp_color_to_hex(color_info.color)
    local highlight_name = create_highlight(rgb_hex, options)

    local range = color_info.range
    local line = range.start.line
    local start_col = range.start.character
    local end_col = options.single_column and start_col + 1 or range['end'].character

    if options.mode == 'virt_text' then
      local color_indicator = options.color_indicator or '■'
      local extmark_id = nil
      if extmark_at_position[line .. 'x' .. start_col] then
        extmark_id = extmark_at_position[line .. 'x' .. start_col]
        extmark_ids[extmark_id] = false
        dump('>R> ' .. line .. 'x' .. start_col .. ':' .. extmark_id)
      end
      vim.api.nvim_buf_set_extmark(0, EXT_NAMESPACE, line, start_col, {
        virt_text = { { color_indicator, highlight_name } },
        virt_text_pos = 'inline',
        id = extmark_id,
      })
    else
      vim.api.nvim_buf_add_highlight(bufnr, NAMESPACE, highlight_name, line, start_col, end_col)
    end
  end

  -- clearup
  dump('>> clear')
  for extmark_id, remove in pairs(extmark_ids) do
    dump('>D> ' .. extmark_id)
    if remove then
      vim.api.nvim_buf_del_extmark(bufnr, EXT_NAMESPACE, extmark_id)
    end
  end
end

local M = {}

local function expand_bufnr(bufnr)
  if bufnr == 0 or bufnr == nil then
    return vim.api.nvim_get_current_buf()
  else
    return bufnr
  end
end

-- first update is empty and then second has changes
-- not sure why but lets debounce it to make sure
-- we dont remove marks if there is no need to
local buf_set_highlights_debounce, timer_set = require('pbogut.utils').debounce_trailing(buf_set_highlights, 250, false)

--- Can be called to manually update the color highlighting
function M.update_highlight(bufnr, options)
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  vim.lsp.buf_request(bufnr, 'textDocument/documentColor', params, function(err, result)
    if err == nil and result ~= nil then
      -- buf_set_highlights(bufnr, result, options)
      buf_set_highlights_debounce(bufnr, result, options)
    end
  end)
end

--- Should be called `on_attach` when the LSP client attaches
function M.buf_attach(bufnr, options)
  bufnr = expand_bufnr(bufnr)
  if ATTACHED_BUFFERS[bufnr] then
    return
  end
  ATTACHED_BUFFERS[bufnr] = true

  options = options or {}

  -- VSCode extension also does 200ms debouncing
  local trigger_update_highlight, timer =
    require('pbogut.utils').debounce_trailing(M.update_highlight, options.debounce or 200, false)

  -- for the first request, the server needs some time before it's ready
  -- sometimes 200ms is not enough for this
  -- TODO: figure out when the first request can be send
  trigger_update_highlight(bufnr, options)

  -- react to changes
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      if not ATTACHED_BUFFERS[bufnr] then
        return true
      end
      trigger_update_highlight(bufnr, options)
    end,
    on_detach = function()
      timer:close()
      timer_set:close()
      ATTACHED_BUFFERS[bufnr] = nil
    end,
  })
end

--- Can be used to detach from the buffer at any time
function M.buf_detach(bufnr)
  bufnr = expand_bufnr(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
  ATTACHED_BUFFERS[bufnr] = nil
end

return M
