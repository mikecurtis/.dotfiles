export USER="${USER:-$(whoami)}"
export HOME="${HOME:-~}"

export PATH="${PATH}:${HOME}/.local/bin"
DOTFILE_DIR="${HOME}/.dotfiles"

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
alias -- hms="just -f ${DOTFILE_DIR}/justfile build && exec ${SHELL}"
alias -- la='eza -a'
alias -- ll='eza -l'
alias -- lla='eza -la'
alias -- ls=eza
alias -- lt='eza --tree'
alias -- tm='tmux list-sessions > /dev/null 2>&1 && tmux a || tmux'
alias -- view='nvim -R'
alias -- vimdiff='nvim -d'%
