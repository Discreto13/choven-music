#!/bin/sh

# Load .env variables
if [ -f ".env" ]; then
    . ./.env
else
    echo "❌ .env file not found!"
    exit 1
fi

# Set tg commands
curl -X POST "https://api.telegram.org/bot$BOT_TOKEN/setMyCommands" \
-H "Content-Type: application/json" \
-d '{
  "commands": [
    {"command": "authors", "description": "<1 endpoint> to show full list of author in library"},
    {"command": "new_author", "description": "[2 endpoint] specify it first to add track of new author"},
    {"command": "youtube_url", "description": "<2 endpoint> youtube url to download"},
    {"command": "track_name", "description": "<2 endpoint> name for the track '\''author - track name'\''"}
  ]
}' &>/dev/null

LAST_UPDATE_FILE="last_update_id.txt"

if [ ! -f "$LAST_UPDATE_FILE" ]; then
    echo 0 > "$LAST_UPDATE_FILE"
fi

get_updates() {
    offset=$(cat "$LAST_UPDATE_FILE")
    curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$offset"
}

send_message() {
    TEXT="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" --data-urlencode "text=$TEXT" >/dev/null
    echo $TEXT
}

split_and_send() {
    CHUNK=""
    COUNT=0
    MAX_LINES=30

    echo "$1" | while read line; do
        [ -z "$line" ] && continue
        CHUNK="$CHUNK$line
"
        COUNT=$((COUNT + 1))

        if [ $COUNT -ge $MAX_LINES ]; then
            [ -n "$CHUNK" ] && send_message "$CHUNK"
            CHUNK=""
            COUNT=0
            sleep 1
        fi
    done

    if [ -n "$CHUNK" ]; then
        send_message "$CHUNK"
    fi
}

# state variables (persist only inside loop)
YOUTUBE_URL=""
TRACK_NAME=""
NEW_AUTHOR=false

echo "Tg bot started"
while true; do
    UPDATES=$(get_updates)

    # Process update_id
    echo "$UPDATES" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | while read update_id; do
        next_offset=$((update_id + 1))
        echo "$next_offset" > "$LAST_UPDATE_FILE"
    done

    # Process message text
    echo "$UPDATES" | jq -r '.result[].message.text' > /tmp/tg_updates.txt
    while read message_text; do
        echo "Received: $message_text"

        # process as multiline message as tg provides updates exactly that way
        if [ "$message_text" = "/authors" ]; then
            send_message "Collecting data..."
            AUTHORS=$(../picoreplayer/scan_authors.sh $MUSIC_DIR --silent 2>/dev/null)
            split_and_send "$AUTHORS"
            send_message "-- end ---"
        elif [ "$message_text" = "/new_author" ]; then
            NEW_AUTHOR=true
            send_message "✅ New author flag set."
        elif echo "$message_text" | grep -q "^/youtube_url "; then
            YOUTUBE_URL=$(echo "$message_text" | sed 's|^/youtube_url ||')
            send_message "✅ YouTube URL saved."
        elif echo "$message_text" | grep -q "^/track_name "; then
            TRACK_NAME=$(echo "$message_text" | sed 's|^/track_name ||')
            send_message "✅ Track name saved."
        fi

        # ✅ Check if both args for track adding are collected
        if [ -n "$YOUTUBE_URL" ] && [ -n "$TRACK_NAME" ]; then
            send_message "🎵 Adding track..."
            CMD="../picoreplayer/add_track.sh -y \"$YOUTUBE_URL\" -n \"$TRACK_NAME\" -d \"$MUSIC_DIR\""
            if [ "$NEW_AUTHOR" = true ]; then
                CMD="$CMD --new-author"
            fi

            echo "Executing: $CMD"
            OUTPUT=$(eval "$CMD" 2>&1)
            send_message "$OUTPUT"

            # Reset state
            YOUTUBE_URL=""
            TRACK_NAME=""
            NEW_AUTHOR=false
        elif [ -n "$YOUTUBE_URL" ] || [ -n "$TRACK_NAME" ] || [ "$NEW_AUTHOR" = true ]; then
            STATUS_MSG="ℹ️  Current add_track command status:
"
            if [ -n "$YOUTUBE_URL" ]; then
                STATUS_MSG="$STATUS_MSG ✅ /youtube_url: $YOUTUBE_URL
"
            else
                STATUS_MSG="$STATUS_MSG ❌ /youtube_url: not set
"
            fi

            if [ -n "$TRACK_NAME" ]; then
                STATUS_MSG="$STATUS_MSG ✅ /track_name: $TRACK_NAME
"
            else
                STATUS_MSG="$STATUS_MSG ❌ /track_name: not set
"
            fi

            if [ "$NEW_AUTHOR" = true ]; then
                STATUS_MSG="$STATUS_MSG ✅ /new_author: true
"
            else
                STATUS_MSG="$STATUS_MSG 📝 /new_author: false
"
            fi

            send_message "$STATUS_MSG"
        fi
    done < /tmp/tg_updates.txt

    sleep 3
done
