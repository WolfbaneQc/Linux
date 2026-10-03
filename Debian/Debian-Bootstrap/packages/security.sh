#!/usr/bin/env bash

# =============================================================================
# Debian 13 Security Configuration Module
# =============================================================================
#
# Purpose:
#   Applies the basic firewall security policy for the Debian workstation.
#
#   This module:
#     - Verifies that UFW is installed.
#     - Denies incoming connections by default.
#     - Allows outgoing connections by default.
#     - Enables UFW.
#     - Verifies the resulting firewall status.
#
#   GUFW is the graphical frontend. UFW is the firewall being configured.
#
#   This script is intended to be called by setup.sh after the required
#   packages have been installed.
#
#   Note:
#     Virtual machine networking may require additional UFW/libvirt rules.
#     Those rules are intentionally NOT added here until virtualization.sh
#     has been reviewed.
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Checking firewall prerequisites..."


if ! command -v ufw >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] UFW is not installed.'
    printf '%s\n' '        Run apt.sh before running security.sh.'
    exit 1
fi


printf '%s\n' '[OK] UFW is installed.'


# -----------------------------------------------------------------------------
# Default Firewall Policy
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Configuring firewall policy..."

printf '%s\n' "Default incoming policy: DENY"
sudo ufw default deny incoming

printf '%s\n' "Default outgoing policy: ALLOW"
sudo ufw default allow outgoing


# -----------------------------------------------------------------------------
# Firewall Activation
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Enabling firewall..."

sudo ufw --force enable


# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying firewall configuration..."

if ! sudo ufw status | grep -q '^Status: active'; then
    printf '%s\n' '[ERROR] UFW is not active.'
    exit 1
fi


printf '%s\n' '[OK] UFW is active.'


# -----------------------------------------------------------------------------
# Display Firewall Status
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Current firewall status:"

sudo ufw status verbose


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Security configuration completed successfully.'
