#!/bin/sh

# Завантажуємо змінні з .env
if [ -f ".env" ]; then
    . ./.env
else
    echo "❌ .env file not found!"
    exit 1
fi

LAST_UPDATE_FILE="last_update_id.txt"

# Ініціалізація offset
if [ ! -f "$LAST_UPDATE_FILE" ]; then
    echo 0 > "$LAST_UPDATE_FILE"
fi

get_updates() {
    offset=$(cat "$LAST_UPDATE_FILE")
    curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$offset"
}

send_message() {
    TEXT="$1"
    TEXT_ESC=$(echo "$TEXT" | sed 's/ /%20/g')
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" -d "text=$TEXT_ESC"
}

split_and_send() {
    CHUNK=""
    COUNT=0
    MAX_LINES=30  # приблизно 30 рядків, щоб не перевищувати ліміт

    echo "$1" | while read line; do
        CHUNK="$CHUNK$line\n"
        COUNT=$((COUNT + 1))

        if [ $COUNT -ge $MAX_LINES ]; then
            send_message "$CHUNK"
            CHUNK=""
            COUNT=0
            sleep 1
        fi
    done

    # Надіслати залишки
    if [ -n "$CHUNK" ]; then
        send_message "$CHUNK"
    fi
}

while true; do
    UPDATES=$(get_updates)

    # Парсимо update_id
    echo "$UPDATES" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | while read update_id; do
        next_offset=$((update_id + 1))
        echo "$next_offset" > "$LAST_UPDATE_FILE"
    done

    # Парсимо текст повідомлення
    echo "$UPDATES" | grep -o '"text":"[^"]*' | cut -d':' -f2- | cut -d'"' -f2 | while read message_text; do
        if [ "$message_text" = "/authors" ]; then
            AUTHORS=$(../picoreplayer/scan_authors.sh $MUSIC_DIR --silent 2>/dev/null)
            split_and_send "$AUTHORS"
        else
            send_message "❓ Unknown command"
        fi
    done

    sleep 3
done
