HARDN_STATUS "error" "Restricting compiler access to root only (HRDN-7222)..."

# Restrict compiler access to root only
restrict_compiler_access() {
    HARDN_STATUS "info" "Restricting compiler access to root only (HRDN-7222)..."

    local compilers
    compilers="/usr/bin/gcc /usr/bin/g++ /usr/bin/make /usr/bin/cc /usr/bin/c++ /usr/bin/as /usr/bin/ld"
    for bin in $compilers; do
        if [[ -f "$bin" ]]; then
            chmod 755 "$bin"
            chown root:root "$bin"
            HARDN_STATUS "pass" "Set $bin to 755 root:root (default for compilers)."
        fi
    done

    HARDN_STATUS "pass" "Compiler access restrictions applied."
    return 0
}

# Entry point function that follows the naming convention used in hardn-main.sh
install_and_configure_compilers() {
    HARDN_STATUS "error" "compilers module has no main function defined"
}
