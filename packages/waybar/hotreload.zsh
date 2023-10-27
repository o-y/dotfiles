DIRECTORY_TO_WATCH="$HOME/dotfiles/packages/waybar/"

stylus ./
pkill waybar
waybar &

while true; do
  inotifywait -e modify -r $DIRECTORY_TO_WATCH
  
  stylus ./
  pkill waybar
  waybar  &
done

