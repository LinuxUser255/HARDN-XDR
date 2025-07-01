# HARDN-XDR USB Security Configuration

# Configure USB security policies through modprobe
configure_usb_modprobe() {
    cat > /etc/modprobe.d/99-usb-storage.conf << 'EOF'
blacklist usb-storage
blacklist uas          # Block USB Attached SCSI (another storage protocol)

EOF
    HARDN_STATUS "info" "USB security policy configured to allow HID devices but block storage."
}

# Configure USB security through udev rules
configure_usb_udev_rules() {
    cat > /etc/udev/rules.d/99-usb-storage.rules << 'EOF'
# Block USB storage devices while allowing keyboards and mice
ACTION=="add", SUBSYSTEMS=="usb", ATTRS{bInterfaceClass}=="08", RUN+="/bin/sh -c 'echo 0 > /sys$DEVPATH/authorized'"
# Interface class 08 is for mass storage
# Interface class 03 is for HID devices (keyboards, mice) - these remain allowed
EOF
    HARDN_STATUS "info" "Additional udev rules created for USB device control."
}

# Reload udev rules to apply changes
reload_udev_rules() {
        if udevadm control --reload-rules && udevadm trigger; then
            HARDN_STATUS "pass" "Udev rules reloaded successfully."
        else
            HARDN_STATUS "error" "Failed to reload udev rules."
        fi
}

# Check and unload USB storage module if loaded
manage_usb_storage_module() {
    # Check if module exists
    if ! lsmod | grep -q "usb_storage"; then
        HARDN_STATUS "pass" "usb-storage module is not loaded, no need to unload."
        return 0
    fi

    # Module is loaded, attempt to unload it
    HARDN_STATUS "info" "usb-storage module is currently loaded, attempting to unload..."

    # Try to unload and report result
    if rmmod usb_storage >/dev/null 2>&1; then
        HARDN_STATUS "pass" "Successfully unloaded usb-storage module."
    else
        HARDN_STATUS "error" "Failed to unload usb-storage module. It may be in use."
    fi
}

# Ensure USB HID module is loaded for keyboards and mice
ensure_usb_hid_module() {
    # Check if HID module is already loaded
    if lsmod | grep -q "usbhid"; then
        HARDN_STATUS "pass" "USB HID module is loaded - keyboards and mice will work."
        return 0
    fi

    # Module not loaded, attempt to load it
    HARDN_STATUS "warning" "USB HID module is not loaded - attempting to load it..."

    # Try to load the module and report result
    if modprobe usbhid; then
        HARDN_STATUS "pass" "Successfully loaded USB HID module."
    else
        HARDN_STATUS "error" "Failed to load USB HID module."
    fi
}

# Main function to orchestrate USB security configuration
configure_usb_security() {

        configure_usb_modprobe
        configure_usb_udev_rules
        reload_udev_rules
        manage_usb_storage_module
        ensure_usb_hid_module

        HARDN_STATUS "pass" "USB configuration complete: keyboards and mice allowed, storage blocked."
}


