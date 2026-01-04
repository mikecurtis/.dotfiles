set dotenv-path := 'private/.env'
set dotenv-load
set dotenv-required

xdg_config_dir := if env('XDG_CONFIG_HOME', '') =~ '^/' {
  env('XDG_CONFIG_HOME')
} else {
  home_directory() / '.config'
}

src_dir := justfile_directory() / 'src'

dist_dir := justfile_directory() / 'dist'
dist_config_dir := justfile_directory() / 'dist/.config'

staging_dir := justfile_directory() / 'staging'
staging_config_dir := justfile_directory() / 'staging/.config'

installer := require('./bin/install.sh')

private_dir := justfile_directory() / 'private'
hostenv := private_dir / '.env'
hostenv_gen := require('./bin/hostenv.sh')

git := require('git')
zsh := require('zsh')
user := env('USER')



# Initialize

init_config: init_dist
  mkdir -p {{dist_config_dir}}
  ln -sf {{dist_config_dir}} {{xdg_config_dir}}

init_dist:
  mkdir -p {{dist_dir}}
  git -C {{dist_dir}} init

init_staging:
  mkdir -p {{staging_dir}}

init_private:
  #!/bin/bash
  mkdir -p {{private_dir}}
  git -C {{private_dir}} init
  {{hostenv_gen}} > {{hostenv}}
  git -C {{private_dir}} add .
  if [ "$(git -C {{private_dir}} status -s)" ]; then
    git -C {{private_dir}} commit -m 'Update private'
    echo "Deployed new version!"
  else
    echo "Nothing to update!"
  fi

init: init_dist init_staging init_private init_config
  sudo chsh -s {{zsh}} {{user}}
  ln -sf {{xdg_config_dir}}/zsh/.zshrc {{home_directory()}}/.zshrc



# Build staging repository

_build_copy target:
  rm -rf {{staging_config_dir}}/{{target}}
  cp -r {{src_dir}}/{{target}} {{staging_config_dir}}/{{target}}

_build_envsubst dir tmpl out:
  rm -rf {{staging_config_dir}}/{{dir}}
  mkdir -p {{staging_config_dir}}/{{dir}}
  envsubst < {{src_dir}}/{{dir}}/{{tmpl}} > {{staging_config_dir}}/{{dir}}/{{out}}

config_ghostty: (_build_copy "ghostty")
config_git: (_build_envsubst "git" "config.tmpl" "config")
config_mise: (_build_copy "mise")
config_starship: (_build_copy "starship")
config_tmux: (_build_copy "tmux")
config_zsh: (_build_copy "zsh")

staging: \
  config_ghostty \
  config_git \
  config_mise \
  config_starship \
  config_tmux \
  config_zsh



# Promote staging/ to dist/

check_dist_nodiff:
  #!/bin/bash
  if [ "$(git -C {{dist_dir}} status -s)" ]; then
    git -C {{dist_dir}} status
    echo "Unresolved diffs in {{dist_dir}}"
    exit 1
  fi

diff_staging_to_dist:
  echo "\n\n=== DIFF ===\n\n"
  diff -ru {{dist_config_dir}} {{staging_config_dir}} | delta

deploy_staging_to_dist:
  #!/bin/bash
  find {{dist_dir}} -mindepth 1 -maxdepth 1 \! -name .git -exec rm -rf {} \;
  find {{staging_dir}} -mindepth 1 -maxdepth 1 -exec cp -r {} {{dist_dir}} \;
  git -C {{dist_dir}} add .
  if [ "$(git -C {{dist_dir}} status -s)" ]; then
    git -C {{dist_dir}} commit -m 'Update dist'
    echo "Deployed new version!"
  else
    echo "Nothing to update!"
  fi

diff: check_dist_nodiff staging diff_staging_to_dist
commit: check_dist_nodiff staging deploy_staging_to_dist



# Install required packages

packages:
  {{installer}} -p gettext-base envsubst
  {{installer}} -p bat batcat
  {{installer}} -p git-delta delta
  {{installer}} eza
  {{installer}} -W fonts-jetbrains-mono
  {{installer}} fzf
  {{installer}} gh
  {{installer}} man
  {{installer}} -s "https://mise.run" -F mise
  {{installer}} -p neovim nvim
  {{installer}} -p ripgrep rg
  {{installer}} starship
  {{installer}} tmux
  {{installer}} zsh



# Top-level commands
build: init packages commit

