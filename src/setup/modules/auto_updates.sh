# Automatic security updates configuration module

configure_debian_updates() {
    local id="$1"
    local codename="$2"

    HARDN_STATUS "info" "Configuring Debian-specific unattended upgrades..."

    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "${id}:${codename}-security";
    "${id}:${codename}-updates";
};
Unattended-Upgrade::Package-Blacklist {
    // Add any packages you want to exclude from automatic updates
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    HARDN_STATUS "pass" "Debian unattended upgrades configured successfully."
}

# Function to configure Ubuntu-specific unattended upgrades
configure_ubuntu_updates() {
    local id="$1"
    local codename="$2"

    HARDN_STATUS "info" "Configuring Ubuntu-specific unattended upgrades..."

    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "${id}:${codename}-security";
    "${id}ESMApps:${codename}-apps-security";
    "${id}ESM:${codename}-infra-security";
};
EOF

    HARDN_STATUS "pass" "Ubuntu unattended upgrades configured successfully."
}

# Function to configure generic Debian-based unattended upgrades
configure_generic_updates() {
    local id="$1"
    local codename="$2"

    HARDN_STATUS "info" "Configuring generic Debian-based unattended upgrades..."

    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "${id}:${codename}-security";
};
EOF

    HARDN_STATUS "pass" "Generic unattended upgrades configured successfully."
}

# Function to enable unattended upgrades
enable_unattended_upgrades() {
    HARDN_STATUS "info" "Enabling unattended upgrades service..."

    cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

    # Ensure the unattended-upgrades service is enabled
    if systemctl is-enabled unattended-upgrades.service &>/dev/null; then
        HARDN_STATUS "pass" "Unattended upgrades service is already enabled."
    else
        systemctl enable unattended-upgrades.service &>/dev/null
        HARDN_STATUS "pass" "Unattended upgrades service has been enabled."
    fi
}

# Main function to configure automatic security updates
configure_auto_updates() {
    HARDN_STATUS "info" "Configuring automatic security updates for Debian-based systems..."

    # Check if ID and CURRENT_DEBIAN_CODENAME are set
    if [ -z "${ID}" ] || [ -z "${CURRENT_DEBIAN_CODENAME}" ]; then
        # Try to source os-release if variables aren't set
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            CURRENT_DEBIAN_CODENAME="${VERSION_CODENAME}"
        else
            HARDN_STATUS "error" "Could not determine OS distribution and codename."
            return 1
        fi
    fi

    # Configure distribution-specific settings
    case "${ID}" in
        "debian")
            configure_debian_updates "${ID}" "${CURRENT_DEBIAN_CODENAME}"
            ;;
        "ubuntu")
            configure_ubuntu_updates "${ID}" "${CURRENT_DEBIAN_CODENAME}"
            ;;
        *)
            # Generic Debian-based fallback
            HARDN_STATUS "warning" "Unknown distribution '${ID}', using generic configuration."
            configure_generic_updates "${ID}" "${CURRENT_DEBIAN_CODENAME}"
            ;;
    esac

    enable_unattended_upgrades

    HARDN_STATUS "pass" "Automatic security updates configuration completed."
}

configure_auto_updates

# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_auto_updates() {
    configure_debian_updates
}
