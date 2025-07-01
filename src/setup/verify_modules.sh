#!/bin/bash
# Script to verify that all modules are properly sourced and executed

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
    grep -E "^[a-zA-Z_]+\(\)" "${module_file}" | grep -E "^apply_|^setup_|^configure_|^harden_" | head -1 | sed 's/().*//'
}

# Verify that all modules are sourced and executed
echo "Verifying modules in ${MODULES_DIR}:"
echo "=================================="

for module in "${MODULES_DIR}"/*.sh; do
    if [[ -f "${module}" ]]; then
        module_name=$(basename "${module}" .sh)
        main_function=$(extract_main_function "${module}")

        echo "Module: ${module_name}"
        echo "  Main function: ${main_function:-<none>}"

        # Check if the module is sourced in the main script
        if grep -q "source.*${module_name}.sh" "${MAIN_SCRIPT}"; then
            echo "  Sourced: Yes"
        else
            echo "  Sourced: No (WARNING)"
        fi

        # Check if the main function is called in the main script
        if [[ -n "${main_function}" ]]; then
            if grep -q "${main_function}" "${MAIN_SCRIPT}"; then
                echo "  Executed: Yes"
            else
                echo "  Executed: No (WARNING)"
            fi
        else
            echo "  Executed: N/A (No main function found)"
        fi

        echo "--------------------------------"
    fi
done

echo "Verification complete."
