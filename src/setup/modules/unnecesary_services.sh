# Module for disabling and removing unnecessary services

# Check service status and take appropriate action
check_and_disable_service() {
        local service_name="$1"

        if is_service_active "$service_name"; then
            disable_active_service "$service_name"
        elif is_service_installed "$service_name"; then
            disable_inactive_service "$service_name"
        else
            log_service_not_found "$service_name"
        fi
}

is_service_active() {
        local service_name="$1"
        systemctl is-active --quiet "$service_name"
}

is_service_installed() {
        local service_name="$1"
        systemctl list-unit-files --type=service | grep -qw "^$service_name.service"
}

disable_active_service() {
        local service_name="$1"
        HARDN_STATUS "error" "Disabling active service: $service_name..."
        systemctl disable --now "$service_name" ||
            log_disable_failure "$service_name"
}

disable_inactive_service() {
        local service_name="$1"
        HARDN_STATUS "error" "Service $service_name is not active, ensuring it is disabled..."
        systemctl disable "$service_name" ||
            log_disable_failure "$service_name"
}

log_disable_failure() {
        local service_name="$1"
        HARDN_STATUS "warning" "Failed to disable service: $service_name (may not be installed or already disabled)."
}

log_service_not_found() {
        local service_name="$1"
        HARDN_STATUS "info" "Service $service_name not found or not installed. Skipping."
}

disable_services() {
        HARDN_STATUS "info" "Disabling unnecessary services..."

        # Process each service in the arguments
        local service
        for service in "$@"; do
            check_and_disable_service "$service"
        done
}

remove_package_if_installed() {
        local pkg="$1"

        # Skip if package is not installed
        dpkg -s "$pkg" >/dev/null 2>&1 || {
            HARDN_STATUS "info" "Package $pkg not installed. Skipping removal."
            return 0
        }

        # Package is installed, attempt to remove it
        HARDN_STATUS "error" "Removing package: $pkg..."
        if apt-get remove -y "$pkg" >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Successfully removed package: $pkg"
        else
            HARDN_STATUS "warning" "Failed to remove package: $pkg"
        fi
}

# Remove unnecessary packages
remove_packages() {
        HARDN_STATUS "info" "Removing unnecessary packages..."

        # Process each package in the arguments
        local pkg
        for pkg in "$@"; do
            remove_package_if_installed "$pkg"
        done
}

# the main function
dis_rm() {
        # Define services and packages to handle
        local services_to_disable=(
            "avahi-daemon"
            "cups"
            "rpcbind"
            "nfs-server"
            "smbd"
            "snmpd"
            "apache2"
            "mysql"
            "bind9"
        )

        local packages_to_remove=(
            "telnet"
            "vsftpd"
            "proftpd"
            "tftpd"
            "postfix"
            "exim4"
        )

        HARDN_STATUS "info" "Starting unnecessary services removal process..."

        disable_services "${services_to_disable[@]}"
        remove_packages "${packages_to_remove[@]}"

        HARDN_STATUS "pass" "Unnecessary services checked and disabled/removed where applicable."
}

# call main
dis_rm

