#!/bin/bash
# Script to update hardn-main.sh with all available modules

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_DIR="${PROJECT_ROOT}/setup/modules"
MAIN_SCRIPT="${PROJECT_ROOT}/hardn-main.sh"

# Check if modules directory exists
if [[ ! -d "${MODULES_DIR}" ]]; then
    echo "Error: Modules directory not found: ${MODULES_DIR}"
    exit 1
fi

# Check if main script exists
if [[ ! -f "${MAIN_SCRIPT}" ]]; then
    echo "Error: Main script not found: ${MAIN_SCRIPT}"
    exit 1
fi

# Function to extract main function name from module
extract_main_function() {
    local module_file="$1"
    # Look for function names that start with "apply_" or similar patterns
    grep -E "^[a-zA-Z_]+\(\)" "${module_file}" | grep -E "^apply_|^setup_|^configure_|^harden_" | head -1 | sed 's/().*//'
}

# Generate the execute_modules function content
generate_execute_modules() {
    local content="execute_modules() {\n    HARDN_STATUS \"info\" \"Executing HARDN-XDR modules...\"\n"

    for module in "${MODULES_DIR}"/*.sh; do
        if [[ -f "${module}" ]]; then
            module_name=$(basename "${module}" .sh)
            main_function=$(extract_main_function "${module}")

            if [[ -n "${main_function}" ]]; then
                content+="\n    # Execute ${module_name} module\n"
                content+="    if type ${main_function} &>/dev/null; then\n"
                content+="        ${main_function}\n"
                content+="    else\n"
                content+="        HARDN_STATUS \"warning\" \"${module_name} module function not found.\"\n"
                content+="    fi\n"
            fi
        fi
    done

    content+="\n    HARDN_STATUS \"pass\" \"All modules executed successfully.\"\n}"

    echo -e "${content}"
}

# Update the execute_modules function in the main script
update_main_script() {
    local new_function=$(generate_execute_modules)
    local temp_file=$(mktemp)

    # Replace the execute_modules function in the main script
    awk -v new_func="${new_function}" '
    /^execute_modules\(\)/ {
        print new_func
        in_function = 1
        next
    }
    in_function && /^}/ {
        in_function = 0
        next
    }
    !in_function {
        print
    }
    ' "${MAIN_SCRIPT}" > "${temp_file}"

    # Replace the main script with the updated content
    mv "${temp_file}" "${MAIN_SCRIPT}"
    chmod +x "${MAIN_SCRIPT}"

    echo "Main script updated successfully."
}

# Run the update
update_main_script
