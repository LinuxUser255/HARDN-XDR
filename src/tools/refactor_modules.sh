#!/bin/bash
# Script to refactor modules to ensure they have the required function

MODULES_DIR="$HOME/Projects/LinuxThings/Hardn-Project/Chris/HARDN-XDR/src/setup/modules"

# Function to find the main function in a module
find_main_function() {
    local module_file="$1"
    grep -E "^[a-zA-Z_]+\(\)" "$module_file" | grep -E "^apply_|^setup_|^configure_|^harden_" | head -1 | sed 's/().*//'
}

# Process each module
for module in "$MODULES_DIR"/*.sh; do
    module_name=$(basename "$module" .sh)
    function_name="install_and_configure_${module_name}"

    # Check if the required function already exists
    if ! grep -q "$function_name" "$module"; then
        echo "Processing $module_name..."

        # Find the main function
        main_function=$(find_main_function "$module")

        if [[ -n "$main_function" ]]; then
            echo "  Found main function: $main_function"

            # Add the required function at the end of the file
            cat >> "$module" << EOF

# Entry point function that follows the naming convention used in hardn-main.sh
$function_name() {
    $main_function
}
EOF
            echo "  Added $function_name function that calls $main_function"
        else
            echo "  No main function found in $module_name"

            # Add a placeholder function
            cat >> "$module" << EOF

# Entry point function that follows the naming convention used in hardn-main.sh
$function_name() {
    HARDN_STATUS "error" "$module_name module has no main function defined"
}
EOF
            echo "  Added placeholder $function_name function"
        fi
    else
        echo "✅ $module_name already has required function $function_name"
    fi
done

echo "Module refactoring complete!"
