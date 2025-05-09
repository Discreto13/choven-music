#!/bin/sh

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BOT_SCRIPT="$SCRIPT_DIR/tg_bot_manager.sh"
LOG_FILE="$SCRIPT_DIR/tg_bot_prod.log"
BOOTLOCAL="/opt/bootlocal.sh"
MARKER="# tg_bot_manager.sh autorun"
CMD_LINE="( $BOT_SCRIPT </dev/null | tee -a $LOG_FILE ) &"

echo "➡️ Checking if tg_bot_manager.sh exists..."
if [ ! -f "$BOT_SCRIPT" ]; then
    echo "❌ tg_bot_manager.sh not found in $SCRIPT_DIR"
    exit 1
fi

echo "➡️ Setting up autorun in $BOOTLOCAL"

# Check if marker already exists
if grep -q "$MARKER" "$BOOTLOCAL"; then
    echo "✅ Autorun already configured."
else
    # Insert marker and command above #pCPstop------
    sudo sed -i "/#pCPstop------/i $MARKER\n$CMD_LINE" "$BOOTLOCAL"
    echo "✅ Autorun line added above #pCPstop------."
fi

echo "➡️ Adding bootlocal.sh to backup list..."
if ! grep -q "opt/bootlocal.sh" /opt/.filetool.lst; then
    echo "opt/bootlocal.sh" | sudo tee -a /opt/.filetool.lst >/dev/null
    echo "✅ Added to /opt/.filetool.lst"
fi

echo "➡️ Saving backup to persist changes..."
sudo filetool.sh -b

echo "🎉 Setup complete! The bot will autostart at boot with logging to console + $LOG_FILE"
