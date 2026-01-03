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

private_dir := justfile_directory() / 'private'

git := require('git')



# Initialize

init: init_dist init_staging init_private init_config

init_config: init_dist
  mkdir -p {{dist_config_dir}}
  ln -s {{dist_config_dir}} {{xdg_config_dir}}

init_dist:
  mkdir -p {{dist_dir}}
  git -C {{dist_dir}} init

init_staging:
  mkdir -p {{staging_dir}}

init_private:
  mkdir -p {{private_dir}}
  git -C {{private_dir}} init



# Build staging repository

_build_copy target:
  mkdir -p {{staging_config_dir}}/{{target}}
  rm -rf {{staging_config_dir}}/{{target}}
  cp -r {{src_dir}}/{{target}} {{staging_config_dir}}/{{target}}

config_ghostty: (_build_copy "ghostty")
config_mise: (_build_copy "mise")
config_starship: (_build_copy "starship")
config_tmux: (_build_copy "tmux")

staging: config_starship config_tmux config_ghostty



# Promote staging/ to dist/

check_dist_nodiff:
  #!/bin/bash
  if [ "$(git -C {{dist_dir}} status -s)" ]; then
    git -C {{dist_dir}} status
    echo "Unresolved diffs in {{dist_dir}}"
    exit 1
  fi

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

promote: check_dist_nodiff staging deploy_staging_to_dist



# Install required packages

_install_package binary package:
  ./bin/install.sh -p "{{package}}" "{{binary}}"

_install_script binary script:
  ./bin/install.sh -s "{{script}}" "{{binary}}"

package_tmux: (_install_package "tmux" "tmux")

install_packages: package_tmux
