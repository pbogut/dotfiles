#!/usr/bin/env bash
#=================================================
# name:   run_once_after_xdg-setup
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
echo -en "> Set browser script as default browser (xdg-settings) ... "
xdg-settings set default-web-browser browser.desktop
echo "done"

echo -en "> Set email script as default emial (xdg-settings) ... "
xdg-settings set default-url-scheme-handler mailto email.desktop
echo "done"

echo -en "> Set email script as default mailto handler (xdg-mime) ... "
xdg-mime default email.desktop 'x-scheme-handler/mailto'
echo "done"

echo -en "> Set lf as default manager (xdg-mime) ... "
xdg-mime default lf.desktop 'inode/directory'
echo "done"

echo -en "> $(
    if [[ -n "$(command -v gio)" ]]; then
        gio mime inode/directory lf.desktop
    elif [[ -n $(command -v gvfs-mime) ]]; then
        gvfs-mime --set inode/directory lf.desktop
    fi
)" && echo " ... done"
