# Network protocol hardening module

# Main function to disable unnecessary network protocols
harden_network_protocols() {
    HARDN_STATUS "info" "Disabling unnecessary network protocols..."

    check_promiscuous_interfaces

    create_network_protocol_blacklist

    apply_changes

    HARDN_STATUS "pass" "Network protocol hardening complete: Disabled $(grep -c "^install" /etc/modprobe.d/blacklist-rare-network.conf) protocols"
}

# Check for network interfaces in promiscuous mode
check_promiscuous_interfaces() {
    local interfaces=()
    mapfile -t interfaces < <(/sbin/ip link show | awk '$0 ~ /: / {print $2}' | sed 's/://g')

    for((i=0; i<${#interfaces[@]}; i++)); do
        local interface="${interfaces[i]}"
        if /sbin/ip link show "$interface" | grep -q "PROMISC"; then
            HARDN_STATUS "warning" "Interface $interface is in promiscuous mode. Review Interface."
        fi
    done
}

# Create comprehensive blacklist file for network protocols
create_network_protocol_blacklist() {
    local blacklist_file="/etc/modprobe.d/blacklist-rare-network.conf"

    cat > "$blacklist_file" << 'EOF'
# HARDN-XDR Blacklist for Rare/Unused Network Protocols
# Disabled for compliance and attack surface reduction

# TIPC (Transparent Inter-Process Communication)
install tipc /bin/true

# DCCP (Datagram Congestion Control Protocol) - DoS risk
install dccp /bin/true

# SCTP (Stream Control Transmission Protocol) - Can bypass firewall rules
install sctp /bin/true

# RDS (Reliable Datagram Sockets) - Previous vulnerabilities
install rds /bin/true

# Amateur Radio and Legacy Protocols
install ax25 /bin/true
install netrom /bin/true
install rose /bin/true
install decnet /bin/true
install econet /bin/true
install ipx /bin/true
install appletalk /bin/true
install x25 /bin/true

# Bluetooth networking (typically unnecessary on servers)

# Wireless protocols (if not needed) put 80211x and 802.11 in the blacklist

# Exotic network file systems
install cifs /bin/true
install nfs /bin/true
install nfsv3 /bin/true
install nfsv4 /bin/true
install ksmbd /bin/true
install gfs2 /bin/true

# Uncommon IPv4/IPv6 protocols
install atm /bin/true
install can /bin/true
install irda /bin/true

# Legacy protocols
install token-ring /bin/true
install fddi /bin/true
EOF
}

# Apply changes immediately where possible
apply_changes() {
    # Reload sysctl settings
    sysctl -p >/dev/null 2>&1

    # Attempt to unload modules that are already loaded
    unload_blacklisted_modules
}

# Attempt to unload modules that are already loaded
unload_blacklisted_modules() {
    local blacklisted_modules=()
    mapfile -t blacklisted_modules < <(grep "^install" /etc/modprobe.d/blacklist-rare-network.conf | awk '{print $2}')

    for((i=0; i<${#blacklisted_modules[@]}; i++)); do
        local module="${blacklisted_modules[i]}"
        if lsmod | grep -q "^${module}"; then
            HARDN_STATUS "info" "Attempting to unload module: $module"
            if rmmod "$module" 2>/dev/null; then
                HARDN_STATUS "pass" "Successfully unloaded module: $module"
            else
                HARDN_STATUS "warning" "Could not unload module: $module (may be in use or built-in)"
            fi
        fi
    done
}

# Execute the main function
harden_network_protocols


# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_network_protocols() {
    harden_network_protocols
}
