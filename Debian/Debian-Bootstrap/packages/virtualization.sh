#!/usr/bin/env bash

# =============================================================================
# Debian 13 Flatpak Installation Module
# =============================================================================
#
# Purpose:
#   Configures Flathub and installs the general-purpose Flatpak applications
#   used in WolfbaneQc's preferred Debian workstation setup.
#
#   Flatpak itself and GNOME Software integration are installed by apt.sh.
#
#   Applications are installed system-wide from the Flathub repository.
#
#   Privacy-related applications are handled separately by privacy.sh.
#
#   Application versions are intentionally not specified. The current version
#   available from Flathub will be installed.
#
#   This script is intended to be called by setup.sh.
#
# =============================================================================



set -Eeuo pipefail


# -----------------------------------------------------------------------------
# User Groups
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Configuring KVM/libvirt user groups..."

sudo usermod -aG libvirt,kvm "$USER"

printf '%s\n' "[OK] $USER added to libvirt and kvm groups."


# -----------------------------------------------------------------------------
# libvirt Service
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Enabling and starting libvirtd..."

sudo systemctl enable --now libvirtd.service

printf '%s\n' "[OK] libvirtd service is enabled and running."


# -----------------------------------------------------------------------------
# Default libvirt Network
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Checking libvirt default network..."

if sudo virsh net-info default >/dev/null 2>&1; then

    if sudo virsh net-info default | grep -q '^Active:.*yes'; then
        printf '%s\n' "[OK] libvirt default network is already active."
    else
        sudo virsh net-start default
        printf '%s\n' "[OK] libvirt default network started."
    fi

    sudo virsh net-autostart default

    printf '%s\n' "[OK] libvirt default network configured for automatic startup."

else
    printf '%s\n' "[WARN] libvirt default network was not found."
    printf '%s\n' "       Check the libvirt network configuration."
fi


# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Current libvirt networks:"

sudo virsh net-list --all


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Virtualization configuration completed successfully.'
