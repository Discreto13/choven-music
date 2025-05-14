#!/bin/sh

# Get required arguments
while getopts p:d: flag; do
    case "${flag}" in
        p) PLAYLIST_URL=${OPTARG};;
        d) MUSIC_DIR=${OPTARG};;
        *) echo "Usage: $0 -p playlist_url -d music_dir"; exit 1;;
    esac
done

if [ -z "$PLAYLIST_URL" ] || [ -z "$MUSIC_DIR" ]; then
    echo "Usage: $0 -p playlist_url -d music_dir"
    exit 1
fi

# Check for required tools
REQUIRED_CMDS="yt-dlp ffmpeg sed grep awk mkdir mv basename"

MISSING=0

for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Missing command: $cmd"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 1 ]; then
    echo "⚠ Please install the missing dependencies before running the script."
    exit 1
else
    echo "Pre-check finished."
fi

# Download palylist
TMP_DIR="$MUSIC_DIR/tmp"
mkdir -p "$TMP_DIR"

yt-dlp --format bestaudio --extract-audio --audio-format mp3 --audio-quality 0 --add-metadata \
 -o "$TMP_DIR/%(artist)s - %(title)s.%(ext)s" \
 --download-archive "$MUSIC_DIR/downloaded.txt" -i "$PLAYLIST_URL"

# For multi-authors tracks, fix filename and metadata
for f in "$TMP_DIR"/*.mp3; do
    [ -e "$f" ] || continue  # Skip case
    base="$(basename "$f")"
    first_artist="$(echo "$base" | sed 's/ - .*//' | sed 's/,.*//')"
    title="$(echo "$base" | sed 's/.* - //')"
    newname="$TMP_DIR/$first_artist - $title"
    mv "$f" "$newname"

    # Rewrite Artist tag by ffmpeg
    ffmpeg -i "$newname" -codec copy -metadata artist="$first_artist" "${newname}.fixed.mp3" -y
    mv "${newname}.fixed.mp3" "$newname"
done

mv "$TMP_DIR"/*.mp3 "$MUSIC_DIR/"
