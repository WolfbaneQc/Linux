#!/usr/bin/env bash

# =============================================================================
# Debian 13 Privacy Tools Installation Module
# =============================================================================
#
# Purpose:
#   Installs the privacy-related applications and tools used in
#   WolfbaneQc's preferred Debian workstation setup.
#
#   This module installs software using the appropriate tool:
#
#     Flatpak:
#       - Proton VPN
#       - Tor Browser Launcher
#
#     Cargo:
#       - oniux
#
#   Flatpak and Flathub are configured by flatpak.sh.
#   Rust and Cargo are configured by rust.sh.
#
#   This script is intended to be called by setup.sh after flatpak.sh
#   and rust.sh have completed successfully.
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Checking privacy tool prerequisites..."


# Flatpak
if ! command -v flatpak >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] Flatpak is not installed.'
    printf '%s\n' '        Run apt.sh and flatpak.sh first.'
    exit 1
fi


# Flathub
if ! sudo flatpak remote-list | awk '{print $1}' | grep -qx 'flathub'; then
    printf '%s\n' '[ERROR] Flathub is not configured.'
    printf '%s\n' '        Run flatpak.sh before privacy.sh.'
    exit 1
fi


# Cargo
if ! command -v cargo >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] Cargo is not available.'
    printf '%s\n' '        Run rust.sh before privacy.sh.'
    exit 1
fi


printf '%s\n' '[OK] Privacy tool prerequisites confirmed.'


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

install_flatpak_application() {
    local application_id="$1"
    local application_name="$2"

    printf '\n'
    printf '%s\n' "Checking $application_name..."

    if sudo flatpak info "$application_id" >/dev/null 2>&1; then

        printf '%s\n' "[OK] $application_name is already installed."

    else

        printf '%s\n' "Installing $application_name..."

        sudo flatpak install \
            -y \
            flathub \
            "$application_id"

        printf '%s\n' "[OK] $application_name installed."

    fi
}


# -----------------------------------------------------------------------------
# Privacy Applications
# -----------------------------------------------------------------------------
#
# These applications are installed system-wide from Flathub.
#
# -----------------------------------------------------------------------------


printf '\n'
printf '%s\n' "Installing privacy applications..."


# Proton VPN
install_flatpak_application \
    "com.protonvpn.www" \
    "Proton VPN"


# Tor Browser Launcher
install_flatpak_application \
    "org.torproject.torbrowser-launcher" \
    "Tor Browser Launcher"


# -----------------------------------------------------------------------------
# oniux
# -----------------------------------------------------------------------------
#
# oniux is installed from the official Tor Project Git repository using Cargo.
#
# The version is intentionally pinned so that the bootstrap remains
# reproducible.
#
# -----------------------------------------------------------------------------


ONIUX_VERSION="v0.10.0"


printf '\n'
printf '%s\n' "Installing oniux..."


if command -v oniux >/dev/null 2>&1; then

    printf '%s\n' '[OK] oniux is already installed.'

else

    cargo install \
        --locked \
        --git https://gitlab.torproject.org/tpo/core/oniux \
        --tag "$ONIUX_VERSION" \
        oniux

    printf '%s\n' '[OK] oniux installed.'

fi


# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying privacy tools..."


# Proton VPN
if sudo flatpak info "com.protonvpn.www" >/dev/null 2>&1; then
    printf '%s\n' '[OK] Proton VPN verified.'
else
    printf '%s\n' '[ERROR] Proton VPN verification failed.'
    exit 1
fi


# Tor Browser Launcher
if sudo flatpak info "org.torproject.torbrowser-launcher" >/dev/null 2>&1; then
    printf '%s\n' '[OK] Tor Browser Launcher verified.'
else
    printf '%s\n' '[ERROR] Tor Browser Launcher verification failed.'
    exit 1
fi


# oniux
if command -v oniux >/dev/null 2>&1; then
    printf '%s\n' '[OK] oniux verified.'
    oniux --version
else
    printf '%s\n' '[ERROR] oniux verification failed.'
    exit 1
fi


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Privacy tools installation completed successfully.'
