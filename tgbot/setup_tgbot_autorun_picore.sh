#!/bin/sh

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BOT_SCRIPT="$SCRIPT_DIR/tg_bot_manager.sh"

if [ ! -f "$BOT_SCRIPT" ]; then
    echo "❌ tg_bot_manager.sh not found in $SCRIPT_DIR"
    exit 1
fi

BOOTLOCAL="/opt/bootlocal.sh"
MARKER="# tg_bot_manager.sh autorun"

echo "➡️ Setting up autorun in $BOOTLOCAL"

# Check if already exists
if grep -q "$MARKER" "$BOOTLOCAL"; then
    echo "✅ Autorun already configured."
else
    # echo "$MARKER" | sudo tee -a "$BOOTLOCAL" >/dev/null
    # echo "$BOT_SCRIPT &" | sudo tee -a "$BOOTLOCAL" >/dev/null
    # Insert before #pCPstop------
    sudo sed -i "/#pCPstop------/i $MARKER\n$BOT_SCRIPT \&" "$BOOTLOCAL"
    echo "✅ Autorun line added."
fi

echo "➡️ Adding bootlocal.sh to backup list..."
if ! grep -q "opt/bootlocal.sh" /opt/.filetool.lst; then
    echo "opt/bootlocal.sh" | sudo tee -a /opt/.filetool.lst >/dev/null
    echo "✅ Added to /opt/.filetool.lst"
fi

echo "➡️ Saving backup to persist changes..."
sudo filetool.sh -b

echo "🎉 Setup complete! The bot will autostart at boot."
