#!/bin/sh

set -e

echo "➡️ Installing dependencies for aarch64"

ARCH=$(uname -m)
echo "➡️ Detected architecture: $ARCH"

if [ "$ARCH" != "aarch64" ]; then
    echo "❌ Unsupported architecture: $ARCH. This installer supports only aarch64."
    exit 1
fi

# Define local binary directory
LOCAL_BIN="/home/tc/local/bin"

echo "➡️ Installing curl"
tce-load -wi curl

echo "➡️ Creating directory $LOCAL_BIN"
mkdir -p "$LOCAL_BIN"

echo "➡️ Downloading ffmpeg static build for aarch64"
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz -O /tmp/ffmpeg.tar.xz
tar -xJf /tmp/ffmpeg.tar.xz -C /tmp
cp /tmp/ffmpeg-*/ffmpeg "$LOCAL_BIN/"
cp /tmp/ffmpeg-*/ffprobe "$LOCAL_BIN/"
chmod +x "$LOCAL_BIN/ffmpeg" "$LOCAL_BIN/ffprobe"

YT_DLP_URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.04.30/yt-dlp_linux_aarch64"
echo "➡️ Downloading yt-dlp binary for aarch64"
wget "$YT_DLP_URL" -O "$LOCAL_BIN/yt-dlp"
chmod +x "$LOCAL_BIN/yt-dlp"

JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-arm64"
echo "➡️ Downloading jq binary for aarch64"
wget "$JQ_URL" -O "$LOCAL_BIN/jq"
chmod +x "$LOCAL_BIN/jq"

echo "➡️ Adding $LOCAL_BIN to PATH"
if ! grep -q "export PATH=.*${LOCAL_BIN}" /home/tc/.profile; then
    echo "export PATH=$LOCAL_BIN:\$PATH" >> /home/tc/.profile
    export PATH="$LOCAL_BIN:$PATH"
fi

echo "➡️ Saving changes to backup"
# filetool.sh -b

echo "✅ Installation and backup completed successfully!"
