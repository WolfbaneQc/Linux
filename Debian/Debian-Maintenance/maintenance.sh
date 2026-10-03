#!/usr/bin/env bash

# =============================================================================
# Debian 13 System Maintenance Script
# =============================================================================
#
# Purpose:
#   A personal Debian 13 maintenance script for keeping the system packages
#   and Flatpak applications up to date, while also performing basic cleanup,
#   diagnostics, logging, and reboot-status checks.
#
#   Created collaboratively by WolfbaneQc and ChatGPT, and adapted to
#   WolfbaneQc's preferred maintenance workflow and safety requirements.
#
# =============================================================================
#
# Performs routine maintenance:
#   1. Validate Debian environment
#   2. Check root filesystem space
#   3. Check dpkg/APT package state
#   4. Refresh APT package lists
#   5. Upgrade Debian packages (full-upgrade)
#   6. Update Flatpak applications for the current desktop user
#   7. Update system Flatpak applications
#   8. Remove unused APT dependencies
#   9. Clean obsolete APT package cache
#  10. Show Flatpak repository diagnostics
#  11. Show system information with fastfetch
#  12. Check whether a reboot is recommended
#  13. Show disk usage
#  14. Show package change summary
#
# Usage:
#   sudo ./debian-maintain.sh
#   sudo ./debian-maintain.sh --dry-run
#   sudo ./debian-maintain.sh --no-flatpak
#   sudo ./debian-maintain.sh --no-cleanup
#
# =============================================================================

# -----------------------------------------------------------------------------
# Shell safety
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"

LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/debian-maintenance.log"
LOGROTATE_FILE="/etc/logrotate.d/debian-maintenance"

DRY_RUN=false
USE_FLATPAK=true
DO_CLEANUP=true

MAINTENANCE_FAILED=false

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    WHITE=$'\033[1;37m'
    DIM=$'\033[2m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'

else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    WHITE=''
    DIM=''
    BOLD=''
    RESET=''
fi

# -----------------------------------------------------------------------------
# Output functions
# -----------------------------------------------------------------------------

print_header() {
    clear 2>/dev/null || true

    echo
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║              Debian 13 System Maintenance                   ║${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${DIM}Host:    $(hostname)${RESET}"
    echo -e "${DIM}Date:    $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${DIM}Kernel:  $(uname -r)${RESET}"
    echo
}

section() {
    echo
    echo -e "${BLUE}${BOLD}┌─ $1${RESET}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────${RESET}"
}

success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

info() {
    echo -e "${CYAN}ℹ $1${RESET}"
}

# -----------------------------------------------------------------------------
# Command existence
# -----------------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Command execution
# -----------------------------------------------------------------------------

run_command() {
    local description="$1"
    shift

    echo
    echo -e "${WHITE}${BOLD}▶ ${description}${RESET}"

    printf '%s' "${DIM}"
    printf '%q ' "$@"
    printf '%s\n' "${RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${MAGENTA}[DRY RUN] Command not executed.${RESET}"
        return 0
    fi

    if [[ "${LOGGING_ENABLED:-false}" == true ]]; then
        if "$@" 2>&1 | tee -a "$LOG_FILE"; then
            success "$description completed."
            return 0
        else
            error "$description failed."
            return 1
        fi
    else
        if "$@"; then
            success "$description completed."
            return 0
        else
            error "$description failed."
            return 1
        fi
    fi
}

# -----------------------------------------------------------------------------
# Argument handling
# -----------------------------------------------------------------------------

usage() {
    cat <<EOF

${BOLD}Usage:${RESET} $SCRIPT_NAME [OPTIONS]

${BOLD}Options:${RESET}

  --dry-run       Simulate APT changes without modifying the packages.
  --no-flatpak    Skip Flatpak updates.
  --no-cleanup    Skip autoremove and APT cache cleanup.
  -h, --help      Show this help.

${BOLD}Examples:${RESET}

  sudo ./$SCRIPT_NAME
  sudo ./$SCRIPT_NAME --dry-run
  sudo ./$SCRIPT_NAME --no-flatpak
  sudo ./$SCRIPT_NAME --no-cleanup

EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;

        --no-flatpak)
            USE_FLATPAK=false
            shift
            ;;

        --no-cleanup)
            DO_CLEANUP=false
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Root check
# -----------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root."
    echo
    echo "Run it with:"
    echo
    echo -e "  ${CYAN}sudo ./$SCRIPT_NAME${RESET}"
    echo
    exit 1
fi

# -----------------------------------------------------------------------------
# OS validation
# -----------------------------------------------------------------------------

if [[ ! -r /etc/os-release ]]; then
    error "Cannot determine operating system."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    error "This script is intended for Debian."
    error "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if [[ "${VERSION_ID:-}" != "13" ]]; then
    warning "This script was designed for Debian 13."
    warning "Detected: ${PRETTY_NAME:-Debian ${VERSION_ID:-unknown}}"
    echo
fi

# -----------------------------------------------------------------------------
# Detect original sudo user
# -----------------------------------------------------------------------------

REAL_USER="${SUDO_USER:-}"

if [[ -n "$REAL_USER" && "$REAL_USER" != "root" ]]; then

    REAL_UID="$(id -u "$REAL_USER" 2>/dev/null || true)"
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

    if [[ -z "$REAL_UID" || -z "$REAL_HOME" ]]; then
        warning "Unable to determine UID/home directory for $REAL_USER."
        REAL_USER=""
        REAL_UID=""
        REAL_HOME=""
    fi

else

    REAL_USER=""
    REAL_UID=""
    REAL_HOME=""

fi

# -----------------------------------------------------------------------------
# Prepare logging
# -----------------------------------------------------------------------------

LOGGING_ENABLED=false

if [[ ! -d "$LOG_DIR" ]]; then
    if mkdir -p "$LOG_DIR" 2>/dev/null; then
        :
    else
        warning "Unable to create $LOG_DIR."
    fi
fi

if touch "$LOG_FILE" 2>/dev/null; then

    LOGGING_ENABLED=true

    {
        echo
        echo "=============================================================="
        echo "Debian Maintenance"
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Host: $(hostname)"
        echo "User: ${REAL_USER:-root}"
        echo "UID: ${REAL_UID:-0}"
        echo "=============================================================="
    } >> "$LOG_FILE"

else

    warning "Unable to write to $LOG_FILE."
    warning "Maintenance will continue without file logging."

fi

# -----------------------------------------------------------------------------
# Configure logrotate
# -----------------------------------------------------------------------------

configure_logrotate() {

    if ! command_exists logrotate; then
        warning "logrotate is not installed."
        warning "Automatic 7-rotation log management cannot be configured."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN: logrotate configuration would be installed at:"
        echo "  $LOGROTATE_FILE"
        return 0
    fi

    cat > "$LOGROTATE_FILE" <<EOF
$LOG_FILE {
    weekly
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF

    chmod 0644 "$LOGROTATE_FILE"

    if logrotate -d "$LOGROTATE_FILE" >/dev/null 2>&1; then
        success "Log rotation configured: 7 weekly rotations."
    else
        warning "Logrotate configuration was written but validation reported a problem."
    fi
}

configure_logrotate

# -----------------------------------------------------------------------------
# Start
# -----------------------------------------------------------------------------

print_header

if [[ "$DRY_RUN" == true ]]; then
    warning "DRY-RUN MODE: package changes will NOT be made."
fi

if [[ -n "$REAL_USER" ]]; then
    info "Desktop user detected: $REAL_USER (UID $REAL_UID)"
else
    info "No non-root sudo user detected."
fi

# =============================================================================
# 1. DISK SPACE PREFLIGHT
# =============================================================================

section "1/9  Checking root filesystem space"

ROOT_USAGE="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"

if [[ -z "$ROOT_USAGE" ]]; then

    error "Unable to determine root filesystem usage."
    MAINTENANCE_FAILED=true
    exit 1

fi

if (( ROOT_USAGE >= 95 )); then

    error "Root filesystem is ${ROOT_USAGE}% full."
    error "Maintenance aborted to avoid package-management problems."
    MAINTENANCE_FAILED=true
    exit 1

elif (( ROOT_USAGE >= 90 )); then

    warning "Root filesystem is ${ROOT_USAGE}% full."
    warning "Consider freeing disk space before performing maintenance."

else

    success "Root filesystem usage: ${ROOT_USAGE}%"

fi

# =============================================================================
# 2. APT / DPKG PREFLIGHT
# =============================================================================

section "2/9  Checking APT and dpkg package state"

# -----------------------------------------------------------------------------
# dpkg audit
# -----------------------------------------------------------------------------

if dpkg --audit; then

    success "dpkg audit passed."

else

    error "dpkg reports packages in an incomplete or problematic state."
    error "Maintenance aborted."
    error "Review the output above before continuing."
    MAINTENANCE_FAILED=true
    exit 1

fi

# -----------------------------------------------------------------------------
# APT check
# -----------------------------------------------------------------------------

if apt-get check; then

    success "APT dependency check passed."

else

    error "APT reports dependency or package-management problems."
    error "Maintenance aborted."
    error "Repair the package state before continuing."
    MAINTENANCE_FAILED=true
    exit 1

fi

# =============================================================================
# 3. APT UPDATE
# =============================================================================

section "3/9  Refreshing Debian package lists"

if [[ "$DRY_RUN" == true ]]; then

    info "DRY RUN: APT package lists would be refreshed."

else

    if ! run_command "Updating APT package lists" \
        apt-get update; then

        error "APT update failed."
        error "Maintenance cannot safely continue."
        MAINTENANCE_FAILED=true
        exit 1

    fi

fi

# =============================================================================
# 4. SYSTEM UPGRADE
# =============================================================================

section "4/9  Upgrading Debian packages"

if [[ "$DRY_RUN" == true ]]; then

    echo
    echo -e "${WHITE}${BOLD}▶ Simulating full system upgrade${RESET}"

    printf '%s' "${DIM}"
    printf '%q ' apt-get --simulate full-upgrade
    printf '%s\n' "${RESET}"

    if apt-get --simulate full-upgrade; then
        success "APT upgrade simulation completed."
    else
        error "APT upgrade simulation failed."
        MAINTENANCE_FAILED=true
    fi

else

    if ! run_command "Performing full system upgrade" \
        apt-get full-upgrade -y; then

        error "The Debian package upgrade failed."
        error "Check the log for details:"
        echo -e "  ${CYAN}$LOG_FILE${RESET}"

        MAINTENANCE_FAILED=true
        exit 1

    fi

fi

# =============================================================================
# 5. FLATPAK
# =============================================================================

section "5/9  Updating Flatpak applications"

if [[ "$USE_FLATPAK" == false ]]; then

    info "Flatpak updates disabled with --no-flatpak."

elif ! command_exists flatpak; then

    info "Flatpak is not installed. Skipping."

else

    # -------------------------------------------------------------------------
    # User Flatpak installation
    # -------------------------------------------------------------------------

    if [[ -n "$REAL_USER" && -n "$REAL_UID" ]]; then

        if [[ "$DRY_RUN" == true ]]; then

            echo
            echo -e "${WHITE}${BOLD}▶ Simulating user Flatpak update${RESET}"
            echo -e "${DIM}User: $REAL_USER (UID $REAL_UID)${RESET}"

            if runuser -u "$REAL_USER" -- \
                env HOME="$REAL_HOME" \
                flatpak update --user --assumeyes --dry-run; then

                success "User Flatpak update simulation completed."

            else

                warning "User Flatpak update simulation failed."
                MAINTENANCE_FAILED=true

            fi

        else

            if ! run_command "Updating user Flatpak applications" \
                runuser -u "$REAL_USER" -- \
                env HOME="$REAL_HOME" \
                flatpak update --user -y; then

                warning "User Flatpak update failed."
                MAINTENANCE_FAILED=true

            fi

        fi

    else

        info "No non-root desktop user detected; skipping user Flatpak updates."

    fi

    # -------------------------------------------------------------------------
    # System Flatpak installation
    # -------------------------------------------------------------------------

    if [[ "$DRY_RUN" == true ]]; then

        echo
        echo -e "${WHITE}${BOLD}▶ Simulating system Flatpak update${RESET}"

        if flatpak update --system --assumeyes --dry-run; then
            success "System Flatpak update simulation completed."
        else
            warning "System Flatpak update simulation failed."
            MAINTENANCE_FAILED=true
        fi

    else

        if ! run_command "Updating system Flatpak applications" \
            flatpak update --system -y; then

            warning "System Flatpak update failed."
            MAINTENANCE_FAILED=true

        fi

    fi

fi

# =============================================================================
# 6. REMOVE UNUSED PACKAGES / CLEAN APT CACHE
# =============================================================================

section "6/9  Cleaning unused APT packages"

if [[ "$DO_CLEANUP" == false ]]; then

    info "Cleanup disabled with --no-cleanup."

else

    # -------------------------------------------------------------------------
    # Autoremove simulation / execution
    # -------------------------------------------------------------------------

    if [[ "$DRY_RUN" == true ]]; then

        echo
        echo -e "${WHITE}${BOLD}▶ Simulating APT autoremove${RESET}"

        if apt-get --simulate autoremove; then
            success "APT autoremove simulation completed."
        else
            warning "APT autoremove simulation failed."
            MAINTENANCE_FAILED=true
        fi

    else

        if ! run_command "Removing unused APT dependencies" \
            apt-get autoremove -y; then

            warning "APT autoremove failed."
            MAINTENANCE_FAILED=true

        fi

    fi

    # -------------------------------------------------------------------------
    # Autoclean
    # -------------------------------------------------------------------------

    if [[ "$DRY_RUN" == true ]]; then

        info "DRY RUN: APT autoclean would be performed."

    else

        if ! run_command "Cleaning obsolete downloaded packages" \
            apt-get autoclean; then

            warning "APT autoclean failed."
            MAINTENANCE_FAILED=true

        fi

    fi

fi

# =============================================================================
# 7. FLATPAK REPOSITORY DIAGNOSTICS
# =============================================================================

section "7/9  Flatpak repository diagnostics"

if [[ "$USE_FLATPAK" == false ]]; then

    info "Flatpak diagnostics skipped with --no-flatpak."

elif ! command_exists flatpak; then

    info "Flatpak is not installed. Skipping."

else

    echo
    echo -e "${WHITE}${BOLD}Configured Flatpak remotes:${RESET}"
    echo

    if flatpak remotes --show-details; then
        success "Flatpak remote information displayed."
    else
        warning "Unable to display Flatpak remote information."
        MAINTENANCE_FAILED=true
    fi

fi

# =============================================================================
# 8. SYSTEM INFORMATION
# =============================================================================

section "8/9  System information"

if command_exists fastfetch; then

    echo
    fastfetch

else

    warning "fastfetch is not installed."
    info "Install it with: apt install fastfetch"

fi

# =============================================================================
# REBOOT CHECK
# =============================================================================

section "Reboot status"

if [[ -f /run/reboot-required ]]; then

    warning "A reboot has been requested by the Debian reboot-required mechanism."

    if [[ -f /run/reboot-required.pkgs ]]; then

        echo
        echo "Packages requesting reboot:"
        cat /run/reboot-required.pkgs

    fi

else

    success "No reboot has been requested by the Debian reboot-required mechanism."

fi

# =============================================================================
# 9. DISK SPACE
# =============================================================================

section "9/9  Disk usage"

echo
echo -e "${WHITE}${BOLD}Filesystem usage:${RESET}"

if ! df -h /; then

    warning "Unable to determine disk usage."
    MAINTENANCE_FAILED=true

fi

# =============================================================================
# PACKAGE CHANGE SUMMARY
# =============================================================================

section "Package change summary"

show_package_summary() {

    local history="/var/log/apt/history.log"
    local transaction
    local upgrades=0
    local installs=0
    local removals=0
    local downgrades=0
    local configures=0

    if [[ ! -r "$history" ]]; then
        warning "APT history log is unavailable."
        return 0
    fi

    transaction="$(
        awk '
            /^Start-Date:/ {
                block = $0 ORS
                inblock = 1
                next
            }

            inblock {
                block = block $0 ORS
            }

            /^End-Date:/ {
                last = block
                inblock = 0
            }

            END {
                printf "%s", last
            }
        ' "$history"
    )"

    if [[ -z "$transaction" ]]; then
        info "No completed APT transaction was found."
        return 0
    fi

    count_entries() {
        local line="$1"

        if [[ -z "$line" ]]; then
            echo 0
            return
        fi

        # Remove the field label.
        line="${line#*:}"

        # Count comma-separated package entries.
        awk -F',' '{
            count = 0

            for (i = 1; i <= NF; i++) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)

                if ($i != "")
                    count++
            }

            print count
        }' <<< "$line"
    }

    upgrades="$(count_entries "$(grep '^Upgrade:' <<< "$transaction" || true)")"
    installs="$(count_entries "$(grep '^Install:' <<< "$transaction" || true)")"
    removals="$(count_entries "$(grep '^Remove:' <<< "$transaction" || true)")"
    downgrades="$(count_entries "$(grep '^Downgrade:' <<< "$transaction" || true)")"
    configures="$(count_entries "$(grep '^Purge:' <<< "$transaction" || true)")"

    echo
    printf "  ${GREEN}%-14s${RESET}%s\n" "Upgraded:" "$upgrades"
    printf "  ${CYAN}%-14s${RESET}%s\n" "Installed:" "$installs"
    printf "  ${RED}%-14s${RESET}%s\n" "Removed:" "$removals"
    printf "  ${YELLOW}%-14s${RESET}%s\n" "Downgraded:" "$downgrades"
    printf "  ${MAGENTA}%-14s${RESET}%s\n" "Purged:" "$configures"


    echo
    echo -e "${DIM}Source: $history${RESET}"
}

if [[ "$DRY_RUN" == true ]]; then

    info "DRY RUN: no package transaction was performed."
    info "The package summary therefore reflects the most recent completed APT transaction, if available."

fi

show_package_summary

# =============================================================================
# FINAL LOGGING
# =============================================================================

if [[ "$LOGGING_ENABLED" == true ]]; then

    {
        echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Maintenance failures: $MAINTENANCE_FAILED"
        echo
    } >> "$LOG_FILE"

fi

# =============================================================================
# FINAL STATUS
# =============================================================================

echo

if [[ "$MAINTENANCE_FAILED" == true ]]; then

    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}║              MAINTENANCE COMPLETED WITH WARNINGS            ║${RESET}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"

else

    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}║                 MAINTENANCE COMPLETE                        ║${RESET}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"

fi

echo

if [[ "$LOGGING_ENABLED" == true ]]; then
    echo -e "${DIM}Log: $LOG_FILE${RESET}"
    echo -e "${DIM}Log rotation: 7 weekly rotations${RESET}"
else
    echo -e "${DIM}File logging unavailable.${RESET}"
fi

echo

if [[ "$MAINTENANCE_FAILED" == true ]]; then
    exit 1
fi

exit 0
