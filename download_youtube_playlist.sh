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
 -o "$TMP_DIR/%(id)s.%(ext)s-tmp" \
 --download-archive "$MUSIC_DIR/downloaded.txt" -i "$PLAYLIST_URL"

# For multi-authors tracks, fix filename and metadata
for f in "$TMP_DIR"/*.mp3; do
    [ -e "$f" ] || continue

    # Extract artist and title from metadata
    artist=$(ffprobe -v error -show_entries format_tags=artist -of default=nw=1:nk=1 "$f")
    title=$(ffprobe -v error -show_entries format_tags=title -of default=nw=1:nk=1 "$f")

    if [ -z "$artist" ] || [ -z "$title" ]; then
        echo "⚠️  Skipping $f: missing artist or title in metadata"
        continue
    fi

    # Clean up the artist name
    first_artist=$(echo "$artist" | sed 's/,.*//')

    # Rename the file accordingly
    newname="$TMP_DIR/$first_artist - $title.mp3"
    mv -v "$f" "$newname"

    # Rewrite artist tag
    ffmpeg -i "$newname" -codec copy -metadata artist="$first_artist" "${newname}.fixed.mp3" -y
    mv "${newname}.fixed.mp3" "$newname"
done

set -- "$TMP_DIR"/*.mp3
if [ -e "$1" ]; then
    mv -v "$@" "$MUSIC_DIR/"
else
    echo "ℹ️  No new mp3 files to move."
fi

if [ -d "$TMP_DIR" ]; then
    if [ -z "$(ls -A "$TMP_DIR")" ]; then
        rm -r "$TMP_DIR"
        echo "✅ All files processed."
    else
        echo "⚠️  Warning: some files are failed to processed. Please check: $TMP_DIR"
    fi
fi
