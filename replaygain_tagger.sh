#!/bin/sh

# replaygain_tagger.sh
# Calculates and embeds ReplayGain tags into MP3 files using ffmpeg and sed.
# Usage:
#   ./replaygain_tagger.sh /path/to/music_dir
#   ./replaygain_tagger.sh /path/to/song.mp3

set -e

# Check input
if [ -z "$1" ]; then
  echo "❌ Usage: $0 /path/to/music_dir_or_mp3"
  exit 1
fi

INPUT="$1"

# Prepare file list
if [ -d "$INPUT" ]; then
  FILES=$(find "$INPUT" -type f -iname "*.mp3")
elif [ -f "$INPUT" ] && echo "$INPUT" | grep -qi '\.mp3$'; then
  FILES="$INPUT"
else
  echo "❌ Error: '$INPUT' is neither a valid directory nor an .mp3 file."
  exit 1
fi

# Check for ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "❌ ffmpeg is not installed or not in PATH"
  exit 1
fi

echo "🔊 Processing files for ReplayGain tagging..."

for f in $FILES; do
  [ -e "$f" ] || continue
  echo "🎧 Analyzing: $(basename "$f")"

  OUTPUT=$(ffmpeg -hide_banner -loglevel error -i "$f" -filter:a "replaygain" -f null - 2>&1)

  GAIN=$(echo "$OUTPUT" | sed -n 's/.*track gain: \([-0-9\.]*\) dB.*/\1/p')
  PEAK=$(echo "$OUTPUT" | sed -n 's/.*track peak: \([0-9\.]*\).*/\1/p')

  if [ -n "$GAIN" ] && [ -n "$PEAK" ]; then
    echo "📊 Gain: $GAIN dB, Peak: $PEAK"

    ffmpeg -hide_banner -loglevel error -i "$f" -c:a copy \
      -metadata REPLAYGAIN_TRACK_GAIN="${GAIN} dB" \
      -metadata REPLAYGAIN_TRACK_PEAK="$PEAK" \
      "${f%.mp3}.gain.mp3" -y

    mv -v "${f%.mp3}.gain.mp3" "$f"
  else
    echo "⚠️  Could not extract ReplayGain info for: $f"
  fi
done

echo "🎵 Done!"
