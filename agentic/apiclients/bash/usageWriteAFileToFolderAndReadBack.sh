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
echo "Session initialized successfully - startDeviceConnection - please wait - sessionToken $SESSION_TOKEN"

CONNECTION_RES=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" start_device_connection "$SESSION_TOKEN" "$DEVICE_UUID")
echo "Device connection started: $CONNECTION_RES"

STATUS_RES=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" get_device_connection_status "$SESSION_TOKEN" "$DEVICE_UUID")
echo "Device connection status: $STATUS_RES"

if [[ "$STATUS_RES" == "true" ]]; then
  echo "ready to send commands"

  # 1: Write content to executiontest.txt
  # please note: for bash we need to escape new lines with \\n to send file content - and surround with '
  WRITE_FILE_CMD='echo \"testcontent\\n\\nthis is test content\" > executiontest.txt'

  echo "Write file command: $WRITE_FILE_CMD"
  RESULT=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" execute_command "$SESSION_TOKEN" "$DEVICE_UUID" "$WRITE_FILE_CMD")
  ENDED_ON_TERMINAL=$(echo "$RESULT" | jq -r '.lastCommandEndedOnTerminal')
  COMMAND_RESULT=$(echo "$RESULT" | jq -r '.commandResult')
  echo "endedOnTerminal: $ENDED_ON_TERMINAL | Result: $COMMAND_RESULT"

  # 2: Read content from executiontest.txt
  READ_FILE_CMD='cat executiontest.txt'
  RESULT_READ_FILE=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" execute_command "$SESSION_TOKEN" "$DEVICE_UUID" "$READ_FILE_CMD")
  READ_RESULT=$(echo "$RESULT_READ_FILE" | jq -r '.commandResult')
  echo "Response read file: $READ_RESULT"

else
  echo "Device not ready."
fi