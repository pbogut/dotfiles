#!/usr/bin/env python3
#
# Copyright (C) 2016 James Murphy
# Licensed under the GPL version 2 only
#
# A battery indicator blocklet script for i3blocks

from subprocess import check_output

status = check_output(['acpi'], universal_newlines=True)

if not status:
    # stands for no battery found
    # fulltext = "<span color='red'><span font='FontAwesome'>\uf00d \uf240</span></span>"
    # percentleft = 100
    # if no battery then its probably PC
    pass
else:
    state = status.split(": ")[1].split(", ")[0]
    commasplitstatus = status.split(", ")
    percentleft = int(commasplitstatus[1].rstrip("%\n"))

    # stands for charging
    FA_LIGHTNING = "<span font='FontAwesome'>\uf0e7</span>"

    # stands for plugged in
    FA_PLUG = "<span font='FontAwesome'>\uf1e6</span>"

    fulltext = ""
    timeleft = ""


    def color(percent):
        if percent < 10:
            # exit code 33 will turn background red
            return "#FFFFFF"
        if percent < 20:
            return "#FF3300"
        if percent < 30:
            return "#FF6600"
        if percent < 40:
            return "#FF9900"
        if percent < 50:
            return "#FFCC00"
        if percent < 60:
            return "#FFFF00"
        if percent < 70:
            return "#FFFF33"
        if percent < 80:
            return "#FFFF66"
        return "#FFFFFF"

    def icon(percent):
        if percent < 20:
            return "<span font='FontAwesome'>\uf244</span> "
        if percent < 45:
            return "<span font='FontAwesome'>\uf243</span> "
        if percent < 70:
            return "<span font='FontAwesome'>\uf242</span> "
        if percent < 95:
            return "<span font='FontAwesome'>\uf241</span> "
        return "<span font='FontAwesome'>\uf240</span> "

    if state == "Discharging":
        time = commasplitstatus[-1].split()[0]
        time = ":".join(time.split(":")[0:2])
        timeleft = " ({})".format(time)
        fulltext = "{} ".format(icon(percentleft))
    elif state == "Full":
        fulltext = FA_PLUG + " "
    elif state == "Unknown":
        fulltext = "<span font='FontAwesome'>\uf128</span> "
    else:
        fulltext = FA_LIGHTNING + " " + FA_PLUG + " "

    form =  '<span color="{}">{}%</span>'
    fulltext += form.format(color(percentleft), percentleft)
    fulltext += timeleft

print(fulltext)

# return with imortant code
if percentleft < 10:
    exit(33)
