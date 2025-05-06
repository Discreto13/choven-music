#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory> [--silent] [--count] [--help]"
    exit 1
fi

DIR="$1"
SILENT=false
COUNT=false

# Обробка аргументів
for arg in "$@"; do
    case $arg in
        --silent)
            SILENT=true
            ;;
        --count)
            COUNT=true
            ;;
        --help)
            echo "Usage: $0 <directory> [--silent] [--count] [--help]"
            echo ""
            echo "--silent   : Only return list of authors without any header text"
            echo "--count    : Show number of tracks for each author"
            echo "--help     : Show this help message"
            exit 0
            ;;
    esac
done

if ! command -v ffmpeg &> /dev/null; then
    echo "❌ ffmpeg not found, please install it first."
    exit 1
fi

tmp_file=$(mktemp)

find "$DIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.m4a" \) | while read -r file; do
    artist=$(ffmpeg -i "$file" 2>&1 | grep -i "artist" | head -1 | sed 's/.*: //')
    if [ -n "$artist" ]; then
        echo "$artist" >> "$tmp_file"
    fi
done

if [ "$COUNT" = true ]; then
    authors=$(sort "$tmp_file" | uniq -c | sort -nr)
else
    authors=$(sort "$tmp_file" | uniq)
fi

rm "$tmp_file"

if [ "$SILENT" = false ]; then
    if [ "$COUNT" = true ]; then
        echo "📊 Authors and track counts:"
    else
        echo "📜 Unique authors:"
    fi
fi

echo "$authors"
