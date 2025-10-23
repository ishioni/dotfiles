# Dotfiles

## Tools

I manage my system/dotfiles through shell scripts and Chezmoi:

## Installation

```shell
curl https://raw.githubusercontent.com/ishioni/dotfiles/master/setup.sh > /tmp/install && chmod +x /tmp/install && /tmp/install
```

Or in Truenas

```shell
export ZFS_POOL=TEST && \
curl https://raw.githubusercontent.com/ishioni/dotfiles/master/setup.sh  > ./install && chmod +x ./install && ./install
```