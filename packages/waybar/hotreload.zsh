DIRECTORY_TO_WATCH="$HOME/dotfiles/packages/waybar/"

waybar &

while true; do
  inotifywait -e modify -r $DIRECTORY_TO_WATCH
  
  pkill waybar
  waybar &
done