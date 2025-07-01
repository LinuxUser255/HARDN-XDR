# Module for purging old packages and cleaning up the system

# Main function to orchestrate the cleanup process
cleanup_system() {
        purge_old_package_configs
        remove_unused_packages
}

# purge configuration files of removed packages
purge_old_package_configs() {
        HARDN_STATUS "info" "Purging configuration files of old/removed packages..."

        # Get list of packages with leftover configs (status 'rc')
        local packages_to_purge
        packages_to_purge=$(dpkg -l | grep '^rc' | awk '{print $2}')

        # Early return if no packages to purge
        if [[ -z "$packages_to_purge" ]]; then
            HARDN_STATUS "pass" "No old/removed packages with leftover configuration files found to purge."
            show_notification "No leftover package configurations to purge."
            return
        fi

        # Display packages to be purged
        HARDN_STATUS "info" "Found the following packages with leftover configuration files to purge:"
        echo "$packages_to_purge"

        # Show GUI notification if whiptail is available
        show_packages_to_purge "$packages_to_purge"

        # Purge each package
        purge_package_list "$packages_to_purge"

        show_notification "Purged configuration files for removed packages."
}

show_packages_to_purge() {
        local package_list="$1"

        if command -v whiptail >/dev/null; then
            whiptail --title "Packages to Purge" --msgbox "The following packages have leftover configuration files that will be purged:\n\n$package_list" 15 70
        fi
}

show_notification() {
        local message="$1"

        if command -v whiptail >/dev/null; then
            whiptail --infobox "$message" 7 70
        fi
}

purge_package_list() {
        local package_list="$1"

        for pkg in $package_list; do
            purge_single_package "$pkg"
        done
}

purge_single_package() {
        local pkg="$1"

        HARDN_STATUS "info" "Purging $pkg..."

        # Try apt purge first
        apt purge -y "$pkg" && {
            HARDN_STATUS "pass" "Successfully purged $pkg."
            return
        }

        # If apt fails, try dpkg --purge
        HARDN_STATUS "error" "Failed to purge $pkg. Trying dpkg --purge..."

        dpkg --purge "$pkg" && {
            HARDN_STATUS "pass" "Successfully purged $pkg with dpkg."
            return
        }

        # Both methods failed
        HARDN_STATUS "error" "Failed to purge $pkg with dpkg as well."
}

remove_unused_packages() {
        HARDN_STATUS "info" "Running apt autoremove and clean to free up space..."

        apt autoremove -y
        apt clean

        show_notification "Apt cache cleaned."
}

cleanup_system


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_purge_old_pkgs() {
    HARDN_STATUS "error" "purge_old_pkgs module has no main function defined"
}
