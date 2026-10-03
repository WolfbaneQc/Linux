#!/usr/bin/env bash

# =============================================================================
# Debian 13 Virtualization Configuration Module
# =============================================================================
#
# Purpose:
#   Configures the QEMU/KVM/libvirt virtualization environment installed by
#   the APT package module.
#
#   This module:
#     - Adds the current user to the libvirt and kvm groups.
#     - Enables and starts the libvirtd service.
#     - Configures the libvirt default network.
#
#   Package installation is handled by apt.sh.
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
