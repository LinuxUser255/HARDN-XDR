# Module for installing and configuring Suricata IDS/IPS

# Main function to orchestrate Suricata setup
setup_suricata() {
        HARDN_STATUS "info" "Checking and configuring Suricata..."

        # Check if Suricata is already installed
        if is_suricata_installed; then
            HARDN_STATUS "pass" "Suricata package is already installed."
        else
            # Try to install Suricata from source
            install_suricata_from_source || return 1
        fi

        # Configure Suricata if it's installed
        if command -v suricata >/dev/null 2>&1; then
            configure_suricata || return 1
            update_suricata_rules
            manage_suricata_service
        else
            HARDN_STATUS "error" "Suricata command not found after installation attempt, skipping configuration."
            return 1
        fi
}

# Check if Suricata is already installed
is_suricata_installed() {
        dpkg -s suricata >/dev/null 2>&1
}

# Install Suricata from source
install_suricata_from_source() {
        HARDN_STATUS "info" "Suricata package not found. Attempting to install from source..."

        local suricata_version="7.0.0"
        local download_url="https://www.suricata-ids.org/download/releases/suricata-${suricata_version}.tar.gz"
        local download_dir="/tmp/suricata_install"
        local tar_file="$download_dir/suricata-${suricata_version}.tar.gz"
        local extracted_dir="suricata-${suricata_version}"

        # Install dependencies
        install_build_dependencies || return 1

        # Create download directory
        mkdir -p "$download_dir"
        cd "$download_dir" || {
            HARDN_STATUS "error" "Error: Cannot change directory to $download_dir."
            return 1
        }

        # Download, extract, and build
        download_suricata "$download_url" "$tar_file" || {
            cleanup "$download_dir"
            return 1
        }

        extract_tarball "$tar_file" "$download_dir" || {
            cleanup "$download_dir"
            return 1
        }

        build_and_install_suricata "$download_dir/$extracted_dir" || {
            cleanup "$download_dir"
            return 1
        }

        # Clean up
        cleanup "$download_dir"
        return 0
}

# Install build dependencies
install_build_dependencies() {
        HARDN_STATUS "info" "Installing Suricata build dependencies..."
        if ! apt update >/dev/null 2>&1 || ! apt install -y \
            build-essential libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev \
            libcap-ng-dev libmagic-dev libjansson-dev libnss3-dev liblz4-dev libtool \
            libnfnetlink-dev libevent-dev pkg-config libhiredis-dev libczmq-dev \
            python3 python3-yaml python3-setuptools python3-pip python3-dev \
            rustc cargo >/dev/null 2>&1; then
            HARDN_STATUS "error" "Error: Failed to install Suricata build dependencies."
            return 1
        fi
        HARDN_STATUS "pass" "Suricata build dependencies installed."
        return 0
}

# Download Suricata source
download_suricata() {
        local url="$1"
        local output_file="$2"

        HARDN_STATUS "info" "Downloading ${url}..."
        if wget -q "$url" -O "$output_file"; then
            HARDN_STATUS "pass" "Download successful."
            return 0
        else
            HARDN_STATUS "error" "Error: Failed to download $url."
            return 1
        fi
}

# Extract tarball
extract_tarball() {
        local tarball="$1"
        local extract_dir="$2"

        HARDN_STATUS "info" "Extracting..."
        if tar -xzf "$tarball" -C "$extract_dir"; then
            HARDN_STATUS "pass" "Extraction successful."
            return 0
        else
            HARDN_STATUS "error" "Error: Failed to extract $tarball."
            return 1
        fi
}

# Build and install Suricata
build_and_install_suricata() {
        local build_dir="$1"

        if [[ ! -d "$build_dir" ]]; then
            HARDN_STATUS "error" "Error: Build directory not found."
            return 1
        fi

        cd "$build_dir" || {
            HARDN_STATUS "error" "Error: Cannot change directory to build folder."
            return 1
        }

        # Configure
        HARDN_STATUS "info" "Running ./configure..."
        if ! ./configure \
            --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --disable-gccmarch-native \
            --enable-lua \
            --enable-geoip \
            > /dev/null 2>&1; then
            HARDN_STATUS "error" "Error: ./configure failed."
            return 1
        fi
        HARDN_STATUS "pass" "Configure successful."

        # Make
        HARDN_STATUS "info" "Running make..."
        if ! make > /dev/null 2>&1; then
            HARDN_STATUS "error" "Error: make failed."
            return 1
        fi
        HARDN_STATUS "pass" "Make successful."

        # Install
        HARDN_STATUS "info" "Running make install..."
        if ! make install > /dev/null 2>&1; then
            HARDN_STATUS "error" "Error: make install failed."
            return 1
        fi
        HARDN_STATUS "pass" "Suricata installed successfully from source."

        # Update shared library cache
        ldconfig >/dev/null 2>&1 || true

        return 0
}

# Clean up temporary files
cleanup() {
        local dir_to_remove="$1"
        cd /tmp || true
        rm -rf "$dir_to_remove"
}

# Configure Suricata
configure_suricata() {
        HARDN_STATUS "info" "Configuring Suricata..."

        # Ensure configuration directory exists
        if [ ! -d /etc/suricata ]; then
            HARDN_STATUS "info" "Creating /etc/suricata directory..."
            mkdir -p /etc/suricata
        fi

        # Check for configuration file
        if [ ! -f /etc/suricata/suricata.yaml ]; then
            HARDN_STATUS "error" "Error: Suricata default configuration file not found. Skipping configuration."
            return 1
        fi

        return 0
}

# Update Suricata rules with reduced nesting
update_suricata_rules() {
        HARDN_STATUS "info" "Running suricata-update..."

        # Check if suricata-update is available, install if needed
        ensure_suricata_update_installed || return 1

        # Run the update if the command is available
        run_suricata_update
}

# Ensure suricata-update is installed
ensure_suricata_update_installed() {
        # Skip if already installed
        command -v suricata-update >/dev/null 2>&1 && return 0

        # Not installed, try to install it
        HARDN_STATUS "info" "suricata-update command not found. Attempting to install..."

        if pip3 install --upgrade pip >/dev/null 2>&1 &&
           pip3 install --upgrade suricata-update >/dev/null 2>&1; then
            HARDN_STATUS "pass" "suricata-update installed successfully via pip3."
            return 0
        else
            HARDN_STATUS "error" "Error: Failed to install suricata-update via pip3. Skipping rule update."
            return 1
        fi
}

# Run suricata-update if available
run_suricata_update() {
        # Check again if command is available (could have been installed above)
        if ! command -v suricata-update >/dev/null 2>&1; then
            HARDN_STATUS "error" "suricata-update command not available, skipping rule update."
            return 1
        fi

        # Run the update
        if suricata-update >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Suricata rules updated successfully."
            return 0
        else
            HARDN_STATUS "warning" "Warning: Suricata rules update failed. Check output manually."
            return 1
        fi
}

# Manage Suricata service
manage_suricata_service() {
        # Enable service
        HARDN_STATUS "info" "Enabling Suricata service..."
        if systemctl enable suricata >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Suricata service enabled successfully."
        else
            HARDN_STATUS "error" "Failed to enable Suricata service. Check if the service file exists."
            return 1
        fi

        # Start service
        HARDN_STATUS "info" "Starting Suricata service..."
        if systemctl start suricata >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Suricata service started successfully."
        else
            HARDN_STATUS "error" "Failed to start Suricata service. Check logs for details."
            return 1
        fi

    return 0
}

# Execute the main function
setup_suricata


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_suricata() {
    setup_suricata
}
