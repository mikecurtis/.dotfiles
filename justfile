xdg_config_dir := if env('XDG_CONFIG_HOME', '') =~ '^/' {
  env('XDG_CONFIG_HOME')
} else {
  home_directory() / '.config'
}

git := require('git')


build:
  echo "This is a recipte"

init: dist private

dist:
  mkdir -p dist
  git init dist

private:
  mkdir -p private
  git init private
