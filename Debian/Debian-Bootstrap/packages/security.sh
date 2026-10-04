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
#     - Verifies that UFW is active.
#     - Verifies the configured default policies.
#     - Displays the resulting firewall configuration.
#
#   GUFW is the graphical frontend.
#   UFW is the firewall being configured.
#
#   This script is intended to be called by setup.sh after virtualization.sh.
#
#   Note:
#     Libvirt manages firewall rules required for its virtual networks.
#     This module intentionally does not add custom libvirt firewall rules.
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


if ! command -v systemctl >/dev/null 2>&1; then

    printf '%s\n' '[ERROR] systemctl was not found.'
    printf '%s\n' '        This script requires a systemd-based Debian installation.'
    exit 1

fi


printf '%s\n' '[OK] UFW is installed.'
printf '%s\n' '[OK] systemctl is available.'


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
# Verification: Firewall Status
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying firewall status..."


if ! sudo ufw status | grep -q '^Status: active'; then

    printf '%s\n' '[ERROR] UFW is not active.'
    exit 1

fi


printf '%s\n' '[OK] UFW is active.'


# -----------------------------------------------------------------------------
# Verification: Default Policies
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying default firewall policies..."


if ! sudo ufw status verbose | grep -q 'Default: deny (incoming)'; then

    printf '%s\n' '[ERROR] Default incoming policy is not DENY.'
    exit 1

fi


if ! sudo ufw status verbose | grep -q 'allow (outgoing)'; then

    printf '%s\n' '[ERROR] Default outgoing policy is not ALLOW.'
    exit 1

fi


printf '%s\n' '[OK] Incoming connections are denied by default.'
printf '%s\n' '[OK] Outgoing connections are allowed by default.'


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
