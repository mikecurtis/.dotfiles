#!/bin/bash

set -ex

function fail {
  echo "$@" >&2
  exit 1
}

function usage {
  echo "usage: $0 [--headless] [--distro=X] [--arch=X]" >&2
  exit 1
}

[ "${USER}" ] || USER="$(whoami)"
[ "${USER}" ] || fail 'Cannot identify \${USER}'

[ "${HOME}" ] || HOME="/home/${USER}"
[ "${HOME}" ] || fail 'Cannot identify \${HOME}'

[ "${HOSTNAME}" ] || HOSTNAME="$(hostname)"
[ "${HOSTNAME}" ] || fail 'Cannot identify \${HOSTNAME}'

[ "${GITUSER}" ] || GITUSER="${USER}"
[ "${USER}" ] || fail 'Cannot identify \${GITUSER}'

DISTRO=
OSTYPE=
ARCH=
STANDALONE=false
DARWIN=false
HEADLESS=false
STABLE=true
WSL=false

[ -f "/etc/wsl.conf" ] && WSL=true
${WSL} && HEADLESS=true

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --headless)
      HEADLESS=true
      shift # past argument
      ;;
    --distro)
      DISTRO="$2"
      shift # past argument
      shift # past value
      ;;
    --arch)
      ARCH="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ -z "${DISTRO}" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID}" in
      ubuntu)
        DISTRO="ubuntu"
        ;;
      arch|archarm)
        DISTRO="arch"
        ;;
      nixos)
        DISTRO="nixos"
        ;;
    esac
  fi
fi

if type uname >/dev/null 2>&1; then

  ARCH="$(uname -m)"

  if [ -z "$DISTRO" ]; then
    case "$(uname -s)" in
      Linux)
        DISTRO="linux"
        ;;
      Darwin)
        DISTRO="darwin"
        ;;
    esac
  fi

fi

case "${DISTRO}" in
  linux|ubuntu|arch)
    OSTYPE="linux"
    STANDALONE=true
    ;;
  darwin)
    OSTYPE="darwin"
    DARWIN=true
    ;;
  nixos)
    fail "NixOS unsupported!"
    ;;
  *)
    fail "DISTRO \"${DISTRO}\" unsupported!"
    ;;
esac

case "${OSTYPE}" in
  linux|darwin)
    ;;
  *)
    fail "OSTYPE \"${OSTYPE}\" unsupported!"
esac

case "${ARCH}" in
  x86_64)
    ;;
  aarch64|arm64)
    ARCH="aarch64"
    ;;
  *)
    fail "ARCH \"${ARCH}\" unsupported!"
esac

SYSTEM="${ARCH}-${OSTYPE}"

function generate {
  for env in \
    USER \
    HOME \
    HOSTNAME \
    GITUSER \
    STANDALONE \
    DARWIN \
    DISTRO \
    OSTYPE \
    ARCH \
    SYSTEM \
    DARWIN \
    WSL \
    HEADLESS \
  ; do
    echo "export ${env}=\"${!env}\""
  done
}

generate
