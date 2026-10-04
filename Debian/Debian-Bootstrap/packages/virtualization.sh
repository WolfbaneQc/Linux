#!/usr/bin/env bash

# =============================================================================
# Debian 13 Virtualization Configuration Module
# =============================================================================
#
# Purpose:
#   Configures the QEMU/KVM/libvirt virtualization environment installed by
#   apt.sh.
#
#   This module:
#     - Adds the current user to the libvirt and kvm groups.
#     - Enables and starts the libvirtd service.
#     - Configures the libvirt default network.
#     - Verifies the resulting libvirt network configuration.
#
#   Package installation is handled by apt.sh.
#
#   Firewall configuration is handled separately by security.sh.
#
#   This script is intended to be called by setup.sh.
#
#   Note:
#     A logout/login or reboot is required before the current user session
#     receives newly added group memberships.
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

    printf '%s\n' "[OK] libvirt default network exists."

    if sudo virsh net-info default | grep -q '^Active:.*yes'; then

        printf '%s\n' "[OK] libvirt default network is already active."

    else

        printf '%s\n' "Starting libvirt default network..."

        sudo virsh net-start default

        printf '%s\n' "[OK] libvirt default network started."

    fi

    printf '%s\n' "Configuring default network for automatic startup..."

    sudo virsh net-autostart default

    printf '%s\n' \
        "[OK] libvirt default network configured for automatic startup."

else

    printf '%s\n' '[ERROR] libvirt default network was not found.'
    printf '%s\n' \
        '        The default libvirt network is required by this bootstrap.'
    printf '%s\n' \
        '        Check the libvirt network configuration.'

    exit 1

fi


# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying libvirt configuration..."

if ! sudo virsh net-info default | grep -q '^Active:.*yes'; then

    printf '%s\n' \
        '[ERROR] libvirt default network is not active.'

    exit 1

fi

if ! sudo virsh net-info default | grep -q '^Autostart:.*yes'; then

    printf '%s\n' \
        '[ERROR] libvirt default network is not configured for autostart.'

    exit 1

fi

printf '%s\n' '[OK] libvirt default network is active.'
printf '%s\n' '[OK] libvirt default network is configured for autostart.'


# -----------------------------------------------------------------------------
# Display Network Status
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Current libvirt networks:"

sudo virsh net-list --all


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Virtualization configuration completed successfully.'
