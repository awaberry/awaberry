#!/bin/bash

echo installer for awaberry client on MAC


if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
  echo "Installation command on terminal:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

echo "1) downloading the awaberry.rb script"
curl -s https://raw.githubusercontent.com/awaberry/awaberry/awaberry.rb -o awaberry.rb

echo "2) installing the awaberry.rb script"
brew reinstall --build-from-source ./awaberry.rb

echo "3) installing the awaberry client"
./macbrewinstaller.sh




