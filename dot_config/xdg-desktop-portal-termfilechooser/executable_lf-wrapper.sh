#!/usr/bin/env bash

# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
#
# Inputs:
# 1. "1" if multiple files can be chosen, "0" otherwise.
# 2. "1" if a directory should be chosen, "0" otherwise.
# 3. "0" if opening files was requested, "1" if writing to a file was
#    requested. For example, when uploading files in Firefox, this will be "0".
#    When saving a web page in Firefox, this will be "1".
# 4. If writing to a file, this is recommended path provided by the caller. For
#    example, when saving a web page in Firefox, this will be the recommended
#    path Firefox provided, such as "~/Downloads/webpage_title.html".
#    Note that if the path already exists, we keep appending "_" to it until we
#    get a path that does not exist.
# 5. The output path, to which results should be written.
#
# Output:
# The script should print the selected paths to the output path (argument #5),
# one path per line.
# If nothing is printed, then the operation is assumed to have been canceled.

multiple="$1"
directory="$2"
save="$3"
path="$4"
path=$(realpath "$path")
out="$5"
cmd="/usr/bin/lf"
if [ "$save" = "1" ]; then
	TITLE="Save File:"
elif [ "$directory" = "1" ]; then
	TITLE="Select Directory:"
else
	TITLE="Select File:"
fi

quote_string() {
	local input="$1"
	echo "'${input//\'/\'\\\'\'}'"
}

TERMCMD="$HOME/.scripts/terminal-float -t $(quote_string "$TITLE") -e"
termcmd="${TERMCMD:-/usr/bin/kitty --title $(quote_string "$TITLE")}"

cleanup() {
	if [ -f "$tmpfile" ]; then
		/usr/bin/rm "$tmpfile" || :
	fi
	if [ "$save" = "1" ] && [ ! -s "$out" ]; then
		/usr/bin/rm "$path" || : || n
	fi
}

trap cleanup EXIT HUP INT QUIT ABRT TERM

if [ "$save" = "1" ]; then
	tmpfile=$(/usr/bin/mktemp)
	/usr/bin/printf '%s' 'xdg-desktop-portal-termfilechooser saving files tutorial

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!                 === WARNING! ===                 !!!
!!! The contents of *whatever* file you open last in !!!
!!! ranger will be *overwritten*!                    !!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Instructions:
1) Move this file wherever you want.
2) Rename the file if needed.
3) Confirm your selection by opening the file, for
   example by pressing <Enter>.
Notes:
1) This file is provided for your convenience. You can
	 only choose this placeholder file otherwise the save operation aborted.
2) If you quit ranger without opening a file, this file
   will be removed and the save operation aborted.
' >"$path"
	set -- -selection-path "$(quote_string "$tmpfile")" "$(quote_string "$path")"
	echo set -- -selection-path "$(quote_string "$tmpfile")" "$(quote_string "$path")" >> /tmp/lf
elif [ "$directory" = "1" ]; then
	set -- -last-dir-path "$(quote_string "$out")" "$(quote_string "$path")"
elif [ "$multiple" = "1" ]; then
	set -- -selection-path "$(quote_string "$out")" "$(quote_string "$path")"
else
	set -- -selection-path "$(quote_string "$out")" "$(quote_string "$path")"
fi

echo "$termcmd -- $cmd $@" >> /tmp/lf
eval "$termcmd -- $cmd $@"
printf "\n" >> "$out"

# case save file
if [ "$save" = "1" ] && [ -s "$tmpfile" ]; then
	selected_file=$(/usr/bin/head -n 1 "$tmpfile")
	# Check if selected file is placeholder file
	if [ -f "$selected_file" ] && /usr/bin/grep -qi "^xdg-desktop-portal-termfilechooser saving files tutorial" "$selected_file"; then
		/usr/bin/echo "$selected_file" >"$out"
		path="$selected_file"
	fi
fi
