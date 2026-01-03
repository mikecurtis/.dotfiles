#!/bin/bash

HOME="${HOME:-~}"
PACKAGE=
SCRIPT=
CHECK_FINISH=true

fail () {
  echo "$@" >&2
  exit 1
}

usage () {
  echo "$0 [ -p PACKAGE | -s SCRIPT ] BINARY" >&2
  exit $1
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

install_package () {
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

check_install_package () {
  if ! check_which $1; then
    if confirm "No $1 found.  Install?"; then
      install_package $2 || fail "$2 installation failed!"
    else
      fail "User aborted"
    fi
  fi
  ${CHECK_FINISH} && ( check_which $1 || fail "No $1 found!" )
}

check_install_script () {
  if ! check_which $1; then
    if confirm "No $1 found.  Install?"; then
      curl -LsSf "$2" | sh || fail "$2 installation failed!"
    else
      fail "User aborted"
    fi
  fi
  ${CHECK_FINISH} && ( check_which $1 || fail "No $1 found!" )
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -p)
    PACKAGE=$2
    shift # past argument
    shift # past value
    ;;
  -s)
    SCRIPT=$2
    shift # past argument
    shift # past value
    ;;
  -C)
    CHECK_FINISH=false
    shift # past argument
    ;;
  -h)
    usage 0
    ;;
  -* | --*)
    fail "Unknown option $1"
    ;;
  *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift                   # past argument
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

[ "$#" -eq 1 ] || usage 1
[ "${PACKAGE}" -a "${SCRIPT}" ] && usage 1
[ "${PACKAGE}" -o "S{SCRIPT}" ] || PACKAGE="$1"

[ "${PACKAGE}" ] && check_install_package "$1" "${PACKAGE}"
[ "${SCRIPT}" ] && check_install_script "$1" "${SCRIPT}"
exit 0
