# Dotfiles

## Tools

I manage my system and dotfiles through shell scripts and Chezmoi.

- **macOS:** Homebrew remains the global package manager.
- **Linux and TrueNAS:** Mise installs its binary, tools, shims, and caches under the user home directory. The bootstrap does not call `install-dev-tools`, write to the read-only root filesystem, create a ZFS dataset, or use Homebrew.

The Linux bootstrap requires the base TrueNAS-provided `curl`, `git`, and `zsh` commands. Project-specific dependencies, including the pinned `homelab-ops` toolchain, are managed by the repository’s `.mise/config.toml` and `.mise/mise.lock`.

## Installation

```shell
curl https://raw.githubusercontent.com/ishioni/dotfiles/master/setup.sh > /tmp/install && chmod +x /tmp/install && /tmp/install
```

The same command applies on TrueNAS; no `ZFS_POOL` variable or developer-tools installation is required.

After cloning `homelab-ops` on a machine with GitHub SSH access:

```shell
cd ~/src/homelab-ops
mise trust
mise install
```
