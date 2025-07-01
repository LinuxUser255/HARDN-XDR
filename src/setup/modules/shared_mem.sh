# Module for securing shared memory

secure_shared_memory() {
        HARDN_STATUS "info" "Securing shared memory..."

        local shm_path="/run/shm"
        local mount_options="defaults,noexec,nosuid,nodev"
        local fstab_entry="tmpfs ${shm_path} tmpfs ${mount_options} 0 0"

        # Check and update fstab if needed
        ensure_fstab_entry "${shm_path}" "${fstab_entry}"

        # Apply settings immediately if possible
        apply_mount_options_if_mounted "${shm_path}" "${mount_options}"
}

ensure_fstab_entry() {
        local path="$1"
        local entry="$2"

        if grep -q "tmpfs ${path}" /etc/fstab; then
            HARDN_STATUS "pass" "Shared memory (${path}) is already configured in /etc/fstab"
        else
            # Add the secure mount configuration to fstab
            echo "${entry}" >> /etc/fstab
            HARDN_STATUS "pass" "Added secure mount configuration for shared memory (${path}) to /etc/fstab"
        fi
}

apply_mount_options_if_mounted() {
        local path="$1"
        local options="$2"

        if mountpoint -q "${path}"; then
            HARDN_STATUS "info" "Remounting ${path} with secure options..."
            if mount -o remount,"${options}" "${path}"; then
                HARDN_STATUS "pass" "Successfully remounted ${path} with secure options"
            else
                HARDN_STATUS "warning" "Failed to remount ${path}. Changes will apply after reboot."
            fi
        else
            HARDN_STATUS "info" "${path} is not currently mounted. Changes will apply after reboot."
        fi
}


secure_shared_memory


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_shared_mem() {
    apply_mount_options_if_mounted
}
