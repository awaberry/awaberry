#!/bin/bash



get_project() {
  curl -s -X POST "$BASE_URL/getProject" \
    -H "Content-Type: application/json" \
    -d "{\"projectkey\":\"$PROJECT_KEY\",\"projectsecret\":\"$PROJECT_SECRET\"}"
}

init_session() {

  RESPONSE=$(curl -s -X POST "$BASE_URL/initSession" \
    -H "Content-Type: application/json" \
    -d "{\"projectkey\":\"$PROJECT_KEY\",\"projectsecret\":\"$PROJECT_SECRET\"}")
  echo "$RESPONSE" | jq -r '.sessionToken'
}

start_device_connection() {
  local session_token="$1"
  local deviceuuid="$2"
  curl -s -X POST "$BASE_URL/startDeviceConnection" \
    -H "Content-Type: application/json" \
    -d "{\"sessionToken\":\"$session_token\",\"deviceuuid\":\"$deviceuuid\"}"
}

get_device_connection_status() {
  local session_token="$1"
  local deviceuuid="$2"
  curl -s -X POST "$BASE_URL/getDeviceConnectionStatus" \
    -H "Content-Type: application/json" \
    -d "{\"sessionToken\":\"$session_token\",\"deviceuuid\":\"$deviceuuid\"}"
}

disconnect_device_connection() {
  local session_token="$1"
  local deviceuuid="$2"
  curl -s -X POST "$BASE_URL/disconnectDeviceConnection" \
    -H "Content-Type: application/json" \
    -d "{\"sessionToken\":\"$session_token\",\"deviceuuid\":\"$deviceuuid\"}"
}

execute_command() {
  local session_token="$1"
  local deviceuuid="$2"
  local command="$3"
  curl -s -X POST "$BASE_URL/executeCommand" \
    -H "Content-Type: application/json" \
    -d "{\"sessionToken\":\"$session_token\",\"deviceuuid\":\"$deviceuuid\",\"command\":\"$command\"}"
}

get_additional_command_results() {
  local session_token="$1"
  local deviceuuid="$2"
  curl -s -X POST "$BASE_URL/getAdditionalCommandResults" \
    -H "Content-Type: application/json" \
    -d "{\"sessionToken\":\"$session_token\",\"deviceuuid\":\"$deviceuuid\"}"
}


BASE_URL="$1"
PROJECT_KEY="$2"
PROJECT_SECRET="$3"
METHOD_TO_EXECUTE="$4"

#echo "process with baseurl $BASE_URL projectkey $PROJECT_KEY projectsecret $PROJECT_SECRET method $METHOD_TO_EXECUTE"

if [[ "$METHOD_TO_EXECUTE" == "init_session" ]]; then
  echo $(init_session)
elif [[ "$METHOD_TO_EXECUTE" == "get_project" ]]; then
  echo $(get_project)
elif [[ "$METHOD_TO_EXECUTE" == "start_device_connection" ]]; then
  echo $(start_device_connection "$5" "$6")
elif [[ "$METHOD_TO_EXECUTE" == "get_device_connection_status" ]]; then
  echo $(get_device_connection_status "$5" "$6")
elif [[ "$METHOD_TO_EXECUTE" == "disconnect_device_connection" ]]; then
  echo $(disconnect_device_connection "$5" "$6")
elif [[ "$METHOD_TO_EXECUTE" == "execute_command" ]]; then
  echo $(execute_command "$5" "$6" "$7")
elif [[ "$METHOD_TO_EXECUTE" == "get_additional_command_results" ]]; then
  echo $(get_additional_command_results "$5" "$6")
fi
