#!/usr/bin/env bash
# Temporary Linux/TrueNAS bootstrap test.
#
# This exercises the Linux setup path through installation of Mise, chezmoi, and
# the 1Password CLI, then signs in to 1Password and applies the specified
# dotfiles branch.

set -Eeuo pipefail

declare -r DOTFILES_REPO_URL="git@github.com:ishioni/dotfiles.git"
declare -r DOTFILES_BRANCH="mise-linux-truenas"
declare -r CHEZMOI_SOURCE_DIR="${HOME}/.local/share/chezmoi"

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

function authenticate_1password() {
  echo "Configuring 1Password CLI..."
  op account add --address my.1password.com
  eval "$(op signin)"
}

function initialize_chezmoi() {
  if [[ -e "${CHEZMOI_SOURCE_DIR}" ]]; then
    echo "Chezmoi source directory already exists: ${CHEZMOI_SOURCE_DIR}" >&2
    echo "This test requires a clean Chezmoi source directory to guarantee the ${DOTFILES_BRANCH} branch is used." >&2
    exit 1
  fi

  echo "Initializing Chezmoi from ${DOTFILES_REPO_URL} (${DOTFILES_BRANCH})..."
  chezmoi init --branch "${DOTFILES_BRANCH}" --guess-repo-url=false "${DOTFILES_REPO_URL}"

  if [[ "$(git -C "${CHEZMOI_SOURCE_DIR}" branch --show-current)" != "${DOTFILES_BRANCH}" ]]; then
    echo "Chezmoi did not check out the expected branch: ${DOTFILES_BRANCH}" >&2
    exit 1
  fi

  chezmoi apply
}

initialize_linux
install_mise
install_chezmoi
install_1password_cli
authenticate_1password
initialize_chezmoi

printf '\nLinux bootstrap test complete.\n'
printf 'Mise:      %s\n' "$(mise --version)"
printf 'Chezmoi:   %s\n' "$(chezmoi --version)"
printf '1Password: %s\n' "$(op --version)"
printf 'Dotfiles branch: %s\n' "${DOTFILES_BRANCH}"
