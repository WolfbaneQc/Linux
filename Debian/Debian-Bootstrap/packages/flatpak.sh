#!/usr/bin/env bash

# =============================================================================
# Debian 13 Flatpak Installation Module
# =============================================================================
#
# Purpose:
#   Configures Flathub and installs the Flatpak applications used in
#   WolfbaneQc's preferred Debian workstation setup.
#
#   Flatpak itself and GNOME Software integration are installed by apt.sh.
#
#   Application versions are intentionally not specified. The current version
#   available from Flathub will be installed.
#
#   This script is intended to be called by setup.sh.
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------

if ! command -v flatpak >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] Flatpak is not installed.'
    printf '%s\n' '        Run apt.sh before running flatpak.sh.'
    exit 1
fi


# -----------------------------------------------------------------------------
# Flatpak Applications
# -----------------------------------------------------------------------------
#
# Flatpak requires an Application ID when installing software.
#
# The application names are included as comments so that this list remains
# easy to understand and maintain.
#
# Flatpak runtimes and dependencies are NOT listed here. They are installed
# automatically by Flatpak when required by an application.
#
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Web Browsers
# -----------------------------------------------------------------------------

BROWSER_APPS=(
    # Chromium
    "org.chromium.Chromium"

    # Ungoogled Chromium
    "io.github.ungoogled_software.ungoogled_chromium"

    # LibreWolf
    "io.gitlab.librewolf-community"

    # Mullvad Browser
    "net.mullvad.MullvadBrowser"
)


# -----------------------------------------------------------------------------
# Privacy and Networking
# -----------------------------------------------------------------------------

PRIVACY_APPS=(
    # Proton VPN
    "com.protonvpn.www"

    # Tor Browser Launcher
    "org.torproject.torbrowser-launcher"
)


# -----------------------------------------------------------------------------
# Development
# -----------------------------------------------------------------------------

DEVELOPMENT_APPS=(
    # VSCodium
    "com.vscodium.codium"
)


# -----------------------------------------------------------------------------
# Network and File Transfer
# -----------------------------------------------------------------------------

NETWORK_APPS=(
    # Transmission
    "com.transmissionbt.Transmission"
)


# -----------------------------------------------------------------------------
# Graphics and Media
# -----------------------------------------------------------------------------

MEDIA_APPS=(
    # Pinta
    "com.github.PintaProject.Pinta"

    # VLC
    "org.videolan.VLC"

    # Amberol
    "io.bassi.Amberol"
)


# -----------------------------------------------------------------------------
# System Utilities
# -----------------------------------------------------------------------------

SYSTEM_APPS=(
    # Fedora Media Writer
    "org.fedoraproject.MediaWriter"
)


# -----------------------------------------------------------------------------
# GNOME Games
# -----------------------------------------------------------------------------

GAME_APPS=(
    # Aisleriot Solitaire
    "org.gnome.Aisleriot"

    # GNOME Mines
    "org.gnome.Mines"
)


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

install_flatpak_group() {
    local group_name="$1"
    shift

    local apps=("$@")

    printf '\n'
    printf '%s\n' "Installing $group_name Flatpak applications..."

    for app in "${apps[@]}"; do

        if sudo flatpak info "$app" >/dev/null 2>&1; then
            printf '%s\n' "[OK] $app is already installed."
        else
            printf '%s\n' "Installing $app..."

            sudo flatpak install \
                -y \
                flathub \
                "$app"

            printf '%s\n' "[OK] $app installed."
        fi

    done
}


# -----------------------------------------------------------------------------
# Flathub Configuration
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Configuring Flathub..."

if sudo flatpak remote-list | awk '{print $1}' | grep -qx 'flathub'; then

    printf '%s\n' "[OK] Flathub is already configured."

else

    sudo flatpak remote-add \
        --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    printf '%s\n' "[OK] Flathub configured."

fi


# -----------------------------------------------------------------------------
# Application Installation
# -----------------------------------------------------------------------------

install_flatpak_group \
    "Web Browser" \
    "${BROWSER_APPS[@]}"

install_flatpak_group \
    "Privacy and Networking" \
    "${PRIVACY_APPS[@]}"

install_flatpak_group \
    "Development" \
    "${DEVELOPMENT_APPS[@]}"

install_flatpak_group \
    "Network and File Transfer" \
    "${NETWORK_APPS[@]}"

install_flatpak_group \
    "Graphics and Media" \
    "${MEDIA_APPS[@]}"

install_flatpak_group \
    "System Utility" \
    "${SYSTEM_APPS[@]}"

install_flatpak_group \
    "GNOME Game" \
    "${GAME_APPS[@]}"


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Flatpak configuration and application installation completed.'
