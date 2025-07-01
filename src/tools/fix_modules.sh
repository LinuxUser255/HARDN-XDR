#!/usr/bin/env bash
# Script to fix modules that are missing their main functions

MODULES_DIR="${1:-/home/linux/Projects/LinuxThings/Hardn-Project/Chris/HARDN-XDR/src/setup/modules}"

# Generic function to check and fix a module
fix_module() {
    local module_name="$1"
    local function_name="$2"
    local function_content="$3"

    local module="${MODULES_DIR}/${module_name}.sh"
    if [[ ! -f "$module" ]]; then
        echo "Module file $module not found, skipping"
        return 1
    fi

    if grep -q "${function_name}" "$module"; then
        echo "Function already exists in ${module_name} module, skipping"
        return 0
    fi

    cat >> "$module" << EOF
${function_content}
EOF
    echo "Fixed ${module_name} module"
    return 0
}

# Function to fix the binfmt module
fix_binfmt() {
    # Define the content with proper escaping for double quotes
    # Using double quotes for the heredoc content to allow variable expansion
    local content="
# Main function to configure binfmt
install_and_configure_binfmt() {
    HARDN_STATUS "info" "Configuring binfmt..."

    # Disable binfmt_misc for security
    if [[ -f /proc/sys/fs/binfmt_misc/status ]]; then
        echo 0 > /proc/sys/fs/binfmt_misc/status
        HARDN_STATUS "pass" "Disabled binfmt_misc for security."
    else
        HARDN_STATUS "info" "binfmt_misc not found or already disabled."
    fi

    # Prevent automatic loading of binfmt_misc
    if [[ -d /etc/modprobe.d ]]; then
        echo "install binfmt_misc /bin/true" > /etc/modprobe.d/binfmt-misc.conf"
        HARDN_STATUS "pass" "Prevented automatic loading of binfmt_misc."
    fi"

    return 0
}"
    # Call the generic fix_module function with the module name, function name, and content
    fix_module "binfmt" "install_and_configure_binfmt" "$content"
}

# Function to fix the compilers module
fix_compilers() {
    local content="
# Main function to restrict compiler access
install_and_configure_compilers() {
    HARDN_STATUS \"info\" \"Restricting compiler access to root only (HRDN-7222)...\"

    # List of common compilers to restrict
    local compilers=(
        \"/usr/bin/as\"
        \"/usr/bin/gcc\"
        \"/usr/bin/cc\"
        \"/usr/bin/c++\"
        \"/usr/bin/g++\"
        \"/usr/bin/make\"
        \"/usr/bin/ld\"
        \"/usr/bin/clang\"
        \"/usr/bin/clang++\"
    )

    # Restrict access to compilers
    for compiler in \"\${compilers[@]}\"; do
        if [[ -f \"\$compiler\" ]]; then
            chmod 0700 \"\$compiler\"
            HARDN_STATUS \"pass\" \"Restricted access to \$compiler\"
        fi
    done

    HARDN_STATUS \"pass\" \"Compiler access restricted to root only.\"
    return 0
}"
    fix_module "compilers" "install_and_configure_compilers" "$content"
}



# Function to fix the deleted_files module
fix_deleted_files() {
    local content="
# Main function to handle deleted files
install_and_configure_deleted_files() {
    HARDN_STATUS "info" "Checking for deleted files still in use..."

    # Find deleted files still in use
    local deleted_files
    deleted_files=\$(lsof +L1 2>/dev/null | grep -v "COMMAND" | awk '{print \$1 " " \$NF}' | sort -u)

    if [[ -n "\$deleted_files" ]]; then
        HARDN_STATUS "warning" "Found deleted files still in use:"
        echo "\$deleted_files"

        # Attempt to restart services using deleted files
        HARDN_STATUS "info" "Attempting to restart services using deleted files..."

        # Extract unique process names
        local processes
        processes=\$(echo "\$deleted_files" | awk '{print \$1}' | sort -u)

        for proc in \$processes; do
            # Check if it is a service
            if systemctl list-unit-files | grep -q "\$proc"; then
                HARDN_STATUS "info" "Restarting service: \$proc"
                systemctl restart "\$proc" || HARDN_STATUS "warning" "Failed to restart \$proc"
            else
                HARDN_STATUS "info" "Process \$proc is not a service, manual intervention may be required."
            fi
        done
    else
        HARDN_STATUS "pass" "No deleted files in use found."
    fi

    return 0
}"
    fix_module "deleted_files" "install_and_configure_deleted_files" "$content"
}

# Function to fix the file_perms module
fix_file_perms() {
    local content="
# Main function to set secure file permissions
install_and_configure_file_perms() {
    HARDN_STATUS "info" "Setting secure file permissions..."

    # Secure SSH configuration files
    if [[ -d /etc/ssh ]]; then
        chmod 0700 /etc/ssh

        if [[ -f /etc/ssh/sshd_config ]]; then
            chmod 0600 /etc/ssh/sshd_config
            HARDN_STATUS "pass" "Secured SSH configuration files."
        else
            HARDN_STATUS "warning" "File /etc/ssh/sshd_config not found, skipping permission setting"
        fi
    fi

    # Secure password and shadow files
    chmod 0644 /etc/passwd
    chmod 0640 /etc/shadow
    chmod 0644 /etc/group
    chmod 0640 /etc/gshadow
    HARDN_STATUS "pass" "Secured password and shadow files."

    # Secure sudoers files
    if [[ -d /etc/sudoers.d ]]; then
        chmod 0750 /etc/sudoers.d
        find /etc/sudoers.d -type f -exec chmod 0440 {} \\;
        HARDN_STATUS "pass" "Secured sudoers files."
    fi

    # Secure cron files
    for crondir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly; do
        if [[ -d "\$crondir" ]]; then
            chmod 0700 "\$crondir"
            find "\$crondir" -type f -exec chmod 0700 {} \\;
        fi
    done

    if [[ -f /etc/crontab ]]; then
        chmod 0700 /etc/crontab
    fi

    HARDN_STATUS "pass" "Secured cron files."

    return 0
}"
    fix_module "file_perms" "install_and_configure_file_perms" "$content"
}

# Function to fix the firewire module
fix_firewire() {
    local content="
# Main function to disable firewire
install_and_configure_firewire() {
    HARDN_STATUS "info" "Disabling FireWire for security..."

    # Create modprobe configuration to disable firewire
    cat > /etc/modprobe.d/firewire-blacklist.conf << 'EOFMOD'
# Blacklist firewire modules for security
blacklist firewire-core
blacklist firewire-ohci
blacklist firewire-sbp2
install firewire-core /bin/true
install firewire-ohci /bin/true
install firewire-sbp2 /bin/true
EOFMOD

    # Update initramfs if available
    if command -v update-initramfs >/dev/null 2>&1; then
        update-initramfs -u
        HARDN_STATUS "pass" "Updated initramfs with FireWire blacklist."
    else
        HARDN_STATUS "warning" "update-initramfs not found, changes will take effect after reboot."
    fi

    HARDN_STATUS "pass" "FireWire modules blacklisted for security."
    return 0
}"
    fix_module "firewire" "install_and_configure_firewire" "$content"
}

# Function to fix the auditd module
fix_auditd() {
    local module="${MODULES_DIR}/auditd.sh"
    if [[ ! -f "$module" ]]; then
        echo "Module file $module not found, skipping"
        return 1
    fi

    if ! grep -q "install_and_configure_auditd" "$module"; then
        echo "Function not found in auditd module, skipping"
        return 0
    fi

    # Add package installation check at the beginning of the function
    sed -i '/install_and_configure_auditd/a \
    # Ensure auditd is installed\
    if ! dpkg -s auditd >/dev/null 2>&1; then\
        HARDN_STATUS "info" "Installing auditd package..."\
        apt-get update >/dev/null 2>&1\
        apt-get install -y auditd audispd-plugins >/dev/null 2>&1 || {\
            HARDN_STATUS "error" "Failed to install auditd. Aborting configuration."\
            return 1\
        }\
    fi' "$module"

    echo "Fixed auditd module"
    return 0
}

# Function to fix the chkrootkit module
fix_chkrootkit() {
    local module="${MODULES_DIR}/chkrootkit.sh"
    if [[ ! -f "$module" ]]; then
        echo "Module file $module not found, skipping"
        return 1
    fi

    if ! grep -q "install_and_configure_chkrootkit" "$module"; then
        echo "Function not found in chkrootkit module, skipping"
        return 0
    fi

    # Add package installation check at the beginning of the function
    sed -i '/install_and_configure_chkrootkit/a \
    # Ensure chkrootkit is installed\
    if ! dpkg -s chkrootkit >/dev/null 2>&1; then\
        HARDN_STATUS "info" "Installing chkrootkit package..."\
        apt-get update >/dev/null 2>&1\
        apt-get install -y chkrootkit >/dev/null 2>&1 || {\
            HARDN_STATUS "error" "Failed to install chkrootkit. Aborting configuration."\
            return 1\
        }\
    fi' "$module"

    echo "Fixed chkrootkit module"
    return 0
}
