#!/bin/sh

set -ex

HOME="${HOME:-~}"
DIR="${HOME}/.dotfiles"
REPO="https://github.com/mikecurtis/testdot"

fail () {
  echo "$@" >&2
  exit 1
}

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "${ID}" in
  arch | archarm)
    OS="arch"
    ;;
  ubuntu)
    OS="ubuntu"
    ;;
  esac
fi

if [ -z "$OS" ]; then
  if type uname >/dev/null 2>&1; then
    case "$(uname)" in
    Darwin)
      OS="macos"
      ;;
    esac
  fi
fi

if [ -z "$OS" ]; then
  fail "Unknown OS"
fi

confirm () {
  ${YES} && return
  read -p "$@ " choice
  case "$choice" in
  y | Y) return 0 ;;
  n | N) return 1 ;;
  *) confirm "$@" ;;
  esac
}

force () {
  ${FORCE} && return
  read -p "$@ " choice
  case "$choice" in
  y | Y) return 0 ;;
  n | N) return 1 ;;
  *) force "$@" ;;
  esac
}

check_which () {
  which $1 >/dev/null 2>&1
  return $?
}

install () {
  case "${OS}" in
  arch)
    sudo pacman --noconfirm --needed -Suy $* ||
      fail "${installer} install failed"
    ;;
  ubuntu)
    sudo apt update -y &&
      sudo apt install -y $* ||
      fail "apt install failed"
    ;;
  macos)
    brew update &&
      brew install $* ||
      fail "brew install failed"
    ;;
  esac
}

check_install () {
  if ! check_which $1; then
    if confirm "No $1 found.  Install?"; then
      install $1 || fail "$1 installation failed!"
    else
      fail "User aborted"
    fi
  fi
  check_which $1 || fail "No $1 found!"
}

check_bootstrap () {
  if ! [ -d "${DIR}" ]; then
    mkdir -p "${DIR}"
    git clone "${REPO}" "${DIR}"
  fi
  cd "${DIR}" || fail "Could not enter ${DIR}"
  git pull || fail "Could not git pull"
  just init || fail "Could not just init"
}

check_install git
check_install just
check_bootstrap
