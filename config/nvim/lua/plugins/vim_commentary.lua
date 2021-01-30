local fn = vim.fn
local bo = vim.bo
local b = vim.b
local cmd = vim.cmd
local u = require'utils'

u.map('n', '<c-_>', ":lua require'plugins.vim_commentary'.comment_line()<cr>j")
u.map('n', '<c-/>', ":lua require'plugins.vim_commentary'.comment_line()<cr>j")
u.map('v', '<c-_>', ":lua require'plugins.vim_commentary'.comment_block()<cr>j")
u.map('v', '<c-/>', ":lua require'plugins.vim_commentary'.comment_block()<cr>j")

u.augroup('x_commentary', {
  FileType = {
    { 'sql', function()
        b.commentary_format = '-- %s'
      end
    },
    { 'blade', function()
        b.commentary_format = '{{-- %s --}}'
      end
    },
    { 'crontab,nginx,resolv', function()
        b.commentary_format = '# %s'
      end
    },
  }
})

local p = {
    php_in_html = {
        comment_format = '// %s',
        starts = '<?php',
        ends = '?>',
        skip = '',
    },
    js_in_html = {
        comment_format = '// %s',
        starts = '<script[^>]*>',
        ends = '</script>',
        skip = function()
            if string.match(fn.getline('.'), '//.*</?script')
                or string.match(fn.getline('.'), '<!--.*</?script')
                or string.match(fn.getline('.'), '/%*.*</?script')
            then
                return true
            end
        end,
    },
    css_in_html = {
        comment_format = '/* %s */',
        starts = '<style[^>]*>',
        ends = '</style>',
        skip = function()
            if string.match(fn.getline('.'), '//.*</?style')
                or string.match(fn.getline('.'), '<!--.*</?style')
                or string.match(fn.getline('.'), '/%*.*</?style')
            then
                return true
            end
        end,
    },
}

local regions = {
    php = {
        -- php files are in fact html with embeded php so here we are
        default = '<?php // %s ?>',
        js = p.js_in_html,
        css = p.css_in_html,
        php = p.php_in_html,
    },
    vue = {
        default = '<!-- %s -->',
        js = p.js_in_html,
        css = p.css_in_html,
    }
}

-- commenting logic start here --

local f = {}

local function get_file_config()
    local ftype = bo.ft
    for pattern, config in pairs(regions) do
        if ftype == pattern then
            return config
        end
    end

    return {}
end

local function get_current_region_config()
    -- local search_flags = 'nbWz' -- [z] requires inner comments implementation
    local search_flags = 'nbW' -- requires inner comments
    local config = get_file_config()
    local max_pos = { 0, 0}
    local result = config.default

    for x, c in pairs(config) do
        if x ~= "default" then
            local pos = fn.searchpairpos(c.starts, '', c.ends, search_flags, c.skip)
            if (pos[1] > max_pos[1])
                or (pos[1] == max_pos[1] and pos[2] > max_pos[2])
            then
                max_pos = pos
                result = c.comment_format
            end
        end
    end

    return result
end

local function comment(callback)
    local comment_format = get_current_region_config()
    local current_format = b.commentary_format

    if comment_format then
        b.commentary_format = comment_format
    end
    callback()
    -- restore whatever was set before
    if current_format ~= b.commentary_format then
        b.commentary_format = current_format
    end
end

function f.comment_line()
    comment(function() cmd('normal gcc') end)
end

-- @todo implement better block handling so its possible
-- to comment starting in one block and ending in another
-- Possibly replace vim-commentator entirely
function f.comment_block()
    comment(function() cmd('normal gvgc') end)
end

return f
