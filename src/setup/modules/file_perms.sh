# Set secure file permissions
set_secure_file_permissions() {
    HARDN_STATUS "info" "Setting secure file permissions..."

    # Define permissions in parallel arrays: paths and permissions
    local file_paths=(
        "/root"
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/gshadow"
        "/etc/ssh/sshd_config"
    )

    local file_perms=(
        "700"  # root home directory - root only
        "644"  # user database - readable (required)
        "600"  # password hashes - root only
        "644"  # group database - readable
        "600"  # group passwords - root only
        "644"  # SSH daemon config - readable
    )

    # Apply permissions and report status
    local errors=0
    for ((i=0; i<${#file_paths[@]}; i++)); do
        local file="${file_paths[i]}"
        local perm="${file_perms[i]}"

        if [[ -e "$file" ]]; then
            if chmod "$perm" "$file"; then
                HARDN_STATUS "pass" "Set permissions $perm on $file"
            else
                HARDN_STATUS "error" "Failed to set permissions $perm on $file"
                ((errors++))
            fi
        else
            HARDN_STATUS "warning" "File $file not found, skipping permission setting"
        fi
    done

    if [[ $errors -eq 0 ]]; then
        HARDN_STATUS "pass" "All file permissions set successfully"
        return 0
    else
        HARDN_STATUS "warning" "Failed to set permissions on $errors files"
        return 1
    fi
}

# Call the function to set secure file permissions
set_secure_file_permissions

