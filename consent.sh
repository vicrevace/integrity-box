#!/bin/sh

# Configuration
TIMEOUT=10
FLAG_DIR="/data/adb/Box-Brain"
CONFIG_FILE="/sdcard/config.md"

# Logger
LOGFILE="/data/adb/Box-Brain/Integrity-Box-Logs/consent.log"
log() {
    echo "$1"
    echo "$(date '+%H:%M:%S') $1" >> "$LOGFILE"
}

# Config File Parser
read_config() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(grep -m 1 "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' \r')
        if [ "$value" = "1" ] || [ "$value" = "0" ]; then
            echo "$value"
            return
        fi
    fi
    echo " "
}

# Core Volume Key Function
get_key() {
    local timeout="$1"
    if [ -z "$timeout" ]; then
        timeout=$TIMEOUT
    fi

    local start_time
    start_time=$(date +%s)
    local tmpfile="/dev/.volkey_$$"

    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $timeout ]; then
            rm -f "$tmpfile"
            echo "TIMEOUT"
            return
        fi

        /system/bin/getevent -lc 1 2>&1 > "$tmpfile"

        if /system/bin/grep -q "VOLUME" "$tmpfile" 2>/dev/null; then
            if /system/bin/grep -q "VOLUMEUP" "$tmpfile" 2>/dev/null; then
                rm -f "$tmpfile"
                echo "UP"
                return
            elif /system/bin/grep -q "VOLUMEDOWN" "$tmpfile" 2>/dev/null; then
                rm -f "$tmpfile"
                echo "DOWN"
                return
            fi
        fi

        rm -f "$tmpfile"
    done
}

# Helper function 
ask_question() {
    local timeout="${1:-$TIMEOUT}"
    local config_key="$2"

    local config_value
    config_value=$(read_config "$config_key")

    if [ "$config_value" = "1" ]; then
        echo "UP"
        return
    elif [ "$config_value" = "0" ]; then
        echo "DOWN"
        return
    fi

    local key
    key=$(get_key "$timeout")

    if [ "$key" = "TIMEOUT" ]; then
        echo "$(date '+%H:%M:%S') Timeout -> DOWN" >> "$LOGFILE"
        key="DOWN"
    else
        echo "$(date '+%H:%M:%S') Selected: $key" >> "$LOGFILE"
    fi

    echo "$key"
}

# Flag Management Helpers
set_flag() {
    local flag_name="$1"
    touch "$FLAG_DIR/$flag_name"
    echo "$(date '+%H:%M:%S') Flag set: $flag_name" >> "$LOGFILE"
}

clear_flag() {
    local flag_name="$1"
    rm -f "$FLAG_DIR/$flag_name"
    echo "$(date '+%H:%M:%S') Flag cleared: $flag_name" >> "$LOGFILE"
}

spoof_security_patch() {
    echo " "
    echo " ______________________________"
    echo "   𝗦𝗽𝗼𝗼𝗳 𝗔𝗻𝗱𝗿𝗼𝗶𝗱 𝗦𝗲𝗰𝘂𝗿𝗶𝘁𝘆 𝗣𝗮𝘁𝗰𝗵 "
    echo " ______________________________"
    echo " "
    echo "  Allows the module to override the"
    echo "  reported Android security patch date"
    echo "  when required."
    echo " "
    echo "  ➕ Volume Up   : Enable Patch Spoofing"
    echo "  ➖ Volume Down : Use Actual Patch Level"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "spoof_security_patch")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Security patch spoofing enabled"
            clear_flag "skip"
            ;;
        DOWN|*)
            echo "  💅  Using actual security patch level"
            set_flag "skip"
            ;;
    esac
}

disable_rom_spoofing() {
    echo " "
    echo " ___________________________________"
    echo "   𝗗𝗶𝘀𝗮𝗯𝗹𝗲 𝗥𝗢𝗠 𝗦𝗽𝗼𝗼𝗳𝗶𝗻𝗴"
    echo " ___________________________________"
    echo " "
    echo "  This is for custom ROM users"
    echo "  useful for ROMs that don't give you"
    echo "  option to disable inbuilt spoofing."
    echo " "
    echo "  ➕ Volume Up   : Disable"
    echo "  ➖ Volume Down : Leave Unchanged"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "disable_rom_spoofing")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Disabled inbuilt spoofing"
            set_flag "disablegms"
            set_flag "disablevending"
            ;;
        DOWN|*)
            echo "  💅  Skipped"
            clear_flag "disablegms"
            clear_flag "disablevending"
            ;;
    esac
}

spoof_encryption() {
    echo " "
    echo " ____________________________"
    echo "   𝗦𝗽𝗼𝗼𝗳 𝗘𝗻𝗰𝗿𝘆𝗽𝘁𝗶𝗼𝗻 𝗦𝘁𝗮𝘁𝘂𝘀  "
    echo " ____________________________"
    echo " "
    echo "  Reports the device as encrypted when"
    echo "  apps check encryption-related system"
    echo "  properties."
    echo " "
    echo "  ➕ Volume Up   : Enable Encryption Spoofing"
    echo "  ➖ Volume Down : Use Actual Encryption Status"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "spoof_encryption")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Encryption status spoofed"
            set_flag "encrypt"
            ;;
        DOWN|*)
            echo "  💅  Using actual encryption status"
            clear_flag "encrypt"
            ;;
    esac
}

spoof_custom_rom_props() {
    echo " "
    echo " _________________________________"
    echo "   𝗖𝘂𝘀𝘁𝗼𝗺 𝗥𝗢𝗠 𝗣𝗿𝗼𝗽𝗲𝗿𝘁𝘆 𝗦𝗽𝗼𝗼𝗳𝗶𝗻𝗴 "
    echo " _________________________________"
    echo " "
    echo "  Hides properties used to detect custom"
    echo "  ROMs such as LineageOS."
    echo " "
    echo "  ⚠️  Warning: May prevent OTA updates!"
    echo " "
    echo "  ➕ Volume Up   : Enable Spoofing"
    echo "  ➖ Volume Down : Keep OTA Compatibility"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 10 "spoof_custom_rom_props")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Custom ROM detection spoofed"
            clear_flag "safemode"
            clear_flag "ota"
            set_flag "NoLineageProp"
            ;;
        DOWN|*)
            echo "  💅  OTA compatibility preserved"
            rm -f "/data/adb/modules/playintegrityfix/system.prop"
            clear_flag "NoLineageProp"
            clear_flag "override"
            set_flag "ota"
            set_flag "safemode"
            ;;
    esac
}

spoof_debug_fingerprint() {
    echo " "
    echo " ______________________________"
    echo "   𝗦𝗮𝗻𝗶𝘁𝗶𝘇𝗲 𝗗𝗲𝗯𝘂𝗴 𝗙𝗶𝗻𝗴𝗲𝗿𝗽𝗿𝗶𝗻𝘁"
    echo " ______________________________"
    echo " "
    echo "  Removes debug indicators from the device"
    echo "  fingerprint that may affect integrity"
    echo "  checks."
    echo " "
    echo "  ➕ Volume Up   : Sanitize Fingerprint"
    echo "  ➖ Volume Down : Leave Unchanged"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "spoof_debug_fingerprint")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Fingerprint sanitized"
            set_flag "nodebug"
            ;;
        DOWN|*)
            echo "  💅  Skipped"
            clear_flag "nodebug"
            ;;
    esac
}

spoof_debug_build() {
    echo " "
    echo " ___________________________________"
    echo "   𝗦𝗮𝗻𝗶𝘁𝗶𝘇𝗲 𝗗𝗲𝗯𝘂𝗴 𝗕𝘂𝗶𝗹𝗱 𝗣𝗿𝗼𝗽𝗲𝗿𝘁𝗶𝗲𝘀"
    echo " ___________________________________"
    echo " "
    echo "  Removes development-related build"
    echo "  properties detected by security and"
    echo "  integrity checks."
    echo " "
    echo "  ➕ Volume Up   : Sanitize Build Properties"
    echo "  ➖ Volume Down : Leave Unchanged"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "spoof_debug_build")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Build properties sanitized"
            set_flag "build"
            ;;
        DOWN|*)
            echo "  💅  Skipped"
            clear_flag "build"
            ;;
    esac
}

spoof_debug_tag() {
    echo " "
    echo " ___________________________"
    echo "   𝗦𝗽𝗼𝗼𝗳 𝗗𝗲𝗯𝘂𝗴 𝗕𝘂𝗶𝗹𝗱 𝗧𝗮𝗴𝘀"
    echo " ___________________________"
    echo " "
    echo "  Converts debug tags (test-keys,"
    echo "  dev-keys) into production-style values."
    echo " "
    echo "  ➕ Volume Up   : Replace Tags"
    echo "  ➖ Volume Down : Leave Unchanged"
    echo "  ⏱️  Default     : Volume Down (${TIMEOUT}s)"
    echo " "

    local choice
    choice=$(ask_question 8 "spoof_debug_tag")

    echo " "
    case "$choice" in
        UP)
            echo "  ✅ Build tags sanitized"
            set_flag "tag"
            ;;
        DOWN|*)
            echo "  💅  Skipped"
            clear_flag "tag"
            ;;
    esac
}

# MAIN INSTALLER FLOW
main_installer() {
    echo " "
    echo "**************************************"
    echo "     Integrity Box Configuration "
    echo "**************************************"
    echo " "

    if [ -f "$CONFIG_FILE" ]; then
        echo "  × 𝙲𝚘𝚗𝚏𝚒𝚐 𝚏𝚒𝚕𝚎 𝚍𝚎𝚝𝚎𝚌𝚝𝚎𝚍: $CONFIG_FILE"
        echo "  × 𝚁𝚎𝚊𝚍𝚒𝚗𝚐 𝚌𝚘𝚗𝚏𝚒𝚐𝚞𝚛𝚊𝚝𝚒𝚘𝚗 𝚟𝚊𝚕𝚞𝚎𝚜..."
        echo " "
    fi

    spoof_security_patch
    disable_rom_spoofing
    spoof_encryption
    spoof_custom_rom_props
    spoof_debug_fingerprint
    spoof_debug_build
    spoof_debug_tag

    echo " "
    echo "**************************************"
    echo "      Configuration Complete!"
    echo "**************************************"
    echo " "
}

main_installer
