#!/usr/bin/env bash

# =============================================================================
# Debian 13 APT Package Installation Module
# =============================================================================
#
# Purpose:
#   Installs the Debian packages required by the bootstrap environment.
#
#   This module is responsible only for installing APT packages.
#
#   Configuration and application-specific setup are handled by the
#   respective modules:
#
#     virtualization.sh  - QEMU / KVM / libvirt configuration
#     security.sh        - UFW firewall configuration
#     flatpak.sh         - Flathub configuration and Flatpak applications
#     rust.sh            - Rust / Cargo toolchain
#     privacy.sh         - Privacy applications and tools
#
#   This script is intended to be called by setup.sh.
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Package Groups
# -----------------------------------------------------------------------------


# General utilities
GENERAL_PACKAGES=(
    curl
    fastfetch
    gufw
)


# Development tools and libraries
DEVELOPMENT_PACKAGES=(
    build-essential
    pkg-config
    libssl-dev
)


# Security and binary analysis
SECURITY_PACKAGES=(
    binwalk
    wireshark
)


# Virtualization
#
# These packages provide the virtualization environment.
# Configuration is handled separately by virtualization.sh.
#
VIRTUALIZATION_PACKAGES=(
    qemu-system-x86
    qemu-utils
    qemu-system-gui
    libvirt-daemon-system
    libvirt-daemon-driver-qemu
    libvirt-clients
    virt-manager
    virtinst
    dnsmasq-base
    bridge-utils
    cpu-checker
)


# Flatpak and GNOME Software integration
#
# Flatpak applications are installed separately by flatpak.sh
# or by other application-specific modules such as privacy.sh.
#
FLATPAK_PACKAGES=(
    flatpak
    gnome-software
    gnome-software-plugin-flatpak
)


# Rust toolchain
#
# rustup provides the Rust toolchain manager.
# Rust configuration is handled separately by rust.sh.
#
RUST_PACKAGES=(
    rustup
)


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

install_packages() {
    local group_name="$1"
    shift

    local packages=("$@")

    printf '\n'
    printf '%s\n' "Installing $group_name packages..."

    sudo apt-get install -y "${packages[@]}"
}


# -----------------------------------------------------------------------------
# APT Update
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Updating APT package information..."

sudo apt-get update


# -----------------------------------------------------------------------------
# System Upgrade
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Upgrading installed Debian packages..."

sudo apt-get upgrade -y


# -----------------------------------------------------------------------------
# Package Installation
# -----------------------------------------------------------------------------

install_packages "general utility" \
    "${GENERAL_PACKAGES[@]}"

install_packages "development" \
    "${DEVELOPMENT_PACKAGES[@]}"

install_packages "security and binary analysis" \
    "${SECURITY_PACKAGES[@]}"

install_packages "virtualization" \
    "${VIRTUALIZATION_PACKAGES[@]}"

install_packages "Flatpak" \
    "${FLATPAK_PACKAGES[@]}"

install_packages "Rust" \
    "${RUST_PACKAGES[@]}"


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] APT package installation completed successfully.'
