HARDN_STATUS "info" "Configuring DNS nameservers..."

# Define DNS providers with their primary and secondary servers
declare_dns_providers() {
    declare -gA dns_providers=(
        ["Quad9"]="9.9.9.9 149.112.112.112"
        ["Cloudflare"]="1.1.1.1 1.0.0.1"
        ["Google"]="8.8.8.8 8.8.4.4"
        ["OpenDNS"]="208.67.222.222 208.67.220.220"
        ["CleanBrowsing"]="185.228.168.9 185.228.169.9"
        ["UncensoredDNS"]="91.239.100.100 89.233.43.71"
    )
}

# Select DNS provider using whiptail
select_dns_provider() {
    local selected_provider
    selected_provider=$(whiptail --title "DNS Provider Selection" --menu \
        "Select a DNS provider for enhanced security and privacy:" 18 78 6 \
        "Quad9" "DNSSEC, Malware Blocking, No Logging (Recommended)" \
        "Cloudflare" "DNSSEC, Privacy-First, No Logging" \
        "Google" "DNSSEC, Fast, Reliable (some logging)" \
        "OpenDNS" "DNSSEC, Custom Filtering, Logging (opt-in)" \
        "CleanBrowsing" "Family-safe, Malware Block, DNSSEC" \
        "UncensoredDNS" "DNSSEC, No Logging, Europe-based, Privacy Focus" \
        3>&1 1>&2 2>&3)

    echo "$selected_provider"
}

# Configure DNS using systemd-resolved
configure_systemd_resolved() {
        local primary_dns="$1"
        local secondary_dns="$2"
        local selected_provider="$3"
        local resolv_conf="$4"
        local changes_made=false
        local temp_resolved_conf
        local resolved_conf_systemd="/etc/systemd/resolved.conf"

        HARDN_STATUS "info" "systemd-resolved is active and manages $resolv_conf."

        # Create temporary file with error handling
        temp_resolved_conf=$(mktemp) || {
            HARDN_STATUS "error" "Failed to create temporary file"
            return 1
        }

        if [[ ! -f "$resolved_conf_systemd" ]]; then
            HARDN_STATUS "info" "Creating $resolved_conf_systemd as it does not exist."
            echo "[Resolve]" > "$resolved_conf_systemd"
            chmod 644 "$resolved_conf_systemd"
        fi

        cp "$resolved_conf_systemd" "$temp_resolved_conf"

        # Use a helper function to update or add configuration parameters
        update_resolved_conf() {
            local param="$1"
            local value="$2"

            if grep -qE "^\s*$param=" "$temp_resolved_conf"; then
                sed -i -E "s/^\s*$param=.*/$param=$value/" "$temp_resolved_conf"
            elif grep -q "\[Resolve\]" "$temp_resolved_conf"; then
                sed -i "/\[Resolve\]/a $param=$value" "$temp_resolved_conf"
            else
                echo -e "\n[Resolve]\n$param=$value" >> "$temp_resolved_conf"
            fi
        }

        # Update configuration parameters
        update_resolved_conf "DNS" "$primary_dns $secondary_dns"
        update_resolved_conf "FallbackDNS" "$secondary_dns $primary_dns"
        update_resolved_conf "DNSSEC" "allow-downgrade"

        if ! cmp -s "$temp_resolved_conf" "$resolved_conf_systemd"; then
            cp "$temp_resolved_conf" "$resolved_conf_systemd"
            HARDN_STATUS "pass" "Updated $resolved_conf_systemd. Restarting systemd-resolved..."
            if systemctl restart systemd-resolved; then
                HARDN_STATUS "pass" "systemd-resolved restarted successfully."
                changes_made=true
            else
                HARDN_STATUS "error" "Failed to restart systemd-resolved. Manual check required."
            fi
        else
            HARDN_STATUS "info" "No effective changes to $resolved_conf_systemd were needed."
        fi

        # Always clean up temporary file
        rm -f "$temp_resolved_conf"

        echo "$changes_made"
}

# Configure DNS using NetworkManager
configure_networkmanager() {
    local primary_dns="$1"
    local secondary_dns="$2"
    local changes_made=false

    HARDN_STATUS "info" "NetworkManager detected. Attempting to configure DNS via NetworkManager..."

    # Get the current active connection
    local active_conn
    active_conn=$(nmcli -t -f NAME,TYPE,DEVICE,STATE c show --active | grep -E ':(ethernet|wifi):.+:activated' | head -1 | cut -d: -f1)

    if [[ -n "$active_conn" ]]; then
        HARDN_STATUS "info" "Configuring DNS for active connection: $active_conn"

        # Attempt to modify the connection
        if nmcli c modify "$active_conn" ipv4.dns "$primary_dns,$secondary_dns" ipv4.ignore-auto-dns yes; then
            HARDN_STATUS "pass" "NetworkManager DNS configuration updated."

            # Handle connection restart with case statement
            case "$(nmcli c down "$active_conn" && nmcli c up "$active_conn"; echo $?)" in
                0)
                    HARDN_STATUS "pass" "NetworkManager connection restarted successfully."
                    changes_made=true
                ;;

                *)
                    HARDN_STATUS "error" "Failed to restart NetworkManager connection. Changes may not be applied."
                ;;
            esac
        else
            HARDN_STATUS "error" "Failed to update NetworkManager DNS configuration."
        fi
    else
        HARDN_STATUS "warning" "No active NetworkManager connection found."
    fi

    echo "$changes_made"
}

# Configure DNS directly in resolv.conf
configure_resolv_conf() {
        local primary_dns="$1"
        local secondary_dns="$2"
        local selected_provider="$3"
        local resolv_conf="$4"
        local changes_made=false

        HARDN_STATUS "info" "Attempting direct modification of $resolv_conf."
        if [[ -f "$resolv_conf" ]] && [[ -w "$resolv_conf" ]]; then
            # Backup the original file
            cp "$resolv_conf" "${resolv_conf}.bak.$(date +%Y%m%d%H%M%S)"

            # Create a new resolv.conf with our DNS servers
            {
                echo "# Generated by HARDN-XDR"
                echo "# DNS Provider: $selected_provider"
                echo "nameserver $primary_dns"
                echo "nameserver $secondary_dns"
                # Preserve any options or search domains from the original file
                grep -E "^\s*(options|search|domain)" "$resolv_conf" || true
            } > "${resolv_conf}.new"

            # Replace the original file
            mv "${resolv_conf}.new" "$resolv_conf"
            chmod 644 "$resolv_conf"

            HARDN_STATUS "pass" "Set $selected_provider DNS servers in $resolv_conf."
            HARDN_STATUS "warning" "Warning: Direct changes to $resolv_conf might be overwritten by network management tools."
            changes_made=true

            # Make resolv.conf immutable to prevent overwriting
            if whiptail --title "Protect DNS Configuration" --yesno "Would you like to make $resolv_conf immutable to prevent other services from changing it?\n\nNote: This may interfere with DHCP or VPN services." 10 78; then
                if chattr +i "$resolv_conf" 2>/dev/null; then
                    HARDN_STATUS "pass" "Made $resolv_conf immutable to prevent changes."
                else
                    HARDN_STATUS "error" "Failed to make $resolv_conf immutable. Manual protection may be needed."
                fi
            fi
        else
            HARDN_STATUS "error" "Could not modify $resolv_conf (file not found or not writable)."
        fi

        echo "$changes_made"
}

# Create dhclient hook for persistent DNS
create_dhclient_hook() {
    local primary_dns="$1"
    local secondary_dns="$2"
    local selected_provider="$3"

    local dhclient_dir="/etc/dhcp/dhclient-enter-hooks.d"
    local hook_file="$dhclient_dir/hardn-dns"

    if [[ ! -d "$dhclient_dir" ]]; then
        mkdir -p "$dhclient_dir"
    fi

    cat > "$hook_file" << EOF
#!/bin/sh
# HARDN-XDR DNS configuration hook
# DNS Provider: $selected_provider

make_resolv_conf() {
# Override the default make_resolv_conf function
cat > /etc/resolv.conf << RESOLVCONF
# Generated by HARDN-XDR dhclient hook
# DNS Provider: $selected_provider
nameserver $primary_dns
nameserver $secondary_dns
RESOLVCONF

# Preserve any search domains from DHCP
if [ -n "\$new_domain_search" ]; then
    echo "search \$new_domain_search" >> /etc/resolv.conf
elif [ -n "\$new_domain_name" ]; then
    echo "search \$new_domain_name" >> /etc/resolv.conf
fi

return 0
}
EOF
    chmod 755 "$hook_file"
    HARDN_STATUS "pass" "Created dhclient hook to maintain DNS settings."
}

# Test DNS resolution
test_dns_resolution() {
        local primary_dns="$1"

        HARDN_STATUS "info" "Testing DNS resolution with $primary_dns..."
        if host -W 5 google.com "$primary_dns" >/dev/null 2>&1; then
            HARDN_STATUS "pass" "DNS resolution test successful."
            return 0
        else
            HARDN_STATUS "warning" "DNS resolution test failed. DNS settings may not be working correctly."
            return 1
        fi
}

# Main function to configure DNS
configure_dns() {
        HARDN_STATUS "info" "Configuring DNS nameservers..."

        # Initialize DNS providers
        declare_dns_providers

        # Select DNS provider
        local selected_provider
        selected_provider=$(select_dns_provider)

        # Exit if user cancels
        if [[ -z "$selected_provider" ]]; then
            HARDN_STATUS "warning" "DNS configuration cancelled by user. Using system defaults."
            return 0
        fi

        # Get the selected DNS servers
        local primary_dns secondary_dns
        read -r primary_dns secondary_dns <<< "${dns_providers[$selected_provider]}"
        HARDN_STATUS "info" "Selected $selected_provider DNS: Primary $primary_dns, Secondary $secondary_dns"

        local resolv_conf="/etc/resolv.conf"
        local configured_persistently=false
        local changes_made=false

        # Check for systemd-resolved
        if systemctl is-active --quiet systemd-resolved && \
           [[ -L "$resolv_conf" ]] && \
           (readlink "$resolv_conf" | grep -qE "systemd/resolve/(stub-resolv.conf|resolv.conf)"); then
            changes_made=$(configure_systemd_resolved "$primary_dns" "$secondary_dns" "$selected_provider" "$resolv_conf")
            configured_persistently=true
        fi

        # Check for NetworkManager
        if [[ "$configured_persistently" = false ]] && command -v nmcli >/dev/null 2>&1; then
            changes_made=$(configure_networkmanager "$primary_dns" "$secondary_dns")
            configured_persistently=true
        fi

        # If not using systemd-resolved or NetworkManager, try to set directly in /etc/resolv.conf
        if [[ "$configured_persistently" = false ]]; then
            changes_made=$(configure_resolv_conf "$primary_dns" "$secondary_dns" "$selected_provider" "$resolv_conf")
        fi

        # Create a persistent hook for dhclient if it exists
        if command -v dhclient >/dev/null 2>&1; then
            create_dhclient_hook "$primary_dns" "$secondary_dns" "$selected_provider"
        fi

        if [[ "$changes_made" = true ]]; then
            whiptail --infobox "DNS configured: $selected_provider\nPrimary: $primary_dns\nSecondary: $secondary_dns" 8 70
        else
            whiptail --infobox "DNS configuration checked. No changes made or needed." 8 70
        fi

        # Test DNS resolution
        test_dns_resolution "$primary_dns"
}

# Call  main
configure_dns


