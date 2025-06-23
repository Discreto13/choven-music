#!/bin/bash

SCRIPT_NAME="$(basename "$0")"


# === Normalization Target Parameters ===

# Target integrated loudness (LUFS)
# Common values: -16 (streaming), -18 (soft), -20 (very soft)
TARGET_I="-18"

# True peak maximum (dB)
# Common values: -1.5 (safe), -2.0 (safer)
TARGET_TP="-1.5"

# Loudness range target (LU)
# Lower = more consistent volume
# Common: 11 (default), 8 (moderate compression), 5 (flat)
TARGET_LRA="8"

# Create a unique temporary file for loudnorm log
TMP_LOG="$(mktemp /tmp/loudnorm_log.json)"

# Clean up the temporary log file on exit
trap 'rm -f "$TMP_LOG"' EXIT

show_help() {
  echo "Usage:"
  echo "  $SCRIPT_NAME /path/to/song.mp3"
  echo "  $SCRIPT_NAME /path/to/folder"
  echo
  echo "Two-pass EBU R128 loudness normalization using ffmpeg."
  echo "Overwrites original MP3 files after normalization."
  echo
  echo "Options:"
  echo "  --help       Show this help message"
}

normalize_file() {
  local f="$1"
  echo "🔊 Processing $f..."

  ffmpeg -i "$f" -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=json -f null - 2> "$TMP_LOG"

  I=$(grep "input_i" "$TMP_LOG" | awk -F: '{ print $2 }' | tr -d ', ')
  TP=$(grep "input_tp" "$TMP_LOG" | awk -F: '{ print $2 }' | tr -d ', ')
  LRA=$(grep "input_lra" "$TMP_LOG" | awk -F: '{ print $2 }' | tr -d ', ')
  THRESH=$(grep "input_thresh" "$TMP_LOG" | awk -F: '{ print $2 }' | tr -d ', ')
  OFFSET=$(grep "target_offset" "$TMP_LOG" | awk -F: '{ print $2 }' | tr -d ', ')

  tmpfile="${f%.mp3}.normalized.mp3"

  ffmpeg -i "$f" -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:offset=$OFFSET:linear=true:print_format=summary "$tmpfile"

  mv "$tmpfile" "$f"

  echo "✅ Normalized $f"
}

# === Entry Point ===

if [[ $# -eq 0 || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

INPUT="$1"

if [[ -f "$INPUT" && "$INPUT" == *.mp3 ]]; then
  normalize_file "$INPUT"
elif [[ -d "$INPUT" ]]; then
  find "$INPUT" -type f -name "*.mp3" | while read -r file; do
    normalize_file "$file"
  done
else
  echo "❌ Invalid input: must be an .mp3 file or a directory."
  show_help
  exit 1
fi
