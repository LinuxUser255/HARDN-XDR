# Module for configuring PAM password quality according to STIG requirements

file_contains_string() {
        local file_path="$1"
        local search_string="$2"

        # Check if file exists
        if [ ! -f "$file_path" ]; then
            return 2  # File not found
        fi

        # Check if string exists in file
        if grep -q "$search_string" "$file_path"; then
            return 0  # String found
        else
            return 1  # String not found
        fi
}

configure_pam_password_quality() {
        HARDN_STATUS "info" "Configuring PAM password quality..."

        local pam_file="/etc/pam.d/common-password"
        local pwquality_module="pam_pwquality.so"
        local pwquality_config="password requisite ${pwquality_module} retry=3 minlen=8 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"

        # Check if the PAM file contains the pwquality module
        file_contains_string "$pam_file" "$pwquality_module"
        local result=$?

        case $result in
            0)  # String found
                HARDN_STATUS "pass" "PAM password quality module already configured in $pam_file"
                ;;
            1)  # String not found
                HARDN_STATUS "info" "Adding password quality configuration to $pam_file"
                echo "$pwquality_config" >> "$pam_file"
                HARDN_STATUS "pass" "Successfully added password quality configuration"
                ;;
            2)  # File not found
                HARDN_STATUS "warning" "Warning: $pam_file not found, skipping PAM configuration..."
                ;;
            *)  # Unknown error
                HARDN_STATUS "error" "Error checking PAM configuration"
                ;;
        esac
}

configure_pam_password_quality

