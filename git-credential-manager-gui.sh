#!/bin/bash

# Git Credential Helper - macOS GUI Version
# Uses 'security' for Keychain access and 'osascript' for GUI.

# Read stdin into variables
while IFS= read -r line; do
    [[ -z "$line" ]] && break
    if [[ "$line" == *"="* ]]; then
        key=${line%%=*}
        value=${line#*=}
        case "$key" in
            protocol) protocol="$value" ;;
            host) host="$value" ;;
            path) path="$value" ;;
            username) username="$value" ;;
            password) password="$value" ;;
            # Ignore capability[], wwwauth[], etc.
            *) ;;
        esac
    fi
done

# Service name strategy: git:<host>
SERVICE="git:${host:-unknown}"

echo "$(date) - Called with cmd: $1, host: $host, username: $username" >> /tmp/git-helper.log

cmd="$1"

case "$cmd" in
    get)
        # Find existing accounts
        DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        HELPER="$DIR/keychain_helper"
        
        ACCOUNTS=$("$HELPER" "$SERVICE")
        
        # Convert newline separated accounts to AppleScript list format: "acc1", "acc2"
        # and add "Add New Account..."
        
        IFS=$'\n' read -rd '' -a ACC_ARRAY <<< "$ACCOUNTS"
        
        APPLESCRIPT_LIST=""
        for acc in "${ACC_ARRAY[@]}"; do
            if [[ -n "$acc" ]]; then
                APPLESCRIPT_LIST="$APPLESCRIPT_LIST\"$acc\", "
            fi
        done
        APPLESCRIPT_LIST="${APPLESCRIPT_LIST}\"Add New Account...\""
        
        # AppleScript to choose account
        RESULT=$(osascript -e "choose from list {$APPLESCRIPT_LIST} with title \"Git Account Manager\" with prompt \"Select account for $host:\" default items {\"Add New Account...\"}" 2>/dev/null)
        
        if [[ "$RESULT" == "false" ]]; then
            # Cancelled
            exit 0
        fi
        
        if [[ "$RESULT" == "Add New Account..." ]]; then
            # Prompt for new credentials
            USERNAME=$(osascript -e 'text returned of (display dialog "Enter Username:" default answer "" with title "Add New Account" with icon note)' 2>/dev/null)
            [ -z "$USERNAME" ] && exit 0
            
            PASSWORD=$(osascript -e 'text returned of (display dialog "Enter Password / Token:" default answer "" with title "Add New Account" with icon caution with hidden answer)' 2>/dev/null)
            [ -z "$PASSWORD" ] && exit 0
            
            echo "username=$USERNAME"
            echo "password=$PASSWORD"
            
            # We should probably store it immediately? 
            # Git will call 'store' command if authentication succeeds. 
            # But if we return it here, Git uses it.
            # If we want to persist it *now*, we can. But better to let Git call 'store'.
            # However, if we don't store it, next time it won't be in the list.
            # The 'store' command is only called if the credential was successfully used.
            # So we rely on Git calling 'store'.
            
        else
            # Existing account selected
            USERNAME="$RESULT"
            # Get password from keychain
            PASSWORD=$(security find-generic-password -s "$SERVICE" -a "$USERNAME" -w 2>/dev/null)
            
            echo "username=$USERNAME"
            echo "password=$PASSWORD"
        fi
        ;;
        
    store)
        if [[ -n "$username" && -n "$password" ]]; then
            # -U = update if exists
            security add-generic-password -s "$SERVICE" -a "$username" -w "$password" -U
        fi
        ;;
        
    erase)
        if [[ -n "$username" ]]; then
            security delete-generic-password -s "$SERVICE" -a "$username"
        fi
        ;;
esac
