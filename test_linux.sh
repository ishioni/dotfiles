#!/usr/bin/env bash
# Temporary Linux/TrueNAS bootstrap test.
#
# This exercises the Linux setup path through installation of Mise, chezmoi, and
# the 1Password CLI. It intentionally does not authenticate 1Password or run
# chezmoi init/apply.

set -Eeuo pipefail

if [[ "$(uname)" != "Linux" ]]; then
  echo "This test script only supports Linux." >&2
  exit 1
fi

function initialize_linux() {
  echo "Initializing Linux..."

  if [[ "$(uname -r)" == *"+truenas" ]]; then
    echo "TrueNAS detected: using a user-local Mise toolchain."
  fi
}

function install_mise() {
  local mise_bin="${HOME}/.local/bin/mise"

  if [[ -x "${mise_bin}" ]]; then
    echo "Mise is already installed."
  else
    curl https://mise.run | sh
  fi

  export PATH="${HOME}/.local/bin:${PATH}"
  eval "$("${mise_bin}" activate bash --shims)"
}

function install_chezmoi() {
  if mise which chezmoi >/dev/null 2>&1; then
    echo "Chezmoi is already installed."
  else
    mise use --global --pin chezmoi@latest
    mise reshim
  fi
}

function install_1password_cli() {
  if mise which op >/dev/null 2>&1; then
    echo "1Password CLI is already installed."
  else
    mise use --global --pin 1password-cli@2.35.0
    mise reshim
  fi
}

initialize_linux
install_mise
install_chezmoi
install_1password_cli

printf '\nLinux bootstrap test complete.\n'
printf 'Mise:     %s\n' "$(mise --version)"
printf 'Chezmoi:  %s\n' "$(chezmoi --version)"
printf '1Password: %s\n' "$(op --version)"
printf '\nDeliberately skipped:\n'
printf '%s\n' '  - op account add / op signin'
printf '%s\n' '  - chezmoi init / chezmoi apply'
