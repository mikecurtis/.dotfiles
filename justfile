xdg_config_dir := if env('XDG_CONFIG_HOME', '') =~ '^/' {
  env('XDG_CONFIG_HOME')
} else {
  home_directory() / '.config'
}

dist_dir := justfile_directory() / 'dist'
dist_config_dir := justfile_directory() / 'dist/.config'

private_dir := justfile_directory() / 'private'

git := require('git')


build:
  echo "This is a recipte"

init: dist private config

config: dist
  mkdir -p {{dist_config_dir}}
  ln -s {{dist_config_dir}} {{xdg_config_dir}}

dist:
  mkdir -p {{dist_dir}}
  git init {{dist_dir}}

private:
  mkdir -p {{private_dir}}
  git init {{private_dir}}
