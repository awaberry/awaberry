#!/bin/bash

echo installer for awaberry client on MAC


if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
  echo "Installation command on terminal:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# check if ssh to localhost is enablesd
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

cd $HOME/Downloads
mkdir awaberryinstall
cd awaberryinstall

echo "1) downloading the awaberry.rb installation scripts"
curl -s https://raw.githubusercontent.com/awaberry/awaberry/main/connect/mac/awaberry.rb -o awaberry.rb
curl -s https://raw.githubusercontent.com/awaberry/awaberry/main/connect/mac/macbrewinstaller.sh -o macbrewinstaller.sh

echo "2) installing the awaberry.rb script"
brew install awaberry/awaberry/awaberry

echo "3) installing the awaberry client"
chmod +x macbrewinstaller.sh
./macbrewinstaller.sh

echo ""
echo "4) installation complete."



