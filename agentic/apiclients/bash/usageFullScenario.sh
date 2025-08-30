#!/bin/bash

BASE_URL="https://agentic.awaberry.net/apirequests"
SCRIPT_PATH="./awaberryapirequestclient.sh"

if [[ -n "$1" && -n "$2" ]]; then
  PROJECT_KEY="$1"
  PROJECT_SECRET="$2"
else
  read -p "Enter Project Key: " PROJECT_KEY
  read -p "Enter Project Secret: " PROJECT_SECRET
fi

echo "Getting project info..."
PROJECT_RES=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" get_project)
SETUP_ENTRIES=$(echo "$PROJECT_RES" | jq -c '.agentprojectsetup | fromjson | .setupEntries')

if [[ "$SETUP_ENTRIES" == "null" || -z "$SETUP_ENTRIES" ]]; then
  echo "No devices found."
  exit 1
fi

echo "Available devices:"
echo "$SETUP_ENTRIES" | jq -c '.[]' | while read -r entry; do
  DEVICE_NAME=$(echo "$entry" | jq -r '.deviceName')
  DEVICE_UUID=$(echo "$entry" | jq -r '.deviceuuid')
  echo "$DEVICE_NAME. uuid: $DEVICE_UUID"
done

NUM_DEVICES=$(echo "$SETUP_ENTRIES" | jq 'length')
if [[ "$NUM_DEVICES" -eq 1 ]]; then
  DEVICE_UUID=$(echo "$SETUP_ENTRIES" | jq -r '.[0].deviceuuid')
  echo "Using only available device: $DEVICE_UUID"
else
  read -p "Enter Device UUID to connect: " DEVICE_UUID
fi

SESSION_TOKEN=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" init_session)
echo "Session initialized successfully. Token: $SESSION_TOKEN"

echo "Starting device connection..."
CONNECTION_RES=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" start_device_connection "$SESSION_TOKEN" "$DEVICE_UUID")
echo "Device connection started: $CONNECTION_RES"

STATUS_RES=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" get_device_connection_status "$SESSION_TOKEN" "$DEVICE_UUID")
echo "Device connection status: $STATUS_RES"

while true; do
  read -p "type next command (or 'exit' to quit): " COMMAND_TO_EXECUTE
  if [[ "$COMMAND_TO_EXECUTE" == "exit" ]]; then
    break
  fi
  RESULT=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" execute_command "$SESSION_TOKEN" "$DEVICE_UUID" "$COMMAND_TO_EXECUTE")
  ENDED_ON_TERMINAL=$(echo "$RESULT" | jq -r '.lastCommandEndedOnTerminal')
  COMMAND_RESULT=$(echo "$RESULT" | jq -r '.commandResult')
  echo "endedOnTerminal: $ENDED_ON_TERMINAL | Result: $COMMAND_RESULT"
done