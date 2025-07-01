# Binary Format Support (binfmt). Disable running non-native binaries
disable_binfmt_misc() {
        HARDN_STATUS "info" "Checking/Disabling non-native binary format support (binfmt_misc)..."

        # Execute each step in sequence
        unmount_binfmt_misc
        unload_binfmt_misc_module
        prevent_binfmt_misc_loading

        # Notify user of completion
        whiptail --infobox "Non-native binary format support (binfmt_misc) checked/disabled." 7 70
}

# Function to unmount binfmt_misc if it's mounted
unmount_binfmt_misc() {
        if mount | grep -q 'binfmt_misc'; then
            HARDN_STATUS "info" "binfmt_misc is mounted. Attempting to unmount..."
            if umount /proc/sys/fs/binfmt_misc; then
                HARDN_STATUS "pass" "binfmt_misc unmounted successfully."
                return 0
            else
                HARDN_STATUS "error" "Failed to unmount binfmt_misc. It might be busy or not a separate mount."
                return 1
            fi
        fi
        return 0
}

# Function to unload the binfmt_misc kernel module if it's loaded
unload_binfmt_misc_module() {
        # Check if module is not loaded - early return
        if ! lsmod | grep -q "^binfmt_misc"; then
            HARDN_STATUS "pass" "binfmt_misc module is not currently loaded."
            return 0
        fi

        # Module is loaded, attempt to unload
        HARDN_STATUS "info" "binfmt_misc module is loaded. Attempting to unload..."

        # Use proper if-then-else structure instead of && and ||
        if rmmod binfmt_misc; then
            HARDN_STATUS "pass" "binfmt_misc module unloaded successfully."
            return 0
        else
            HARDN_STATUS "error" "Failed to unload binfmt_misc module. It might be in use or built-in."
            return 1
        fi
}

# Function to prevent binfmt_misc from loading on boot
prevent_binfmt_misc_loading() {
        local modprobe_conf="/etc/modprobe.d/disable-binfmt_misc.conf"
        local rule="install binfmt_misc /bin/true"

        # Case 1: Config file doesn't exist - create it
        if [[ ! -f "$modprobe_conf" ]]; then
            echo "$rule" > "$modprobe_conf"
            HARDN_STATUS "pass" "Added modprobe rule to prevent binfmt_misc from loading on boot: $modprobe_conf"
        # Case 2: Config file exists but doesn't have our rule - append it
        elif ! grep -q "$rule" "$modprobe_conf"; then
            echo "$rule" >> "$modprobe_conf"
            HARDN_STATUS "pass" "Appended modprobe rule to prevent binfmt_misc from loading to $modprobe_conf"
        # Case 3: Config file exists and already has our rule - do nothing
        else
            HARDN_STATUS "info" "Modprobe rule to disable binfmt_misc already exists in $modprobe_conf."
        fi
        return 0
}

# Call the main function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    disable_binfmt_misc
fi

# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_binfmt() {
    HARDN_STATUS "error" "binfmt module has no main function defined"
}
