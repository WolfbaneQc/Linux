#!/usr/bin/env bash

# =============================================================================
# Debian 13 Rust Toolchain Module
# =============================================================================
#
# Purpose:
#   Configures the Rust development environment using the rustup package
#   provided by Debian.
#
#   This module:
#     - Verifies that rustup is installed.
#     - Initializes rustup for the current user.
#     - Configures the stable Rust toolchain.
#     - Verifies rustc and cargo.
#
#   Rust-based applications and tools are installed by their respective
#   modules. For example, oniux is handled by privacy.sh.
#
#   This script is intended to be called by setup.sh.
#
# =============================================================================


set -Eeuo pipefail


# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------

if ! command -v rustup >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] rustup is not installed.'
    printf '%s\n' '        Run apt.sh before running rust.sh.'
    exit 1
fi


# -----------------------------------------------------------------------------
# Rustup Initialization
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Configuring rustup..."

if [[ ! -f "$HOME/.cargo/env" ]]; then

    rustup default stable

else

    printf '%s\n' '[OK] rustup is already initialized.'

fi


# -----------------------------------------------------------------------------
# Load Cargo Environment
# -----------------------------------------------------------------------------

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
else
    printf '%s\n' '[ERROR] Rust environment file was not created.'
    exit 1
fi


# -----------------------------------------------------------------------------
# Stable Toolchain
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Configuring stable Rust toolchain..."

rustup default stable

printf '%s\n' '[OK] Stable Rust toolchain configured.'


# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' "Verifying Rust installation..."

if ! command -v rustc >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] rustc was not found.'
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] cargo was not found.'
    exit 1
fi

printf '%s\n' 'Rust version:'
rustc --version

printf '%s\n' 'Cargo version:'
cargo --version


# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------

printf '\n'
printf '%s\n' '[OK] Rust toolchain installation completed successfully.'
