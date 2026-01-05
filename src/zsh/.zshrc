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
alias -- hms="(pushd ${DOTFILE_DIR} && git pull && just build && popd) && exec ${SHELL}"
alias -- la='eza -a'
alias -- ll='eza -l'
alias -- lla='eza -la'
alias -- ls=eza
alias -- lt='eza --tree'
alias -- tm='tmux list-sessions > /dev/null 2>&1 && tmux a || tmux'
alias -- view='nvim -R'
alias -- vimdiff='nvim -d'%


# Auto-start the ssh agent and add default keys
SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initializing new SSH agent..."
    # Create an environment file with safe permissions
    touch "$SSH_ENV"
    chmod 600 "${SSH_ENV}"
    # Start the agent and output the env variables to the file
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' >> "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    # Add default keys (id_rsa, id_ecdsa, etc.)
    ssh-add
}

# Source SSH settings, if applicable
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    # Check if the stored agent process is still running
    kill -0 $SSH_AGENT_PID 2>/dev/null || {
        start_agent
    }
else
    start_agent
fi


# Set tmux window titles to match user, host, and (optionally) directory.
# This must be done from within the shell because tmux only sees the parent
# shell, and we may be within ssh or a subshell.
if [ "${TMUX}" ]; then

  local name=""
  # Optimization: If this is a remote session using a tunnel back to tmux, save
  # ~150ms on initial load by taking initial value directly from client
  # environment variable rather than making a callback.
  if [ "${TMUX_TITLE_HINT}" ]; then
    name="${TMUX_TITLE_HINT}"
    unset TMUX_TITLE_HINT
  else
    name="$(tmux display-message -p "#{window_name}" 2>/dev/null)"
  fi
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
  _ctrl_z_handler() {
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
        tmux rename-window "${without}"
      else
	tmux rename-window "${with}"
      fi
    else
      if [ "${without}" = "${name}" ]; then
        tmux rename-window "${with}"
      else
	tmux rename-window "${without}"
      fi
    fi
  }
  zle -N _ctrl_z_handler
  bindkey '^Z' _ctrl_z_handler

fi

# ssh with tmux tunneling.  Should only be used on trusted destinations.
function tsh {
  LOCAL="$(echo $TMUX | cut -d ',' -f1)"
  REMOTE="/tmp/tmux.remote.$(date +'%s')"
  # Minor optimization.  See notes in .zshrc
  TMUX_TITLE_HINT="$(tmux display-message -p '#{window_name}')"

  # Note that \$SHELL is escaped to be evaluated in the remote environment.
  ssh -t -R "${REMOTE}:${LOCAL}" "$@" \
    "export TMUX=\"${REMOTE}\"; \
    export TMUX_TITLE_HINT="${TMUX_TITLE_HINT}" ; \
    trap \"rm ${REMOTE}\" EXIT; \
    exec \$SHELL -l"
}
