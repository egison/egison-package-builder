#!/bin/bash
set -ue
VERSION="master"
readonly REPODIR="${PWD}/egison-tutorial"

## Make shared libraries static
readonly GCC_OPT='-optl-static'
{
  git clone -b "${VERSION}" https://github.com/egison/egison-tutorial.git "${REPODIR}"
  cd "${REPODIR}"
  sed -i "\$a  ghc-options:  $GCC_OPT/" egison-tutorial.cabal
  cabal v2-update
  cabal v2-configure
  cabal v2-build
  mkdir bin
  cp "$(find dist-newstyle/ -type f  -name egison-tutorial)" ./bin/egison-tutorial-impl
  printf '%s\n%s\n' '#!/bin/sh' 'egison_datadir=/usr/lib/egison-tutorial egison-tutorial-impl "$@"' > ./bin/egison-tutorial
  chmod +x ./bin/egison-tutorial

  mkdir -p ./lib/egison-tutorial
  git clone -b "3.9.3" https://github.com/egison/egison.git
  cp -rf egison/lib ./lib/egison-tutorial/lib

  _file="egison-tutorial-3.9.3.x86_64.tar.gz"
  tar zcvf "$_file" -C "$PWD" bin lib .tar2package.yml
  docker run -i greymd/tar2rpm < "$_file" > egison-tutorial-3.9.3.x86_64.rpm
  docker run -i greymd/tar2deb < "$_file" > egison-tutorial-3.9.3.x86_64.deb
} >&2

