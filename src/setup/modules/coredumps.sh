disable_core_dumps() {
        HARDN_STATUS "info" "Disabling core dumps..."

        # Configure limits.conf to prevent core dumps
        if ! grep -q "hard core" /etc/security/limits.conf; then
            echo "* hard core 0" >> /etc/security/limits.conf
        fi

        # Configure sysctl settings for core dumps
        if ! grep -q "fs.suid_dumpable" /etc/sysctl.conf; then
            echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
        fi

        if ! grep -q "kernel.core_pattern" /etc/sysctl.conf; then
            echo "kernel.core_pattern = /dev/null" >> /etc/sysctl.conf
        fi

        # Apply sysctl changes
        sysctl -p >/dev/null 2>&1

        HARDN_STATUS "pass" "Core dumps disabled: Limits set to 0, suid_dumpable set to 0, core_pattern set to /dev/null."
        return 0
}

# Function to apply kernel security hardening
apply_kernel_security() {
        HARDN_STATUS "info" "Starting kernel security hardening..."

        # Call the core dumps function
        disable_core_dumps

        HARDN_STATUS "info" "Kernel security settings applied successfully."
        return 0
}

# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_coredumps() {
    apply_kernel_security
}
