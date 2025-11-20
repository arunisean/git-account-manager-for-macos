#!/bin/bash

# Installation script for Git Account Manager

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PATH="$DIR/git-credential-manager-gui.sh"

echo "Configuring Git to use the Account Manager..."
# Reset any system helpers (like osxkeychain) by adding an empty helper first
git config --global --replace-all credential.helper ""
git config --global --add credential.helper "$SCRIPT_PATH"

echo "Done! Git is now configured to use:"
echo "$SCRIPT_PATH"
echo ""
echo "Try running 'git pull' on a repository to see the account selection popup."
