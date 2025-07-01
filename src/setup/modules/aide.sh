# Advanced Intrusion Detection Environment
install_and_configure_aide() {
        if dpkg -s aide >/dev/null 2>&1; then
            HARDN_STATUS "warning" "AIDE already installed, skipping configuration..."
            return 0
        fi

        HARDN_STATUS "info" "Installing and configuring AIDE..."
        apt install -y aide >/dev/null 2>&1

        if [[ ! -f "/etc/aide/aide.conf" ]]; then
            HARDN_STATUS "error" "AIDE install failed, /etc/aide/aide.conf not found"
            return 1
        fi

        HARDN_STATUS "info" "Initializing AIDE database (this may take several minutes)..."
        aideinit >/dev/null 2>&1 || true
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db >/dev/null 2>&1 || true

        # Schedule daily checks at 5 AM
        echo "0 5 * * * root /usr/bin/aide --check" >> /etc/crontab

        HARDN_STATUS "pass" "AIDE installed and configured successfully"
        return 0
}

# Do NOT call the function here - it will be called from hardn-main.sh
