TRACK=$(playerctl metadata title)
STATUS=$(playerctl status)

CLASS=$( [[ "$STATUS" == "Playing" ]] && echo "playing" || echo "stopped" )
PERCENTAGE=$( [[ "$STATUS" == "Playing" ]] && echo "100" || echo "0" )

echo "{\"text\": \"$TRACK\", \"class\": \"$CLASS\", \"percentage\": $PERCENTAGE }"