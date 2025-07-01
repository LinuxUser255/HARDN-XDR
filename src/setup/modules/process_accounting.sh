# Process accounting and system statistics module

# Main function to configure process accounting and system statistics
configure_process_monitoring() {
        HARDN_STATUS "info" "Enabling process accounting (acct) and system statistics (sysstat)..."
        local changed_acct changed_sysstat
        changed_acct=false
        changed_sysstat=false

        configure_process_accounting

        configure_sysstat

        # Report final status
        if [[ "$changed_acct" = true || "$changed_sysstat" = true ]]; then
            HARDN_STATUS "pass" "Process accounting (acct) and sysstat configured successfully."
        else
            HARDN_STATUS "pass" "Process accounting (acct) and sysstat already configured or no changes needed."
        fi
}

configure_process_accounting() {
        HARDN_STATUS "info" "Checking and installing acct (process accounting)..."

        # Install acct if not present
        if ! is_package_installed "acct" && ! is_package_installed "psacct"; then
            install_acct_package
        else
            HARDN_STATUS "info" "acct/psacct is already installed."
        fi

        # Enable and start acct service if installed
        if is_package_installed "acct" || is_package_installed "psacct"; then
            enable_acct_service
        fi
}

is_package_installed() {
        dpkg -s "$1" >/dev/null 2>&1
}

install_acct_package() {
        whiptail --infobox "Installing acct (process accounting)..." 7 60
        if atp install -y acct; then
            HARDN_STATUS "pass" "acct installed successfully."
            changed_acct=true
        else
            HARDN_STATUS "error" "Failed to install acct. Please check manually."
        fi
}

enable_acct_service() {
        if ! systemctl is-active --quiet acct && ! systemctl is-active --quiet psacct; then
            HARDN_STATUS "info" "Attempting to enable and start acct/psacct service..."
            systemctl enable --now acct 2>/dev/null || systemctl enable --now psacct 2>/dev/null
            HARDN_STATUS "pass" "acct/psacct service enabled and started."
            changed_acct=true
        else
            HARDN_STATUS "pass" "acct/psacct service is already active."
        fi
}

configure_sysstat() {
        HARDN_STATUS "info" "Checking and installing sysstat..."

        # Install sysstat if not present
        if ! is_package_installed "sysstat"; then
            install_sysstat_package
        else
            HARDN_STATUS "info" "sysstat is already installed."
        fi

        # Configure and enable sysstat if installed
        if is_package_installed "sysstat"; then
            configure_sysstat_settings
            enable_sysstat_service
        fi
}

install_sysstat_package() {
        whiptail --infobox "Installing sysstat..." 7 60
        if atp install -y sysstat; then
            HARDN_STATUS "pass" "sysstat installed successfully."
            changed_sysstat=true
        else
            HARDN_STATUS "error" "Failed to install sysstat. Please check manually."
        fi
}

configure_sysstat_settings() {
        local sysstat_conf="/etc/default/sysstat"

        # Early return if config file doesn't exist
        if [[ ! -f "$sysstat_conf" ]]; then
            HARDN_STATUS "warning" "sysstat configuration file $sysstat_conf not found. Manual check might be needed."
            return
        fi

        # Check if already enabled
        if grep -qE '^\s*ENABLED="true"' "$sysstat_conf"; then
            HARDN_STATUS "pass" "sysstat data collection is already enabled in $sysstat_conf."
            return
        fi

        HARDN_STATUS "info" "Enabling sysstat data collection in $sysstat_conf..."

        # Replace ENABLED="false" with ENABLED="true" if it exists
        sed -i 's/^\s*ENABLED="false"/ENABLED="true"/' "$sysstat_conf"

        grep -qE '^\s*ENABLED=' "$sysstat_conf" || echo 'ENABLED="true"' >> "$sysstat_conf"

        changed_sysstat=true
        HARDN_STATUS "pass" "sysstat data collection enabled."
}

enable_sysstat_service() {
        # Check if service is already active
        if systemctl is-active --quiet sysstat; then
            HARDN_STATUS "pass" "sysstat service is already active."
            return
        fi

        # Service not active, attempt to enable and start
        HARDN_STATUS "info" "Attempting to enable and start sysstat service..."

        # Use && to simplify success path and avoid nesting
        systemctl enable --now sysstat && {
            HARDN_STATUS "pass" "sysstat service enabled and started."
            changed_sysstat=true
            return
        }

        # If we reach here, the command failed
        HARDN_STATUS "error" "Failed to enable/start sysstat service."
}

configure_process_monitoring


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_process_accounting() {
    configure_process_monitoring
}
