#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   07/02/2025
#=================================================
result=0
label=$(razer-battery 2>/dev/null) || result=$?
color="#000"
if ((result == 2)); then
	label="-"
elif ((result == 0)) && [[ $label =~ ^(100|[1-9]?[0-9])%$ ]]; then
	level=${label%\%}
	if ((level <= 5)); then
		color="#ff0806"
	elif ((level <= 10)); then
		color="#ff7806"
	fi
else
	label=""
fi
printf '{"label_color":"#fff","label_size":60,"icon_color":"#fff","color":"%s","label":"%s"}\n' "$color" "$label"
