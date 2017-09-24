c.url.start_pages = ["https://google.com"]
c.downloads.open_dispatcher = "sh -c '~/.scripts/i3-open \"{}\"'"
c.editor.command = ["nvim-qt", "--nofork", "--geometry", "900x55", "--", "-f", "{}"]
c.content.developer_extras = True
c.downloads.position = "bottom"
c.confirm_quit = ["multiple-tabs", "downloads"]
c.scrolling.bar = True
c.scrolling.smooth = True
c.prompt.radius = 5
c.tabs.background = True
c.tabs.last_close = "close"
c.tabs.show = "multiple"
c.tabs.position = "right"
c.tabs.width.bar= 200
c.tabs.padding = {"top": 2, "bottom": 2, "left": 5, "right": 5}
c.downloads.location.directory = "~/Downloads"
c.content.plugins = True
c.content.host_blocking.whitelist = ["piwik.org", "analytics.google.com", "apis.google.com"]
c.content.pdfjs = True
c.hints.border = "1px solid #E3BE23"
c.hints.chars = "arstdhneifuwy"
# c.hints.find_implementation = "javascript"
c.url.searchengines = {
    "DEFAULT": "https://google.com/search?q={}",
    "g": "https://google.com/search?q={}",
    "aw": "https://wiki.archlinux.org/?search={}",
    "al": "https://allegro.pl/listing?string={}",
}
# c.colors.completion.even.bg = "#333333"
c.colors.completion.odd.bg = "#1f1f1f"
c.colors.completion.even.bg = "#1f1f1f"
c.colors.completion.category.bg = "#285577"
c.colors.completion.item.selected.fg = "white"
c.colors.completion.item.selected.bg = c.colors.completion.category.bg
c.colors.completion.item.selected.border.top = 'black'
c.colors.completion.item.selected.border.bottom = 'black'
c.colors.completion.scrollbar.fg = c.colors.completion.item.selected.bg
c.colors.statusbar.insert.bg = "#b58900"
c.colors.statusbar.caret.bg = "#d33682"
c.colors.statusbar.url.success.https.fg = "white"
c.colors.tabs.odd.bg = c.colors.completion.odd.bg
# c.colors.tabs.even.bg = c.colors.completion.even.bg
c.colors.tabs.even.bg = c.colors.completion.odd.bg
c.colors.tabs.selected.odd.bg = c.colors.completion.category.bg
c.colors.tabs.selected.even.bg = c.colors.completion.category.bg
c.colors.tabs.bar.bg = "#1c1c1c"
c.colors.messages.error.bg = "#dc322f"
c.colors.prompts.bg = c.colors.tabs.bar.bg
c.fonts.monospace = '"Sauce Code Pro Nerd Fonts", Terminus, Monospace, "DejaVu Sans Mono", Monaco, "Bitstream Vera Sans Mono", "Andale Mono", "Courier New", Courier, "Liberation Mono", monospace, Fixed, Consolas, Terminal'
c.fonts.hints = "12pt monospace"
c.fonts.prompts = "10pt sans-serif"

config.unbind('d', mode='normal')
config.unbind('D', mode='normal')
config.unbind('T', mode='normal')
config.unbind('<back>', mode='normal')
config.bind('gO', 'open -t {url:pretty}', force=True)
config.bind('xO', 'open -b {url:pretty}', force=True)
config.bind('<Ctrl-q>', 'tab-close', force=True)
config.bind('<Ctrl-n>', 'tab-next', force=True)
config.bind('<Ctrl-p>', 'tab-prev', force=True)

config.bind('<Ctrl-i>', 'open-editor', mode='insert')
config.bind('<ctrl-j>', 'spawn --userscript ~/.scripts/qb-lastpass.rb --add', mode='insert')
config.bind('<ctrl-l>', 'spawn --userscript ~/.scripts/qb-lastpass.rb --type-user-and-pass', mode='insert')
config.bind('<ctrl-u>', 'spawn --userscript ~/.scripts/qb-lastpass.rb --type-user', mode='insert')
config.bind('<ctrl-y>', 'spawn --userscript ~/.scripts/qb-lastpass.rb --type-pass', mode='insert')
config.bind('<ctrl-n>', 'fake-key <down>', mode='insert')
config.bind('<ctrl-p>', 'fake-key <up>', mode='insert')
config.bind('<ctrl-w>', 'fake-key <shift-ctrl-left> ;; fake-key <backspace>', mode='insert')


config.bind('<Ctrl-n>', 'completion-item-focus next', force=True, mode='command')
config.bind('<Ctrl-p>', 'completion-item-focus prev', force=True, mode='command')
config.bind('<Ctrl-w>', 'fake-key -g <shift-ctrl-left> ;; fake-key -g <backspace>', force=True, mode='command')

config.bind('<Alt-n>', 'command-history-next', force=True, mode='command')
config.bind('<Alt-j>', 'command-history-next', force=True, mode='command')
config.bind('<Alt-p>', 'command-history-prev', force=True, mode='command')
config.bind('<Alt-k>', 'command-history-prev', force=True, mode='command')

config.bind('K', 'tab-move -', force=True)
config.bind('J', 'tab-move +', force=True)

config.bind('yh', 'spawn --userscript ~/.scripts/qb-copy-html.sh -b')
config.bind('ys', 'spawn --userscript ~/.scripts/qb-copy-text.sh -b')
config.bind('yH', 'spawn --userscript ~/.scripts/qb-copy-html.sh -p')
config.bind('yS', 'spawn --userscript ~/.scripts/qb-copy-text.sh -p')
config.bind('eu', 'edit-url')
