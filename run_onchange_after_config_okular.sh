#!/usr/bin/env bash
#=================================================
# name:   run_onchange_after_config_okular
# author: author <author_contact>
# date:   06/04/2024
#=================================================
config="$HOME/.config/okularpartrc"

# set up dark theme colors
echo "
[Dlg Accessibility]
RecolorBackground=0,43,54
RecolorForeground=238,238,238
" >> "$config"
