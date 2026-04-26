#!/bin/bash
 
TELEGRAM_BOT_TOKEN="8684432474:AAGOBhw8RdiwAsxfJMPN2pJNaimyAXJ2rr8"
TELEGRAM_CHAT_ID="8156582552"

LOG_FILE="/var/log/ups_handler.log"
 
telegram_send() {
  local message=$1 retries=3 success=false
  for ((i=1; i<=retries; i++)); do
    response=$(curl -s -X POST \
      "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d "chat_id=$TELEGRAM_CHAT_ID&text=$message")
    if [[ $response == *"true"* ]]; then success=true; break; fi
    sleep 1
  done
}
 
if [ -f /Users/Steve/.ups_shutdown_flag ]; then
  rm -f /Users/Steve/.ups_shutdown_flag
  ssh -o ConnectTimeout=10 -o BatchMode=yes \
    steve@192.168.137.252 'sudo shutdown -c' 2>/dev/null
  ssh -o ConnectTimeout=10 -o BatchMode=yes \
    shit@192.168.1.101 'shutdown /a' 2>/dev/null
  telegram_send "Manual cancel: all shutdowns aborted."
else
  telegram_send "No shutdown in progress."
fi

