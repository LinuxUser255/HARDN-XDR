#!/bin/bash

# HARDN-XDR - The Linux Security Hardening Sentinel
# Developed and built by SIG Team
# About this script:
# STIG Compliance: Security Technical Implementation Guide.

HARDN_VERSION="2.1.0"
export APT_LISTBUGS_FRONTEND=none
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DEBIAN_VERSION_ID=""
CURRENT_DEBIAN_CODENAME=""
MODULES_DIR="${SCRIPT_DIR}/modules"
echo "Looking for modules in: ${MODULES_DIR}"

HARDN_STATUS() {
        local status="$1"
        local message="$2"
        case "$status" in
            "pass")
                echo -e "\033[1;32m[PASS]\033[0m $message"
                ;;
            "warning")
                echo -e "\033[1;33m[WARNING]\033[0m $message"
                ;;
            "error")
                echo -e "\033[1;31m[ERROR]\033[0m $message"
                ;;
            "info")
                echo -e "\033[1;34m[INFO]\033[0m $message"
                ;;
            *)
                echo -e "\033[1;37m[UNKNOWN]\033[0m $message"
                ;;
        esac
}

get_os_sysinfo() {
    # Get kernel name for OS detection
    local kernel_name
    kernel_name=$(uname -s)

    # Detect OS type
    case $kernel_name in
        Linux)
            if [[ -r /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                CURRENT_DEBIAN_CODENAME="${VERSION_CODENAME}"
                CURRENT_DEBIAN_VERSION_ID="${VERSION_ID}"

                # Set OS type and distribution
                export OS_TYPE="Linux"
                export OS_DISTRO="${ID:-unknown}"

                # Check if this is a supported Debian-based system
                if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
                    export IS_SUPPORTED_DISTRO=true
                else
                    export IS_SUPPORTED_DISTRO=false
                    HARDN_STATUS "warning" "Unsupported Linux distribution: ${ID}"
                fi
            else
                HARDN_STATUS "error" "Cannot detect Linux distribution: /etc/os-release not found"
                export OS_TYPE="Linux"
                export OS_DISTRO="unknown"
                export IS_SUPPORTED_DISTRO=false
            fi
        ;;

        Darwin)
            export OS_TYPE="macOS"
            export OS_DISTRO="macOS"
            export IS_SUPPORTED_DISTRO=false
            HARDN_STATUS "error" "macOS is not supported by HARDN-XDR"
        ;;

        CYGWIN*|MSYS*|MINGW*)
            export OS_TYPE="Windows"
            export OS_DISTRO="Windows"
            export IS_SUPPORTED_DISTRO=false
            HARDN_STATUS "error" "Windows is not supported by HARDN-XDR"
        ;;

        *BSD|DragonFly|Bitrig)
            export OS_TYPE="BSD"
            export OS_DISTRO="BSD"
            export IS_SUPPORTED_DISTRO=false
            HARDN_STATUS "error" "BSD is not supported by HARDN-XDR"
        ;;

        *)
            export OS_TYPE="Unknown"
            export OS_DISTRO="Unknown"
            export IS_SUPPORTED_DISTRO=false
            HARDN_STATUS "error" "Unknown OS detected: '${kernel_name}'"
            HARDN_STATUS "error" "HARDN-XDR only supports Debian-based Linux distributions"
        ;;
    esac

    # Return system information as formatted output if requested
    if [[ "$1" == "--print" || "$1" == "--show" ]]; then
        echo "HARDN-XDR v${HARDN_VERSION} - System Information"
        echo "================================================"
        echo "Script Version: ${HARDN_VERSION}"
        echo "Target OS: Debian-based systems (Debian 12+, Ubuntu 24.04+)"

        # Display detected OS information if available
        if [[ -n "${CURRENT_DEBIAN_VERSION_ID}" && -n "${CURRENT_DEBIAN_CODENAME}" ]]; then
            echo "Detected OS: ${OS_DISTRO:-${ID:-Unknown}} ${CURRENT_DEBIAN_VERSION_ID} (${CURRENT_DEBIAN_CODENAME})"
        fi

        # Display OS type and support status
        if [[ -n "${OS_TYPE}" ]]; then
            echo "System Type: ${OS_TYPE}"
        fi

        if [[ "${IS_SUPPORTED_DISTRO}" == "true" ]]; then
            echo "Support Status: Supported"
        elif [[ -n "${IS_SUPPORTED_DISTRO}" ]]; then
            echo "Support Status: Unsupported"
        fi

        echo "Features: STIG Compliance, Malware Detection, System Hardening"
        echo "Security Tools: UFW, Fail2Ban, AppArmor, AIDE, rkhunter, and more"
        echo ""
    fi
}

# Pass "$@" to the function to forward any script arguments
get_os_sysinfo "$@"

#show_system_info() {
#        echo "HARDN-XDR v${HARDN_VERSION} - System Information"
#        echo "================================================"
#        echo "Script Version: ${HARDN_VERSION}"
#        echo "Target OS: Debian-based systems (Debian 12+, Ubuntu 24.04+)"
#        echo "Features: STIG Compliance, Malware Detection, System Hardening"
#        echo "Security Tools: UFW, Fail2Ban, AppArmor, AIDE, rkhunter, and more"
#        echo ""
#}
#
welcomemsg() {
    # Display header
    cat << EOF

HARDN-XDR v${HARDN_VERSION} - Linux Security Hardening Sentinel
================================================================
EOF

    # Show welcome message dialog
    whiptail --title "HARDN-XDR v${HARDN_VERSION}" \
             --msgbox "Welcome to HARDN-XDR v${HARDN_VERSION} - A Debian Security tool for System Hardening\n\nThis will apply STIG compliance, security tools, and comprehensive system hardening." \
             12 70

    echo ""
    echo "This installer will update your system first..."

    # Confirmation dialog
    if ! whiptail --title "HARDN-XDR v${HARDN_VERSION}" \
                 --yesno "Do you want to continue with the installation?" \
                 10 60; then
        echo "Installation cancelled by user."
        exit 1
    fi
}

preinstallmsg() {
        echo ""
        whiptail --title "HARDN-XDR" --msgbox "Welcome to HARDN-XDR. A Linux Security Hardening program." 10 60
        echo "The system will be configured to ensure STIG and Security compliance."

}


print_ascii_banner() {

    local terminal_width
    terminal_width=$(tput cols)
    local banner
    banner=$(cat << "EOF"

   ▄█    █▄            ▄████████         ▄████████      ████████▄       ███▄▄▄▄
  ███    ███          ███    ███        ███    ███      ███   ▀███      ███▀▀▀██▄
  ███    ███          ███    ███        ███    ███      ███    ███      ███   ███
 ▄███▄▄▄▄███▄▄        ███    ███       ▄███▄▄▄▄██▀      ███    ███      ███   ███
▀▀███▀▀▀▀███▀       ▀███████████      ▀▀███▀▀▀▀▀        ███    ███      ███   ███
  ███    ███          ███    ███      ▀███████████      ███    ███      ███   ███
  ███    ███          ███    ███        ███    ███      ███    ███      ███   ███
  ███    █▀           ███    █▀         ███    ███      ████████▀        ▀█   █▀
                                        ███    ███

                            Endpoint Detection and Response
                            by Security International Group

EOF
)
    local banner_width
    banner_width=$(echo "$banner" | awk '{print length($0)}' | sort -n | tail -1)
    local padding=$(( (terminal_width - banner_width) / 2 ))
    local i
    printf "\033[1;31m"
    while IFS= read -r line; do
        for ((i=0; i<padding; i++)); do
            printf " "
        done
        printf "%s\n" "$line"
    done <<< "$banner"
    sleep 2
    printf "\033[0m"

}

setup_security(){
        HARDN_STATUS "pass"  "Using detected system: Debian ${CURRENT_DEBIAN_VERSION_ID} (${CURRENT_DEBIAN_CODENAME}) for security setup."
        HARDN_STATUS "info"  "Loading and running security modules..."

        # listing every module simpler
        local mods=(
          aide
          auditd
          audit_system
          auto_updates
          banner
          binfmt
          central_logging
          chkrootkit
          compilers
          coredumps
          debsums
          deleted_files
          dns_config
          file_perms
          firewire
          grub
          kernel_sec
          network_protocols
          ntp
          pentest
          process_accounting
          purge_old_pkgs
          rkhunter
          secure_net
          service_disable
          shared_mem
          stig_pwquality
          suricata
          ufw
          unhide
          unnecesary_services
          usb
        )

        # shellcheck disable=SC1090
        for m in "${mods[@]}"; do
          if [[ -r "${MODULES_DIR}/${m}.sh" ]]; then
            HARDN_STATUS "info" "Loading module: ${m}"
            source "${MODULES_DIR}/${m}.sh"

            # Call the module's main function if it exists
            # The function name should follow the pattern: install_and_configure_<module_name>
            local function_name="install_and_configure_${m}"
            if declare -f "$function_name" > /dev/null; then
                HARDN_STATUS "info" "Running module: ${m}"
                "$function_name"
            else
                HARDN_STATUS "warning" "Function ${function_name} not found in module ${m}.sh"
            fi
          else
            HARDN_STATUS "warning" "Module not found: ${m}.sh"
          fi
        done

        echo ""
        echo "RUN THE LYNIS AUDIT TO TEST AFTER GRUB SUCCESS"
        echo ""
}

cleanup() {
    HARDN_STATUS "info" "Performing cleanup operations..."

    # Clean up any temporary files created during installation
    if [[ -d "/tmp/hardn-temp" ]]; then
        rm -rf "/tmp/hardn-temp"
    fi

    # Reset any environment variables that are no longer needed
    unset APT_LISTBUGS_FRONTEND

    HARDN_STATUS "pass" "Cleanup completed successfully."
}

main() {
        print_ascii_banner
        #show_system_info
        welcomemsg
        setup_security
        cleanup
        print_ascii_banner

        HARDN_STATUS "pass" "HARDN-XDR v${HARDN_VERSION} installation completed successfully!"
        HARDN_STATUS "info" "Your system has been hardened with STIG compliance and security tools."
        HARDN_STATUS "warning" "Please reboot your system to complete the configuration."
}

# Command line argument handling
if [[ $# -gt 0 ]]; then
    case "$1" in
        --version|-v)
            cat << EOF
HARDN-XDR v${HARDN_VERSION}
Linux Security Hardening Sentinel
Extended Detection and Response

Target Systems: Debian 12+, Ubuntu 24.04+
Features: STIG Compliance, Malware Detection, System Hardening
Developed by: SIG Team

EOF
            exit 0
            ;;
        --help|-h)
            cat << EOF
HARDN-XDR v${HARDN_VERSION} - Linux Security Hardening Sentinel

Usage: $0 [OPTIONS]

Options:
  --version, -v    Show version information
  --help, -h       Show this help message

This script applies comprehensive security hardening to Debian-based systems
including STIG compliance, malware detection, and security monitoring.

WARNING: This script makes significant system changes. Run only on systems
         intended for security hardening.
EOF
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use '$0 --help' for usage information."
            exit 1
            ;;
    esac
fi

main
