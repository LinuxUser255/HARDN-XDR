disable_service() {
        local service_name="$1"
        local service_status

        # Check if service exists first
        if ! systemctl list-unit-files --type=service | grep -qw "^$service_name.service"; then
            HARDN_STATUS "info" "Service $service_name not found or not installed. Skipping."
            return 0
        fi

        # Determine service status
        if systemctl is-active --quiet "$service_name"; then
            service_status="active"
        else
            service_status="inactive"
        fi

        # Handle service based on its status
        case "$service_status" in
            active)
                HARDN_STATUS "info" "Disabling active service: $service_name..."
                if systemctl disable --now "$service_name"; then
                    HARDN_STATUS "pass" "Successfully disabled active service: $service_name"
                else
                    HARDN_STATUS "warning" "Failed to disable active service: $service_name"
                fi
                ;;

            inactive)
                HARDN_STATUS "info" "Service $service_name is not active, ensuring it is disabled..."
                if systemctl disable "$service_name"; then
                    HARDN_STATUS "pass" "Successfully disabled inactive service: $service_name"
                else
                    HARDN_STATUS "warning" "Failed to disable inactive service: $service_name"
                fi
                ;;
        esac
}
