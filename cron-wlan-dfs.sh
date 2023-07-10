#!/bin/bash

# Define the web request URL and token
URL="https://example.com/webhook/url"
TOKEN="auth_token"

# Define the state file path
STATE_FILE="/var/run/wlan0-last-state"

# Define the PID file path
PID_FILE="/var/run/cron-wlan0-dfs.pid"

# Define the trusted root certificate
ROOT_CERT="$HOME/root.pem"

# Helper function for logging
log() {
  echo "$1"
  logger -t "wlan_checker" "$1"
}

# Check if another instance of the script is already running
if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")
  if kill -0 "$pid"; then
    log "Another instance of the script is already running with PID: $pid"
    exit 1
  else
    log "Stale PID file found. Removing the PID file and continuing..."
    rm "$PID_FILE"
  fi
fi

# Create the PID file
echo "$$" > "$PID_FILE"

# Function to send a web request
send_web_request() {
  msg="$1"
  log "$msg"
  ret=$(curl --cacert "$ROOT_CERT" "$URL" -H "Authorization: $TOKEN" -d "$msg")
}

# Function to check the state of wlan0
check_wlan0_state() {
  output=$(hostapd_cli -i wlan0 status 2>&1)
  state=$(echo "$output" | grep "^state=" | cut -d'=' -f2)
  if [[ $output =~ "wpa_ctrl_open: No such file or directory" ]]; then
    state="DISABLED"
  fi
  echo "$state"
}

# Function to restart WiFi and monitor state for 2 minutes
restart_and_monitor_wifi() {
  # Restart WiFi
  /sbin/wifi up radio0

  # Get the initial state
  previous_state="$1"
  for ((i=0; i<120; i++)); do
    current_state=$(check_wlan0_state)
    if [[ $current_state != "$previous_state" ]]; then
      send_web_request "WiFi state $previous_state => $current_state on $(date '+%H:%M:%S')"
      previous_state="$current_state"
    fi
    if [[ $current_state == "ENABLED" ]]; then
      break
    fi
    sleep 1
  done
}

# Read the last recorded state
if [[ -f "$STATE_FILE" ]]; then
  last_state=$(cat "$STATE_FILE")
else
  touch "$STATE_FILE"
  last_state="UNKNOWN"
fi

# Get the current state
current_state=$(check_wlan0_state)

log "WiFi state: $current_state"

# Check if the state has changed
if [[ $current_state != "ENABLED" ]]; then
  log "WiFi state changed from $last_state to $current_state"
  send_web_request "WiFi Alert: $last_state => $current_state on $(date '+%H:%M:%S')"

  # If the state changed to something other than ENABLED, restart WiFi
  if [[ $current_state != "ENABLED" ]]; then
    restart_and_monitor_wifi "$current_state"
  fi

  # Update the state file with the new state
  echo "$current_state" > "$STATE_FILE"
fi

# Remove the PID file
rm "$PID_FILE"

