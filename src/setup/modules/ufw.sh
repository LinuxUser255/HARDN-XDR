# Module for configuring Uncomplicated Firewall (UFW)

# Main function to configure UFW
configure_ufw() {
        HARDN_STATUS "info" "Setting up Uncomplicated Firewall (UFW)..."

        # Check if UFW is installed
        if ! command -v ufw >/dev/null 2>&1; then
            HARDN_STATUS "error" "UFW is not installed. Please install it first."
            return 1
        fi

        reset_ufw
        set_default_policies
        configure_allowed_services
        configure_logging
        enable_ufw

        HARDN_STATUS "pass" "UFW configuration completed successfully."
        return 0
}

# Reset UFW to default state
reset_ufw() {
        HARDN_STATUS "info" "Resetting UFW to default state..."
        if ufw --force reset >/dev/null 2>&1; then
            HARDN_STATUS "pass" "UFW reset successfully."
        else
            HARDN_STATUS "warning" "Failed to reset UFW. Continuing with configuration..."
        fi
}

# Set default policies
set_default_policies() {
        HARDN_STATUS "info" "Setting default UFW policies..."

        # Deny all incoming traffic by default
        if ufw default deny incoming >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Default incoming policy set to DENY."
        else
            HARDN_STATUS "error" "Failed to set default incoming policy."
            return 1
        fi

        # Allow all outgoing traffic by default
        if ufw default allow outgoing >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Default outgoing policy set to ALLOW."
        else
            HARDN_STATUS "error" "Failed to set default outgoing policy."
            return 1
        fi

        return 0
}

# Configure allowed services
configure_allowed_services() {
        HARDN_STATUS "info" "Configuring allowed services..."

        # Define an array of services to allow
        local services=(
            "ssh"           # SSH for remote administration
            "80/tcp"        # HTTP
            "443/tcp"       # HTTPS
        )

        # Allow each service using compact loop style
        for((i=0; i<${#services[@]}; i++)); do
            service="${services[$i]}"
            if ufw allow "$service" >/dev/null 2>&1; then
                HARDN_STATUS "pass" "Allowed $service."
            else
                HARDN_STATUS "warning" "Failed to allow $service."
            fi
        done
}

# Configure logging
configure_logging() {
        HARDN_STATUS "info" "Configuring UFW logging..."

        # Set logging level to medium
        if ufw logging medium >/dev/null 2>&1; then
            HARDN_STATUS "pass" "UFW logging set to medium."
        else
            HARDN_STATUS "warning" "Failed to set UFW logging level."
        fi
}

# Enable UFW and ensure it starts on boot
enable_ufw() {
        HARDN_STATUS "info" "Enabling UFW..."

        # Enable UFW
        if ufw --force enable >/dev/null 2>&1; then
            HARDN_STATUS "pass" "UFW enabled successfully."
        else
            HARDN_STATUS "error" "Failed to enable UFW."
            return 1
        fi

        # Ensure UFW starts on boot
        if systemctl enable ufw >/dev/null 2>&1; then
            HARDN_STATUS "pass" "UFW service enabled at boot."
        else
            HARDN_STATUS "warning" "Failed to enable UFW service at boot."
        fi

        return 0
}

#  main
configure_ufw


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_ufw() {
    configure_ufw
}
