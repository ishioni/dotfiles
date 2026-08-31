#!/usr/bin/env bash

set -Eeuo pipefail

declare -r DOTFILES_REPO_URL="https://github.com/ishioni/dotfiles"
declare ostype="$(uname)"

function initialize_os_env() {
  if [[ "${ostype}" == "Darwin" ]]; then
    initialize_macos
  elif [[ "${ostype}" == "Linux" ]]; then
    initialize_linux
  else
    echo "Invalid OS type: ${ostype}" >&2
    exit 1
  fi
}

function initialize_macos() {
  function install_xcode() {
    local git_cmd_path
    git_cmd_path="$(command -v git || true)"

    if [[ -z "${git_cmd_path}" ]]; then
      xcode-select --install
      read -r -p "Press any key when the installation has completed." -n 1
    else
      echo "Command line developer tools are installed."
    fi
  }

  function install_rosetta() {
    sudo softwareupdate --agree-to-license --install-rosetta
  }

  echo "Initializing macOS..."
  install_xcode
  install_rosetta
}

function initialize_linux() {
  echo "Initializing Linux..."

  if [[ "$(uname -r)" == *"+truenas" ]]; then
    echo "TrueNAS detected: using a user-local Mise toolchain."
  fi
}

function install_homebrew() {
  export HOMEBREW_CASK_OPTS=--no-quarantine

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "Homebrew is already installed."
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"
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
  if [[ "${ostype}" == "Linux" ]]; then
    if mise which chezmoi >/dev/null 2>&1; then
      echo "Chezmoi is already installed."
    else
      mise use --global --pin chezmoi@latest
      mise reshim
    fi
  elif command -v chezmoi >/dev/null 2>&1; then
    echo "Chezmoi is already installed."
  else
    brew install chezmoi
  fi
}

function install_1password() {
  if [[ "${ostype}" == "Linux" ]]; then
    if mise which op >/dev/null 2>&1; then
      echo "1Password CLI is already installed."
    else
      mise use --global --pin 1password-cli@2.35.0
      mise reshim
    fi

    op account add --address my.1password.com
    eval "$(op signin)"
  elif command -v op >/dev/null 2>&1; then
    echo "1Password CLI is already installed."
    read -r -p "Please open 1Password, log into all accounts, and enable Integrate with 1Password CLI. Press any key to continue." -n 1
  else
    brew install --cask 1password
    brew install --cask 1password-cli
    read -r -p "Please open 1Password, log into all accounts, and enable Integrate with 1Password CLI. Press any key to continue." -n 1
  fi
}

initialize_os_env

if [[ "${ostype}" == "Darwin" ]]; then
  install_homebrew
else
  install_mise
fi

install_chezmoi
install_1password

# Apply dotfiles
echo "Applying Chezmoi configuration."
chezmoi init "${DOTFILES_REPO_URL}"
cd "${HOME}/.local/share/chezmoi"
git remote set-url origin git@github.com:ishioni/dotfiles.git
chezmoi apply
source "${HOME}/.zshrc"
