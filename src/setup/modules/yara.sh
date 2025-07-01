# YARA rules setup module

# Check if YARA is installed
check_yara_installed() {
        command -v yara >/dev/null 2>&1 || {
            HARDN_STATUS "warning" "Warning: YARA command not found. Skipping rule setup."
            return 1
        }

        HARDN_STATUS "pass" "YARA command found."
        return 0
}

# Create YARA rules directory
create_yara_directory() {
        HARDN_STATUS "info" "Creating YARA rules directory..."
        mkdir -p /etc/yara/rules
        chmod 755 /etc/yara/rules # Ensure directory is accessible
}

# Check and install git if needed
ensure_git_installed() {
        HARDN_STATUS "info" "Checking for git..."
        command -v git >/dev/null 2>&1 && {
            HARDN_STATUS "pass" "git command found."
            return 0
        }

        HARDN_STATUS "info" "git not found. Attempting to install..."

        apt-get update >/dev/null 2>&1 || {
            HARDN_STATUS "error" "Error: Failed to update package lists. Cannot install git."
            return 1
        }

        apt-get install -y git >/dev/null 2>&1 || {
            HARDN_STATUS "error" "Error: Failed to install git. Cannot download YARA rules."
            return 1
        }

        HARDN_STATUS "pass" "git installed successfully."
        return 0
}

# Create temporary directory
create_temp_directory() {
        local temp_dir
        temp_dir=$(mktemp -d -t yara-rules-XXXXXXXX)

        # Check if directory exists and return appropriate value
        [[ -d "$temp_dir" ]] || {
            HARDN_STATUS "error" "Error: Failed to create temporary directory for YARA rules."
            return 1
        }

        echo "$temp_dir"
}

# Clone YARA rules repository
clone_yara_rules() {
        local temp_dir="$1"
        local rules_repo_url="https://github.com/Yara-Rules/rules.git"

        HARDN_STATUS "info" "Cloning YARA rules from $rules_repo_url to $temp_dir..."
        if git clone --depth 1 "$rules_repo_url" "$temp_dir" >/dev/null 2>&1; then
            HARDN_STATUS "pass" "YARA rules cloned successfully."
            return 0
        else
            HARDN_STATUS "error" "Error: Failed to clone YARA rules repository."
            return 1
        fi
}

# Copy YARA rules to destination
copy_yara_rules() {
    local temp_dir="$1"
    local copied_count=0
    local yar_file

    HARDN_STATUS "info" "Copying .yar rules to /etc/yara/rules/..."

    # Find all .yar files and process them
    while IFS= read -r -d $'\0' yar_file; do
        # Try to copy the file and track success/failure
        if cp "$yar_file" /etc/yara/rules/; then
            ((copied_count++))
        else
            HARDN_STATUS "warning" "Warning: Failed to copy rule file: $yar_file"
        fi
    done < <(find "$temp_dir" -name "*.yar" -print0)

    # Report results based on copy count
    if [[ $copied_count -gt 0 ]]; then
        HARDN_STATUS "pass" "Copied $copied_count YARA rule files to /etc/yara/rules/."
    else
        HARDN_STATUS "warning" "Warning: No .yar files found or copied from the repository."
    fi
}

# Clean up temporary directory
cleanup_temp_directory() {
        local temp_dir="$1"

        HARDN_STATUS "info" "Cleaning up temporary directory $temp_dir..."
        rm -rf "$temp_dir"
        HARDN_STATUS "pass" "Cleanup complete."
}

# Main function to set up YARA rules
setup_yara_rules() {
        HARDN_STATUS "error" "Setting up YARA rules..."

        check_yara_installed || return 0
        create_yara_directory
        ensure_git_installed || return 1

        local temp_dir
        temp_dir=$(create_temp_directory) || return 1

        clone_yara_rules "$temp_dir" && copy_yara_rules "$temp_dir"
        cleanup_temp_directory "$temp_dir"

        HARDN_STATUS "pass" "YARA rules setup attempt completed."
}

setup_yara_rules
