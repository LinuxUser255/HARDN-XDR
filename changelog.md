# Changelog

## Version 1.1.46

#### Improved
- **Modular system**: Restructured the security setup function into a modular system, verified all setups pass. 
- **Update isntall** to source local file and not the clone, incase clone has chanes local does not.
- **Debian Packaging** add Debian packaging and build action in /workflows. This should allow any change to main create a new release, for the user to download the `.hardn-xdr_1.1.X` from releases.
- Upated all documentaiton in `/docs`
- **Package Management**: add `is_installed` at top of each module to allow flexible multi-distribution support:
    - apt
    - yum
    - rpm
    - dnf
- **Version ontro

#### Fixed
- **Rkhunter**: Changed repository to the real, existing one.
- **chkrootkit**: using apt to install and removed url. 
- **suricata**: fixed install path and automated setup
- **aide**: edited scan to only needed directories and provided a suer output statement with path to make more changes. 
- **debsums**: fixed install to correcty source and also setup. 
- **auditd**: fixed install and implimented MITRE ATT&CK framwork settings. 


### NEEDS ATTENTION:
- N/a

---

## Version 1.1.13

#### Added
- **Version Tracking**: Added explicit version identifier (v2.0.0) throughout the script and user interface
- **Enhanced User Experience**: Improved welcome messages, banners, and completion notifications with version information
- **Production Ready**: Finalized as the definitive public release of HARDN-XDR

#### Improved
- **User Interface**: Enhanced all user-facing messages with clearer version information and better formatting
- **Feedback Systems**: Improved completion messages and system cleanup notifications
- **Code Quality**: Maintained high code quality standards from previous ShellCheck improvements

#### Fixed
- **Version Consistency**: Unified version numbering across all components
- **User Communication**: Better feedback during installation and completion phases

### Final Mission Goals
- Comprehensive STIG compliance for Debian-based systems
- Advanced malware detection and response capabilities
- Complete system hardening with security tools integration
- Central logging and monitoring systems
- Extended Detection and Response (XDR) functionality

---

## Version 1.1.8

### Added
- **New Feature**: Introduced a new feature for enhanced system monitoring.

### Improved
- **Performance**: Optimized system performance for faster execution of tasks.

### Fixed
- **Bug Fixes**: Resolved minor bugs reported in version `1.1.6`.

---
## Version 1.1.6

### Added
- **Internet Connectivity Check**: Added a function to verify internet connectivity before proceeding with the setup.
- **Linux Malware Detect (maldet)**: Automated installation and configuration of maldet.
- **Audit Rules**: Configured audit rules for critical system files like `/etc/passwd` and `/etc/shadow`.

### Improved
- **File Permissions**: Fixed permissions for critical files such as `/etc/shadow` and `/etc/passwd`.
- **Service Management**: Enhanced error handling and ensured `Fail2Ban`, `AppArmor`, and `auditd` are enabled and running at boot.
- **SSH Hardening**: Enforced stricter SSH settings for improved security.
- **Kernel Randomization**: Ensured kernel randomization is applied persistently and at runtime.

### Fixed
- **Error Handling**: Improved error handling for services like `Fail2Ban`, `AppArmor`, and `auditd` to prevent setup failures.


---

## Version 1.1.5

### Added
- **Debian Packaging**: Added support for building Debian packages for HARDN.
- **Error Handling**: Enhanced error handling in scripts to prevent disruptions to user logins or system functionality.

### Improved
- **Script Optimization**: Removed redundant steps and consolidated repetitive code blocks in setup scripts.
- **Documentation**: Updated documentation to reflect the latest changes and features.

### Fixed
- **Cron Jobs**: Ensured cron jobs are non-intrusive and do not disrupt user workflows.
- **GRUB BUG**: removed dependant file due to PAM collision and Kernal alerting flaw. 
- **AIDE Initialization**: Improved AIDE initialization process for better reliability.


---

