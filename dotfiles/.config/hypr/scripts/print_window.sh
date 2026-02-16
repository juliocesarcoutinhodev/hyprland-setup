#!/bin/bash
active_ws=$(hyprctl activeworkspace -j | jq ".id")
geom=$(hyprctl clients -j | jq -r --argjson ws "$active_ws" ".[] | select(.workspace.id == \$ws) | \"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])\"" | slurp)
if [ -z "$geom" ]; then exit 0; fi

# Repare que removi o --fullscreen da linha abaixo
grim -g "$geom" - | satty --filename - --output-filename ~/Imagens/Screenshots/satty-$(date "+%Y%m%d-%H:%M:%S").png
