# opens rofi
# usage: zsh rofi <scope>
# acceptable scopes: global, desktop-apps

scope="$1"

if [[ "$scope" = "global" ]]; then
    rofi -show combi -theme ~/.config/rofi/launchers/type-1/style-8.rasi -icon-theme "Papirus"
elif [[ "$scope" = "desktop-apps" ]]; then
    rofi -show drun -theme ~/.config/rofi/launchers/type-3/style-1.rasi -icon-theme "Papirus"
elif [[ "$scope" = "kill" ]]; then
    killall rofi
elif [[ "$scope" = "clipboard" ]]; then
    rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}' -theme ~/.config/rofi/launchers/type-1/style-7.rasi
fi