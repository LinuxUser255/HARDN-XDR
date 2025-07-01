# Disable FireWire modules and blacklist them for security
disable_firewire() {
        HARDN_STATUS "info" "Checking/Disabling FireWire (IEEE 1394) drivers..."
        local firewire_modules="firewire_core firewire_ohci firewire_sbp2"
        local changed=0

        # Unload currently loaded modules
        changed=$(unload_firewire_modules "$firewire_modules" "$changed")

        # Blacklist modules to prevent loading at boot
        changed=$(blacklist_firewire_modules "$firewire_modules" "$changed")

        # Show result notification
        display_firewire_status "$changed"

        return "$changed"
}

# Unload currently loaded FireWire modules
unload_firewire_modules() {
        local modules_array="($1)"  # Convert space-separated string to array
        local changed="$2"

        # Use C-style loop to iterate over array elements
        for((i=0; i<${#modules_array[@]}; i++)); do
            local module_name="${modules_array[i]}"

            # Check if module is loaded and handle accordingly
            if ! lsmod | grep -q "^${module_name}"; then
                HARDN_STATUS "info" "FireWire module $module_name is not currently loaded."
                continue
            fi

            # Module is loaded, attempt to unload it
            HARDN_STATUS "info" "FireWire module $module_name is loaded. Attempting to unload..."

            # Try to unload and report result
            if rmmod "$module_name"; then
                HARDN_STATUS "pass" "FireWire module $module_name unloaded successfully."
                changed=1
            else
                HARDN_STATUS "error" "Failed to unload FireWire module $module_name. It might be in use or built-in."
            fi
        done

        return "$changed"
}

# Function to blacklist FireWire modules
blacklist_firewire_modules() {
        local modules="$1"
        local changed="$2"
        local blacklist_file="/etc/modprobe.d/blacklist-firewire.conf"

        # Create blacklist file if it doesn't exist
        if [[ ! -f "$blacklist_file" ]]; then
            touch "$blacklist_file"
            HARDN_STATUS "pass" "Created FireWire blacklist file: $blacklist_file"
        fi

        # Add each module to the blacklist if not already present
        local modules_array="($modules)"  # Convert space-separated string to array

        for((i=0; i<${#modules_array[@]}; i++)); do
            local module_name="${modules_array[i]}"

            if ! grep -q "blacklist $module_name" "$blacklist_file"; then
                echo "blacklist $module_name" >> "$blacklist_file"
                HARDN_STATUS "pass" "Blacklisted FireWire module $module_name in $blacklist_file"
                changed=1
            else
                HARDN_STATUS "info" "FireWire module $module_name already blacklisted in $blacklist_file."
            fi
        done

        return "$changed"
}

# Function to display status message
display_firewire_status() {
        local changed="$1"

        if [[ "$changed" -eq 1 ]]; then
            whiptail --infobox "FireWire drivers checked. Unloaded and/or blacklisted where applicable." 7 70
        else
            whiptail --infobox "FireWire drivers checked. No changes made (likely already disabled/not present)." 8 70
        fi
}

# Execute the main function
disable_firewire

