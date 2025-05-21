#!/bin/sh

show_help() {
  echo "📜 This script generates or updates an .m3u playlist file using a list of desired artists."
  echo ""
  echo "Usage:"
  echo "  $0 -d <music_dir> -a <artists_file> -p <playlist_file>"
  echo ""
  echo "Parameters:"
  echo "  -d <music_dir>      Path to the folder containing all music files (e.g., /mnt/data/music)"
  echo "  -a <artists_file>   Path to a file with one artist per line. Each line should match the format used in filenames"
  echo "                      Example line: Epolets"
  echo "  -p <playlist_file>  Path to the playlist file (.m3u) to create or update. Absolute paths to songs will be added."
  echo ""
  echo "Behavior:"
  echo "  - Ensures playlist file's directory exists"
  echo "  - Avoids duplicates"
  echo "  - Only includes *.mp3 files with filename format like 'Artist - Title.mp3'"
  echo ""
  echo "Example:"
  echo "  $0 -d /mnt/data/music -a /mnt/data/artists.txt -p /mnt/data/playlists/my_mix.m3u"
  exit 0
}

# Parse arguments
while getopts d:a:p:h-: flag; do
  case "${flag}" in
    d) MUSIC_DIR=${OPTARG} ;;
    a) ARTISTS_FILE=${OPTARG} ;;
    p) PLAYLIST_FILE=${OPTARG} ;;
    h) show_help ;;
    -)
      case "${OPTARG}" in
        help) show_help ;;
        *) echo "❌ Unknown option --${OPTARG}"; exit 1 ;;
      esac ;;
    *) echo "❌ Invalid usage"; show_help ;;
  esac
done

if [ -z "$MUSIC_DIR" ] || [ -z "$ARTISTS_FILE" ] || [ -z "$PLAYLIST_FILE" ]; then
  echo "❌ Missing required arguments."
  show_help
fi

# Check if playlist directory exists
PLAYLIST_DIR=$(dirname "$PLAYLIST_FILE")
if [ ! -d "$PLAYLIST_DIR" ]; then
  echo "❌ Directory '$PLAYLIST_DIR' does not exist."
  exit 1
fi

# Ensure file exists
touch "$PLAYLIST_FILE"
TMP_PLAYLIST=$(mktemp)
sort "$PLAYLIST_FILE" | uniq > "$TMP_PLAYLIST"

# Append found songs by artist to temp file
while IFS= read -r ARTIST || [ -n "$ARTIST" ]; do
  [ -z "$ARTIST" ] && continue
  find "$MUSIC_DIR" -type f -iname "$ARTIST - *.mp3" >> "$TMP_PLAYLIST"
done < "$ARTISTS_FILE"

sort "$TMP_PLAYLIST" | uniq > "$PLAYLIST_FILE"
rm "$TMP_PLAYLIST"

echo "✅ Playlist updated: $PLAYLIST_FILE"
