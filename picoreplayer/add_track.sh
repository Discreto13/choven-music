#!/bin/sh

set -e

show_help() {
    echo "Usage: $0 -n \"author - song.mp3\" -y <youtube_url> -d <destination_dir> [--new-author]"
    echo ""
    echo "Parameters:"
    echo "  -n     Song name in format \"Author - Song.mp3\""
    echo "  -y     YouTube URL to download audio"
    echo "  -d     Target directory where to put the final file"
    echo "  --new-author   Skip author existence check"
    echo "  --help         Show this help message"
}

NEW_AUTHOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n)
            NAME="$2"
            shift 2
            ;;
        -y)
            YOUTUBE_URL="$2"
            shift 2
            ;;
        -d)
            DEST_DIR="$2"
            shift 2
            ;;
        --new-author)
            NEW_AUTHOR=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown parameter: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ -z "$NAME" || -z "$YOUTUBE_URL" || -z "$DEST_DIR" ]]; then
    echo "❌ Parameters -n, -y, and -d are required."
    show_help
    exit 1
fi

if [[ "$NAME" != *" - "*".mp3" ]]; then
    echo "❌ Name must be in format 'Author - Song.mp3'"
    exit 1
fi

AUTHOR=$(echo "$NAME" | awk -F ' - ' '{print $1}')
TITLE=$(echo "$NAME" | awk -F ' - ' '{print $2}' | sed 's/\.mp3$//')

if [[ "$NEW_AUTHOR" = false ]]; then
    AUTHORS=$(./scan_authors.sh "$DEST_DIR" --silent)
    if ! echo "$AUTHORS" | grep -Fxq "$AUTHOR"; then
        echo "❌ Author '$AUTHOR' not found in library."
        exit 1
    fi
fi

if [[ -f "$DEST_DIR/$NAME" ]]; then
    echo "❌ Song '$NAME' already exists in destination directory."
    exit 1
fi

TMP_DIR="./tmp"
mkdir -p "$TMP_DIR"
TMP_FILE="$TMP_DIR/$NAME"

echo "🎵 Calling download_youtube.sh..."
if ! ./download_youtube.sh -y "$YOUTUBE_URL" -o "$TMP_DIR/${NAME%.mp3}"; then
    echo "❌ Failed to download from YouTube."
    rm -f "$TMP_FILE"
    exit 1
fi

if ! ./update_mp3_tags.sh "$TMP_FILE"; then
    echo "❌ Failed to update mp3 tags."
    rm -f "$TMP_FILE"
    exit 1
fi

if ! mv "$TMP_FILE" "$DEST_DIR/"; then
    echo "❌ Failed to move file to destination."
    exit 1
fi

echo "✅ Successfully added '$NAME' to '$DEST_DIR'"
