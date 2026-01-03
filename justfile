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



init: init_config init_dist init_staging init_private

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



staging: config_starship config_tmux config_ghostty

_build_copy target:
  mkdir -p {{staging_config_dir}}/{{target}}
  rm -rf {{staging_config_dir}}/{{target}}
  cp -r {{src_dir}}/{{target}} {{staging_config_dir}}/{{target}}

config_ghostty: (_build_copy "ghostty")
config_starship: (_build_copy "starship")
config_tmux: (_build_copy "tmux")



update_dist: staging
  find {{dist_dir}} -mindepth 1 -maxdepth 1 \! -name .git -exec rm -rf {} \;
  find {{staging_dir}} -mindepth 1 -maxdepth 1 -exec cp -r {} {{dist_dir}} \;
  git -C {{dist_dir}} add .
  git -C {{dist_dir}} commit --allow-empty -m 'Update dist'
