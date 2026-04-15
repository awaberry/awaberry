#!/bin/bash

echo installer for awaberry client on MAC


if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
  echo "Installation command on terminal:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# check if ssh to localhost is enabled
if ssh -o BatchMode=yes -o ConnectTimeout=5 localhost 'exit' 2>&1 | grep -qi 'refused'; then
  echo "SSH to localhost failed."
  echo "Please ensure that remote login is enabled in System Preferences > Sharing."
  echo "See https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac"
  echo ""
  echo "Note that it is sufficient to have ssh from machine to localhost working, i.e. sshd-client in firewall can be set to 'block incoming connections'."
  exit 1
else
  echo "SSH to localhost works - may continue."
fi

echo "update brew"
brew update

echo "1) adding the awaberry tap"
brew tap awaberry/awaberry

echo "2) installing awaberry"
# The short name 'awaberry' works once the tap is added above.
# post_install inside the formula will automatically run the client
# installer and start the background service.
brew install awaberry

echo "3) starting the awaberry service"
brew services start awaberry

echo ""
echo "Installation complete."
echo "The awaberry service is running and will start automatically on login/reboot."
echo ""
echo "To manage the service:"
echo "  brew services start awaberry"
echo "  brew services stop  awaberry"
echo "  brew services list"
