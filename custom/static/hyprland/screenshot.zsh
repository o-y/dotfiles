# Capture a screenshot and saves it to the clipboard and the filesystem

image_specifier=$(date +"%d-%m-%y_%T")
screenshot_path="$HOME/Pictures/Screenshots/$image_specifier.png"

grimblast copysave area $screenshot_path

open "$screenshot_path"

# Notification
dunstify \
  -a "Open Screenshot" \
  -i "$screenshot_path" \
  "$image_specifier.png" \
  "Click to open in Chrome"