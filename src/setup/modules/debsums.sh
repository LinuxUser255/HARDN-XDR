# debsums.sh - Optimized version
# use indiviual functions for separation of concerns, maintainability, etc..

# initialize debsums
initialize_debsums() {
        HARDN_STATUS "info" "Initializing debsums..."
        if debsums_init >/dev/null 2>&1; then
            HARDN_STATUS "pass" "debsums initialized successfully"
            return 0
        else
            HARDN_STATUS "error" "Failed to initialize debsums"
            return 1
        fi
}

# configure debsums cron job
configure_debsums_cron() {
        HARDN_STATUS "info" "Configuring debsums daily check..."
        # Use awk for more efficient pattern matching
        if ! awk '/debsums/ {found=1; exit} END {exit !found}' /etc/crontab; then
            # Use printf instead of echo for better performance
            printf "0 4 * * * root /usr/bin/debsums -s 2>&1 | logger -t debsums\n" >> /etc/crontab
            HARDN_STATUS "pass" "debsums daily check added to crontab"
        else
            HARDN_STATUS "warning" "debsums already in crontab"
        fi
        return 0
}

# initial debsums check
run_initial_debsums_check() {
        HARDN_STATUS "info" "Running initial debsums check..."
        # Use timeout to prevent hanging if debsums takes too long
        if timeout 300 debsums -s >/dev/null 2>&1; then
            HARDN_STATUS "pass" "Initial debsums check completed successfully"
            return 0
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                HARDN_STATUS "warning" "Warning: debsums check timed out after 5 minutes"
            else
                HARDN_STATUS "warning" "Warning: Some packages failed debsums verification"
            fi
            return 1
        fi
}

# main
setup_debsums() {
        HARDN_STATUS "info" "Configuring debsums..."

        # Check if debsums is installed - use hash for faster command checking
        if ! hash debsums 2>/dev/null; then
            HARDN_STATUS "error" "debsums command not found, skipping configuration"
            return 1
        fi

        # Use local variables for tracking status
        local init_status=0
        local cron_status=0
        local check_status=0

        # Initialize debsums
        initialize_debsums
        init_status=$?

        # Configure cron job - continue even if initialization fails
        configure_debsums_cron
        cron_status=$?

        # Run initial check only if initialization succeeded
        if [ $init_status -eq 0 ]; then
            run_initial_debsums_check
            check_status=$?
        fi

        # Determine overall status
        if [ $init_status -eq 0 ] && [ $cron_status -eq 0 ] && [ $check_status -eq 0 ]; then
            HARDN_STATUS "info" "debsums setup completed successfully"
            return 0
        else
            HARDN_STATUS "warning" "debsums setup completed with warnings"
            return 1
        fi
}

