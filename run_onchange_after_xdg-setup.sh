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

echo -en "> Set yazi as default manager (xdg-mime) ... "
xdg-mime default yazi.desktop 'inode/directory'
echo "done"

xdg-mime default feh.desktop 'image/svg+xml'
xdg-mime default feh.desktop 'image/*'

echo -en "> $(
    if [[ -n "$(command -v gio)" ]]; then
        gio mime inode/directory lf.desktop
        gio mime model/stl OrcaSlicer.desktop
        gio mime application/vnd.ms-3mfdocument OrcaSlicer.desktop
    elif [[ -n $(command -v gvfs-mime) ]]; then
        gvfs-mime --set inode/directory lf.desktop
        gvfs-mime --set model/stl OrcaSlicer.desktop
        gvfs-mime --set application/vnd.ms-3mfdocument OrcaSlicer.desktop
    fi
)" && echo " ... done"
