#!/bin/bash

currentMainPath=$(pwd)
awaberryHomeDataDir=~/Library/Application\ Support/awaberry

apiServerUrl="https://svgfbngpzdaksjzuwuli.supabase.co/functions/v1"
apiToken="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2Z2ZibmdwemRha3NqenV3dWxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA5MDI4NTgsImV4cCI6MjA0NjQ3ODg1OH0.UoGYsZlIWsMeFQ7vRkU9yCwJerkUxT65AhFKWSbbRzU"

# Ensure the data directory exists
awaberryDir="$HOME"
awaberryHomeDir=$awaberryDir


awaberryMainDir="$awaberryDir/awaberry/"

# for storing the awaberry relevant config files
awaberryHomeDataDir=$awaberryMainDir/.awaberrydata
mkdir -p $awaberryHomeDataDir

# data for file browser to init to
awaberryFileBrowserDataDir=$awaberryMainDir/data
mkdir -p $awaberryHomeDataDir

deviceconnectedfile=$awaberryHomeDataDir/deviceconnected.txt
deviceuuidfile=$awaberryHomeDataDir/deviceuuid.txt
useruuidfile=$awaberryHomeDataDir/useruuid.txt

accountnamefile="$awaberryHomeDataDir/accountname.txt"

deviceConnectSuccessFile=$awaberryHomeDataDir/deviceconnectsuccess.txt
devicenamefile="$awaberryHomeDataDir/devicename.txt"
fileCountryCode="$awaberryHomeDataDir/country_code.txt"

cloudCertsDirectory="$awaberryHomeDataDir/cloudcerts"
mkdir -p "$cloudCertsDirectory"
publicUserCertFile="$cloudCertsDirectory/AwaBerryUserPublicCert.pub"

sshcertssDirectory="$awaberryHomeDataDir/sshcerts"
mkdir -p "$sshcertssDirectory"

userHomeDir="$HOME"
userHomeDirSsh="$userHomeDir/.ssh"

directoryAwaberryClient="$awaberryHomeDataDir/awaberryclient"

# the default home dir for file browser: $Home/Downloads - exists by default

# write the path to java for brew
brew --prefix openjdk@21 > "$awaberryHomeDataDir/java.txt"


# Check for required commands
for cmd in jq curl base64 openssl ssh-keygen; do
  if ! command -v $cmd &>/dev/null; then
    echo "Error: $cmd is not installed."
    case $cmd in
      jq) echo "Install with: brew install jq" ;;
      curl) echo "Install with: brew install curl" ;;
      base64) echo "base64 should be available by default on macOS." ;;
      openssl) echo "Install with: brew install openssl" ;;
      ssh-keygen) echo "ssh-keygen is included with macOS (part of OpenSSH)." ;;
    esac
    exit 1
  fi
done






installAwaberryClient() {

  cd $awaberryMainDir || exit 1
  echo "install awaberryclient in $directoryAwaberryClient"

  deploymentServerUrl="https://data.dl.awaberry.com/data"
  buildtarget="software"
  requiredModule=awaberryclient

  echo "install the awaberryclient"
  echo "download $requiredModule from $deploymentServerUrl/$buildtarget/$requiredModule/install.sh"



  curl -s "$deploymentServerUrl/$buildtarget/$requiredModule/install.sh" -o install.sh
  chmod +x install.sh

  ## run install
  ./install.sh
  tver=$?
  if [ "$tver" == "0" ]; then
      echo "update successful"
  else
    echo "install failed - exit"
    exit 1
  fi
}


generateCertificates() {
  deviceuuid=$(cat "$deviceuuidfile")
  if [ ! -e "$sshcertssDirectory/UserCert.key" ]; then
    content=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $apiToken" -d "{\"identifier\": \"$deviceuuid\"}" $apiServerUrl/sslsshcertificatedevice)
    userkey=$(echo "$content" | jq -r '.userkey')
    usercrt=$(echo "$content" | jq -r '.usercrt')

    if [ -z "$userkey" ] || [ -z "$usercrt" ]; then
      echo "Error: userkey or usercrt is empty. Exiting."
      exit 1
    fi

    echo "$userkey" | base64 --decode > "$sshcertssDirectory/UserCert.key"
    echo "$usercrt" | base64 --decode > "$sshcertssDirectory/UserCert.pem"
    chmod 600 "$sshcertssDirectory/UserCert.key"
    ssh-keygen -y -f "$sshcertssDirectory/UserCert.key" > "$sshcertssDirectory/UserCert.pub"
    rsainput=$(cat "$sshcertssDirectory/UserCert.pub")
    rsadata=$(sed "s/ssh-rsa //g" <<< "$rsainput")
    echo "$rsadata" > "$awaberryHomeDataDir/identifier.txt"
    echo "$rsainput" >> "$userHomeDirSsh/authorized_keys"
    chmod 700 "$userHomeDirSsh"
    chmod 600 "$userHomeDirSsh/authorized_keys"
  fi
  if [ ! -e "$cloudCertsDirectory/UserCert.key" ]; then
    content=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $apiToken" -d "{\"identifier\": \"$deviceuuid\"}" $apiServerUrl/sslcloudcertificatedevice)
    userkey=$(echo "$content" | jq -r '.userkey')
    usercrt=$(echo "$content" | jq -r '.usercrt')

    if [ -z "$userkey" ] || [ -z "$usercrt" ]; then
      echo "Error: userkey or usercrt is empty. Exiting."
      exit 1
    fi

    echo "$userkey" | base64 --decode > "$cloudCertsDirectory/UserCert.key"
    echo "$usercrt" | base64 --decode > "$cloudCertsDirectory/UserCert.pem"
    openssl rsa -in "$cloudCertsDirectory/UserCert.key" -pubout > "$cloudCertsDirectory/UserCert.pub"
    user_public_key=$(cat "$cloudCertsDirectory/UserCert.pub" | base64)
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $apiToken" -d "{\"deviceid\": \"$deviceuuid\", \"devicecert\": \"$user_public_key\"}" $apiServerUrl/devicelobby_addorupdatepubliccert)
    if [ -z "$response" ] || [[ $response == *"exception"* ]]; then
      echo "Operation failed with exception: $response"
      exit 1
    fi
    echo "$response" | base64 --decode > "$publicUserCertFile"
  fi
}

getLocalIp() {
  localip=$(ipconfig getifaddr en0)
  echo "$localip"
}

getMemoryTotalFile() {
  mem_bytes=$(sysctl -n hw.memsize)
  memory_total=$((mem_bytes / 1024 / 1024))
  echo "$memory_total"
}

getCpuInformation() {
  CPU_COUNT=$(sysctl -n hw.ncpu)
  MODEL_NAME=$(sysctl -n machdep.cpu.brand_string)
  ARCHITECTURE=$(uname -m)
  VENDOR_ID="Apple"
  CPU_MIN_MHZ=""
  CPU_MAX_MHZ=$(sysctl -n hw.cpufrequency_max 2>/dev/null)
  if [ -n "$CPU_MAX_MHZ" ]; then
    CPU_MAX_MHZ=$((CPU_MAX_MHZ / 1000000))
  fi

  os="Apple"
  cpuinformation=$(echo "{\"os\": \"$os\", \"cpu_count\": \"$CPU_COUNT\", \"model_name\": \"$MODEL_NAME\", \"architecture\": \"$ARCHITECTURE\", \"vendor_id\": \"$VENDOR_ID\", \"cpu_min_mhz\": \"$CPU_MIN_MHZ\", \"cpu_max_mhz\": \"$CPU_MAX_MHZ\"}")

  echo "$cpuinformation"
}


isValidUUID() {
  local uuid=$1
  if [[ $uuid =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[4][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$ ]]; then
    return 0
  else
    return 1
  fi
}

linkDeviceAwaberryLobby() {

  # on mac work with the account name instead of user awaberry
  accountname=$(whoami)
  echo "$accountname" > "$accountnamefile"


  cpu_info=$(getCpuInformation)
  deviceuuid=$(cat "$deviceuuidfile")

  if [ -z "$deviceuuid" ]; then
    echo
    echo '####################################'
    echo '# AWABERRY LOBBY                   #'
    echo '####################################'
    echo
    echo "If not yet done, please create an account at app.awaberry.com"
    echo "Start linking a device and copy the device uuid"
    echo ""
    echo "Please paste the deviceid here:"
    read deviceuuid

    echo "validate deviceuuid $deviceuuid"
    if isValidUUID "$deviceuuid"; then
      echo "   "
      echo "Start linking the device"
    else
      echo "Invalid format for the provided device id."
      echo "Please start script again and correct the inputs"
      exit 1
    fi

    echo "valid uuid - continue with linking the device"
    # write deviceuuid to $deviceuuidfile
    echo "$deviceuuid" > "$deviceuuidfile"
  fi


  ipaddress=$(getLocalIp)
  memory=$(getMemoryTotalFile)
  response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $apiToken" -d "{\"deviceid\": \"$deviceuuid\", \"ipaddress\": \"$ipaddress\", \"cpuinfo\": $cpu_info, \"memory\": $memory}" $apiServerUrl/devicelobby_sendipandmemory)

  #echo $response
  responsecode=$(echo "$response" | jq -r '.code')
  if [ "$responsecode" = "401" ]; then
    echo "Error: Unauthorized (401). Exiting."
    exit 1
  fi

  devicecountry=$(echo "$response" | jq -r '.country')
  if [ -z "$devicecountry" ]; then
    echo "Error: device country is empty. Exiting."
    exit 1
  fi

  loadbalancertouse=$(echo "$response" | jq -r '.loadbalancertouse')
  if [ -z "$loadbalancertouse" ]; then
    echo "Error: loadbalancertouse is empty. Exiting."
    exit 1
  fi

  devicename=$(echo "$response" | jq -r '.devicename')

  useruuid=$(echo "$response" | jq -r '.useruuid')
  if [ -z "$useruuid" ]; then
    echo "Error: could not load cloud values. Stopping the script."
    exit 1
  fi
  echo "$devicecountry" > "$fileCountryCode"

  echo "$loadbalancertouse" > "$awaberryHomeDataDir/loadbalancertouse.txt"
  echo "$devicename" > "$devicenamefile"
  echo "$useruuid" > "$useruuidfile"
  echo "1" > "$deviceconnectedfile"
  echo "1" > "$deviceConnectSuccessFile"
  echo "device is now available in your device list at https://app.awaberry.com"
}


echo "check $deviceConnectSuccessFile"
if [ -f "$deviceConnectSuccessFile" ]; then
  devicename=$(cat "$devicenamefile")
  echo "device uuid is already linked with awaBerry"
  echo "You can connect to the device with the name: $devicename"
  echo "https://app.awaberry.com - login with your account and select the device to connect to it"
  devi

else
  echo "device uuid is not linked with awaBerry"
  linkDeviceAwaberryLobby



  generateCertificates
  installAwaberryClient
fi