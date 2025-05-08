#!/bin/sh

set -e

echo "➡️ Installing curl"
tce-load -wi curl

echo "➡️ Creating directory /home/tc/local/bin"
mkdir -p /home/tc/local/bin

echo "➡️ Downloading ffmpeg static build"
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz -O /tmp/ffmpeg.tar.xz
tar -xJf /tmp/ffmpeg.tar.xz -C /tmp
cp /tmp/ffmpeg-*/ffmpeg /home/tc/local/bin/
cp /tmp/ffmpeg-*/ffprobe /home/tc/local/bin/
chmod +x /home/tc/local/bin/ffmpeg /home/tc/local/bin/ffprobe

ARCH=$(uname -m)
echo "➡️ Detected architecture: $ARCH"

if [ "$ARCH" = "aarch64" ]; then
    YT_DLP_URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.04.30/yt-dlp_linux_aarch64"
elif [ "$ARCH" = "armv7l" ]; then
    YT_DLP_URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.04.30/yt-dlp_linux_armv7l"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "➡️ Downloading yt-dlp binary for $ARCH"
wget "$YT_DLP_URL" -O /home/tc/local/bin/yt-dlp
chmod +x /home/tc/local/bin/yt-dlp

echo "➡️ Downloading jq binary for $ARCH"
wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-arm64 -O /home/tc/local/bin/jq
chmod +x /home/tc/local/bin/jq

echo "➡️ Adding /home/tc/local/bin to PATH"
export PATH=/home/tc/local/bin:$PATH
if ! grep -q 'export PATH=/home/tc/local/bin:$PATH' /home/tc/.profile; then
    echo 'export PATH=/home/tc/local/bin:$PATH' >> /home/tc/.profile
fi

echo "➡️ Saving changes to backup"
filetool.sh -b

echo "✅ Installation and backup completed successfully!"
