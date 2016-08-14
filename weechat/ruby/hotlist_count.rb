# hotlist_count
SCRIPT_NAME = 'hotlist_count'
SCRIPT_AUTHOR = 'Pawel Bogut <pawel.bogut@gmail.com>'
SCRIPT_DESC = 'Saves hotlist count to file'
SCRIPT_VERSION = '0.0.1'
SCRIPT_LICENSE = 'MIT'

COUNT_FILE = '/tmp/weechat_count.info'

LOWEST_PRIORITY = 2 # private message is 2, highlight is 3

def weechat_init
  Weechat.register SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE, SCRIPT_DESC, "", ""
  Weechat.hook_signal("hotlist_changed", "hotlist_changed", "")
  hotlist_changed() #init hotlist count
  return Weechat::WEECHAT_RC_OK
end

def hotlist_changed(_ = nil, _ = nil, _ = nil)
  hotlist = Weechat.infolist_get("hotlist","","");
  count = 0
  while Weechat.infolist_next(hotlist) != 0
    name = Weechat.infolist_string(hotlist,'buffer_name')
    priority = Weechat.infolist_integer(hotlist, 'priority')
    if priority >= LOWEST_PRIORITY
      count += 1
    end
  end

  begin
    file = File.open(COUNT_FILE, "w")
    file.write("#{count}\n")
  rescue IOError => e
    #some error occur, dir not writable etc.
  ensure
    file.close unless file.nil?
  end
end
