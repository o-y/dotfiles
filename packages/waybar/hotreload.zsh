DIRECTORY_TO_WATCH="$HOME/dotfiles/packages/waybar"

while true; do
  EVENT=$(inotifywait -e modify -r $DIRECTORY_TO_WATCH)
  
  pkill waybar
  waybar &
done