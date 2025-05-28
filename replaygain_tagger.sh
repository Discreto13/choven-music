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

# Check for ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "❌ ffmpeg is not installed or not in PATH"
  exit 1
fi

echo "🔊 Processing files for ReplayGain tagging..."

find "$INPUT" -type f -iname "*.mp3" | while IFS= read -r f; do
  [ -e "$f" ] || continue
  echo "🎧 Analyzing: $(basename "$f")"

  OUTPUT=$(ffmpeg -i "$f" -filter:a "replaygain" -f null - 2>&1)

  GAIN=$(echo "$OUTPUT" | sed -n 's/.*track_gain = \([-0-9\.]*\) dB.*/\1/p')
  PEAK=$(echo "$OUTPUT" | sed -n 's/.*track_peak = \([0-9\.]*\).*/\1/p')

  if [ -n "$GAIN" ] && [ -n "$PEAK" ]; then
    echo "📊 Gain: $GAIN dB, Peak: $PEAK"

    ffmpeg -loglevel error -i "$f" -c:a copy \
      -metadata REPLAYGAIN_TRACK_GAIN="${GAIN} dB" \
      -metadata REPLAYGAIN_TRACK_PEAK="$PEAK" \
      "${f%.mp3}.gain.mp3" -y

    mv -v "${f%.mp3}.gain.mp3" "$f"
  else
    echo "⚠️  Could not extract ReplayGain info for: $f"
  fi
done

echo "🎵 Done!"
