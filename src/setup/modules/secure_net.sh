# Module for configuring secure network parameters

configure_secure_network() {
        HARDN_STATUS "info" "Configuring secure network parameters..."

        # Create a temporary file for our sysctl settings
        local temp_sysctl_file
        temp_sysctl_file=$(mktemp)

        generate_secure_network_params > "$temp_sysctl_file"
        apply_sysctl_settings "$temp_sysctl_file"
        # Clean up
        rm -f "$temp_sysctl_file"
        HARDN_STATUS "pass" "Secure network parameters configured successfully."
}

generate_secure_network_params() {
    cat << EOF
# IPv4 forwarding (disable unless needed for routing)
net.ipv4.ip_forward = 0

# ICMP redirects (prevent MITM attacks)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Protect against broadcast attacks
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
}

apply_sysctl_settings() {
        local sysctl_file="$1"

        # Check if the file exists
        if [[ ! -f "$sysctl_file" ]]; then
            HARDN_STATUS "error" "Error: Sysctl settings file not found."
            return 1
        fi

        # Backup original sysctl.conf if it exists
        if [[ -f /etc/sysctl.conf ]]; then
            cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
            HARDN_STATUS "info" "Backed up original sysctl.conf to /etc/sysctl.conf.bak"
        fi

        # Check for duplicate entries and append new settings
        local param value
        while IFS='=' read -r param value; do
            param=$(echo "$param" | xargs)  # Trim whitespace
            value=$(echo "$value" | xargs)  # Trim whitespace

            # Skip empty lines
            [[ -z "$param" ]] && continue

            # Remove existing setting if present
            if grep -q "^$param\s*=" /etc/sysctl.conf 2>/dev/null; then
                sed -i "/^$param\s*=/d" /etc/sysctl.conf
            fi
        done < "$sysctl_file"

        # Append all settings to sysctl.conf
        cat "$sysctl_file" >> /etc/sysctl.conf

        # Apply settings immediately
        sysctl -p >/dev/null 2>&1 || {
            HARDN_STATUS "warning" "Warning: Some sysctl parameters may not have been applied."
        }
}

# Call the main function
configure_secure_network

# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_secure_net() {
    configure_secure_network
}
