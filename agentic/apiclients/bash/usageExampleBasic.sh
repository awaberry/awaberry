#!/bin/bash

BASE_URL="https://agentic.awaberry.net/apirequests"
if [[ -n "$1" && -n "$2" ]]; then
  PROJECT_KEY="$1"
  PROJECT_SECRET="$2"
else
  read -p "Enter Project Key: " PROJECT_KEY
  read -p "Enter Project Secret: " PROJECT_SECRET
fi

SCRIPT_PATH="./awaberryapirequestclient.sh"

echo "calls $SCRIPT_PATH with baseurl $BASE_URL projectkey $PROJECT_KEY projectsecret $PROJECT_SECRET"
SESSION_TOKEN=$($SCRIPT_PATH "$BASE_URL" "$PROJECT_KEY" "$PROJECT_SECRET" init_session)

echo "Session Token ; $SESSION_TOKEN"