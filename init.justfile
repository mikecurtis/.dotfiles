xdg_config_dir := if env('XDG_CONFIG_HOME', '') =~ '^/' {
  env('XDG_CONFIG_HOME')
} else {
  home_directory() / '.config'
}

src_dir := justfile_directory() / 'src'

dist_dir := justfile_directory() / 'dist'
dist_config_dir := justfile_directory() / 'dist/.config'

staging_dir := justfile_directory() / 'staging'

private_dir := justfile_directory() / 'private'
hostenv_gen := require('./bin/hostenv.sh')
hostenv := private_dir / '.env'

git := require('git')
zsh := require('zsh')
user := env('USER')



# Initialize

init: init_dist init_staging init_private init_config
  chsh -s {{zsh}} {{user}}
  ln -sf {{xdg_config_dir}}/zsh/.zshrc {{home_directory()}}/.zshrc

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

init_config: init_dist
  #!/bin/bash
  mkdir -p {{dist_config_dir}}
  [ -d {{xdg_config_dir}} ] || ln -s {{dist_config_dir}} {{xdg_config_dir}}
