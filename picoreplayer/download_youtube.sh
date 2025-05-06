#!/bin/sh

show_help() {
    echo "Usage: $0 -y <YouTube URL> -o <output file name without .mp3>"
    echo ""
    echo "Parameters:"
    echo "  -y     YouTube URL to download audio"
    echo "  -o     Output file name (without .mp3 extension)"
    echo "  --help Show this help message"
}

# Ініціалізація змінних
URL=""
FILENAME=""

# Обробка аргументів
while [[ $# -gt 0 ]]; do
    case $1 in
        -y)
            URL="$2"
            shift 2
            ;;
        -o)
            FILENAME="$2"
            shift 2
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

# Перевірка обов'язкових аргументів
if [[ -z "$URL" ]]; then
    echo "❌ YouTube URL (-y) is required."
    show_help
    exit 1
fi

if [[ -z "$FILENAME" ]]; then
    # Отримуємо назву відео, замінюючи спецсимволи на _
    # FILENAME=$(yt-dlp --get-title "$URL" | sed 's/[\/:*?"<>|]/_/g')
    FILENAME=$(yt-dlp --get-title "$URL")
fi

echo "🎵 Downloading from YouTube..."
if ! yt-dlp --quiet -f 'bestaudio' --extract-audio --audio-format mp3 --audio-quality 0 \
    -o "${FILENAME}.%(ext)s" "$URL"; then
    echo "❌ Failed to download from YouTube."
    exit 1
fi

echo "✅ Завантаження завершено: ${FILENAME}.mp3"
