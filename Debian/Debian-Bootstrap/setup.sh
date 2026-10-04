#!/usr/bin/env bash

# =============================================================================
# Debian 13 System Bootstrap Script
# =============================================================================
#
# Purpose:
#   A personal Debian 13 bootstrap script for preparing a fresh Debian
#   installation with the software, development tools, virtualization
#   environment, Flatpak applications, Rust toolchain, privacy tools, and
#   basic firewall configuration used in WolfbaneQc's preferred Debian
#   workstation setup.
#
#   This script is the main entry point for the bootstrap process and
#   executes the individual installation/configuration modules in the
#   required order.
#
# =============================================================================
#
# Structure:
#
#   setup.sh
#       Main entry point. Performs prerequisite checks and calls each module.
#
#   packages/
#       Individual installation and configuration modules.
#
# Execution order:
#
#   1. System and APT packages
#   2. QEMU / KVM / libvirt virtualization
#   3. Basic firewall configuration
#   4. Flatpak and Flathub applications
#   5. Rust toolchain
#   6. Privacy tools and applications
#
# Usage:
#
#   ./setup.sh
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/packages"


# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

if [[ -t 1 ]]; then
    BLUE='\033[1;34m'
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    RESET='\033[0m'
else
    BLUE=''
    GREEN=''
    RED=''
    RESET=''
fi


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

log() {
    printf '\n%b==> %s%b\n' "$BLUE" "$1" "$RESET"
}


success() {
    printf '%b[OK]%b %s\n' "$GREEN" "$RESET" "$1"
}


die() {
    printf '%b[ERROR]%b %s\n' "$RED" "$RESET" "$1" >&2
    exit 1
}


run_module() {
    local module="$1"
    local path="$MODULE_DIR/$module"

    if [[ ! -f "$path" ]]; then
        die "Missing module: $path"
    fi

    if [[ ! -x "$path" ]]; then
        die "Module is not executable: $path"
    fi

    log "Running $module"

    "$path"

    success "$module completed successfully."
}


# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------

log "Checking prerequisites"


# Do not run the bootstrap as root.
if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run setup.sh as root."
fi


# Verify the operating-system information file exists.
if [[ ! -r /etc/os-release ]]; then
    die "Cannot determine operating system."
fi


# Load Debian release information.
# shellcheck disable=SC1091
source /etc/os-release


# Verify Debian.
if [[ "${ID:-}" != "debian" ]]; then
    die "This script is intended for Debian."
fi


# Verify Debian 13 / Trixie.
if [[ "${VERSION_CODENAME:-}" != "trixie" ]]; then
    die "This script targets Debian 13 (Trixie)."
fi


# Verify sudo.
if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required."
fi


# Verify the module directory.
if [[ ! -d "$MODULE_DIR" ]]; then
    die "Module directory not found: $MODULE_DIR"
fi


# Verify sudo access before starting.
if ! sudo -v; then
    die "Unable to obtain sudo access."
fi


success "Debian 13 (Trixie) detected."
success "sudo access confirmed."
success "Module directory confirmed."


# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

log "Starting Debian bootstrap"


# Refresh sudo authentication before beginning the installation.
#
# The bootstrap may take a considerable amount of time. Refreshing the
# sudo timestamp here reduces the chance of a later module failing because
# the sudo authentication timestamp expired.
if ! sudo -v; then
    die "sudo authentication failed."
fi


run_module "apt.sh"
run_module "virtualization.sh"
run_module "security.sh"
run_module "flatpak.sh"
run_module "rust.sh"
run_module "privacy.sh"


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

log "Bootstrap completed"


printf '\n'
printf '%bAll installation and configuration modules completed successfully.%b\n' \
    "$GREEN" "$RESET"


printf '\n'
printf '%s\n' \
    'A new login session is required for libvirt and KVM group membership changes to take effect.'


printf '\n'
printf '%s\n' \
    'Log out and log back in, or reboot the system, before using libvirt/KVM as your normal user.'
