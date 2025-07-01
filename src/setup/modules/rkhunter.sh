# Module for installing and configuring rkhunter (Rootkit Hunter)

# Main function to orchestrate rkhunter setup
setup_rkhunter() {
        HARDN_STATUS "info" "Configuring rkhunter..."

        install_rkhunter_if_needed

        configure_rkhunter_if_available
}

install_rkhunter_if_needed() {
        # Skip if already installed
        if dpkg -s rkhunter >/dev/null 2>&1; then
            HARDN_STATUS "pass" "rkhunter package is already installed."
            return 0
        fi

        # Try to install via apt
        HARDN_STATUS "info" "rkhunter package not found. Attempting to install via apt..."
        if apt-get install -y rkhunter >/dev/null 2>&1; then
            HARDN_STATUS "pass" "rkhunter installed successfully via apt."
            return 0
        fi

        # Fallback to GitHub installation
        HARDN_STATUS "warning" "Warning: Failed to install rkhunter via apt. Attempting to download and install from GitHub as a fallback..."
        install_rkhunter_from_github
}

install_rkhunter_from_github() {
        if ! ensure_git_installed; then
            return 1
        fi

        local original_dir
        original_dir=$(pwd)

        # Change to /tmp directory
        cd /tmp || {
            HARDN_STATUS "error" "Error: Cannot change directory to /tmp."
            return 1
        }

        # Clone repository
        HARDN_STATUS "info" "Cloning rkhunter from GitHub..."
        if ! git clone https://github.com/Rootkit-Hunter/rkhunter.git rkhunter_github_clone >/dev/null 2>&1; then
            HARDN_STATUS "error" "Error: Failed to clone rkhunter from GitHub."
            cd "$original_dir" || true
            return 1
        fi

        # Run installer
        cd rkhunter_github_clone || {
            HARDN_STATUS "error" "Error: Cannot change directory to rkhunter_github_clone."
            cd "$original_dir" || true
            rm -rf /tmp/rkhunter_github_clone
            return 1
        }

        HARDN_STATUS "info" "Running rkhunter installer..."
        if ./installer.sh --install >/dev/null 2>&1; then
            HARDN_STATUS "pass" "rkhunter installed successfully from GitHub."
        else
            HARDN_STATUS "error" "Error: rkhunter installer failed."
        fi

        # Clean up
        cd /tmp || true
        rm -rf rkhunter_github_clone
        cd "$original_dir" || true
}

ensure_git_installed() {
        if command -v git >/dev/null 2>&1; then
            return 0
        fi

        HARDN_STATUS "info" "Installing git..."
        if apt-get install -y git >/dev/null 2>&1; then
            return 0
        fi

        HARDN_STATUS "error" "Error: Failed to install git. Cannot proceed with GitHub install."
        return 1
}

configure_rkhunter_if_available() {
        if ! command -v rkhunter >/dev/null 2>&1; then
            HARDN_STATUS "warning" "Warning: rkhunter not found, skipping configuration."
            return 1
        fi

        # Create config file if it doesn't exist
        test -e /etc/default/rkhunter || touch /etc/default/rkhunter

        # Enable daily cron job
        sed -i 's/#CRON_DAILY_RUN=""/CRON_DAILY_RUN="true"/' /etc/default/rkhunter 2>/dev/null || true

        run_rkhunter_updates
}

run_rkhunter_updates() {
        rkhunter --configcheck >/dev/null 2>&1 || true

        rkhunter --update --nocolors >/dev/null 2>&1 || {
            HARDN_STATUS "warning" "Warning: Failed to update rkhunter database."
        }

        rkhunter --propupd --nocolors >/dev/null 2>&1 || {
            HARDN_STATUS "warning" "Warning: Failed to update rkhunter properties."
        }
}

setup_rkhunter


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_rkhunter() {
    setup_rkhunter
}
