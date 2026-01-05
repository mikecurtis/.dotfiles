export USER="${USER:-$(whoami)}"
export HOME="${HOME:-~}"
export HOSTNAME="${HOSTNAME:-$(cat /etc/hostname)}"

export PATH="${PATH}:${HOME}/.local/bin"
export DOTFILE_DIR="${HOME}/.dotfiles"

typeset -U path cdpath fpath manpath
autoload -U compinit && compinit
ZSH_AUTOSUGGEST_STRATEGY=(history)


# History options should be set in .zshrc and after oh-my-zsh sourcing.
# See https://github.com/nix-community/home-manager/issues/177.
HISTSIZE="1000"
SAVEHIST="999"

HISTFILE="${HOME}/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

setopt HIST_FCNTL_LOCK

# Enabled history options
enabled_opts=(
  HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
)
for opt in "${enabled_opts[@]}"; do
  setopt "$opt"
done
unset opt enabled_opts

# Disabled history options
disabled_opts=(
  APPEND_HISTORY EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
  HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
)
for opt in "${disabled_opts[@]}"; do
  unsetopt "$opt"
done
unset opt disabled_opts


if [[ $options[zle] = on ]]; then
  source <(fzf --zsh)
fi

if [[ $TERM != "dumb" ]]; then
  export STARSHIP_CONFIG="${HOME}/.config/starship/starship.toml"
  source <(starship init zsh)
fi

source <(mise activate zsh)

export GH_CONFIG_DIR="${HOME}/.local/share/gh"

( [ "$TERM" = "xterm-ghostty" ] || [ "$TERM_PROGRAM" = "ghostty" ] ) && ! $(which ghostty >/dev/null 2>&1) && export TERM=xterm-256color

alias -- bat=batcat
alias -- cat=bat
alias -- hmc="cd ${DOTFILE_DIR}"
alias -- hms="(pushd ${DOTFILE_DIR} && git pull && just build && popd && exec ${SHELL})"
alias -- la='eza -a'
alias -- ll='eza -l'
alias -- lla='eza -la'
alias -- ls=eza
alias -- lt='eza --tree'
alias -- tm='tmux list-sessions > /dev/null 2>&1 && tmux a || tmux'
alias -- view='nvim -R'
alias -- vimdiff='nvim -d'%


# Set tmux window titles to match user, host, and (optionally) directory.
# This must be done from within the shell because tmux only sees the parent
# shell, and we may be within ssh or a subshell.
if [ "${TMUX}" ]; then

  local name="$(tmux display-message -p "#{window_name}" 2>/dev/null)"
  local user=""
  local hostname=""
  local directory=""
  if [ "${name}" ]; then
    IFS="@" read -r user dest <<< "${name}"
    IFS=":" read -r hostname directory <<< "${dest}"
  fi

  # Connect to the user@host if it doesn't match the current.
  if [ \( "${user}" -a "${hostname}" \) -a \( \( "${user}" != "${USER}" \) -o \( "${hostname}" != "${HOSTNAME}" \) \) ]; then
    echo "Connecting ${user}@${hostname}"
    exec bash -c "ssh ${user}@${hostname} || (echo Failed to connect >&2 && sleep 3)"
  fi

  # Navigate to the directory, if specified.
  if [ "${directory}" ]; then
    cd "${directory}"
  fi

  # Let ctrl-z communicate with the shell to update the current state and/or
  # enable/disable directory updates.
  ctrl_z_handler() {
    local with="${USER}@${HOSTNAME}:$(pwd)"
    local without="${USER}@${HOSTNAME}"
    local name="$(tmux display-message -p "#{window_name}" 2>/dev/null)"
    IFS="@" read -r user dest <<< "${name}"
    IFS=":" read -r hostname directory <<< "${dest}"
    # If the current state matches, toggle between directory mode and
    # non-directory mode.  Otherwise, update the current state within the
    # current mode.
    if [ "${directory}" ]; then
      if [ "${with}" = "${name}" ]; then
	echo a $name
        tmux rename-window "${without}"
      else
	echo b $name
	tmux rename-window "${with}"
      fi
    else
      if [ "${without}" = "${name}" ]; then
	echo c $name
        tmux rename-window "${with}"
      else
	echo d $name
	tmux rename-window "${without}"
      fi
    fi
  }
  zle -N ctrl_z_handler
  bindkey '^Z' ctrl_z_handler

fi
