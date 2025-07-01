# Function to check for deleted files still in use by processes

check_deleted_files() {
        HARDN_STATUS "info" "Checking for deleted files in use..."

        # Check if lsof is available
        if ! command -v lsof >/dev/null 2>&1; then
            HARDN_STATUS "error" "lsof command not found. Cannot check for deleted files in use."
            return 1
        fi

        # Find deleted files with proper error handling
        local deleted_files
        deleted_files=$(lsof +L1 2>/dev/null | awk 'NR>1 && $NF ~ /.*\(deleted\)$/ {print $9}' | sort -u)

        # Check if any deleted files were found
        if [[ -n "$deleted_files" ]]; then
            HARDN_STATUS "warning" "Found deleted files in use:"
            # Format output for better readability
            echo "$deleted_files" | while read -r file; do
                echo "  - $file"
            done
            HARDN_STATUS "warning" "Please consider rebooting the system to release these files."
            return 2
        else
            HARDN_STATUS "pass" "No deleted files in use found."
            return 0
        fi
}

# Execute the function
check_deleted_files
