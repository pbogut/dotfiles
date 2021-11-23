-- naive way of loading subtitles
-- works for minidlna and causes no errors for enythig else,
-- but maybe message in some cases in mpv console, good enough for me

function on_path_change(name, value)
  if value and value:match('/MediaItems/') then
    local srt = value:gsub('MediaItems', 'Captions')
    mp.commandv('sub-add', srt, 'select')
  end
end

mp.observe_property("path", "string", on_path_change)
