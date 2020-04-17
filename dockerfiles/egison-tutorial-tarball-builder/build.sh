#!/bin/bash
set -ue
VERSION="$1"
readonly REPODIR="${PWD}/egison-tutorial"
readonly TARBALL_FILE="egison-tutorial-${VERSION}.x86_64.tar.gz"

## Make shared libraries static
readonly GCC_OPT='-optl-static'
{
  # egison-tutorial repository does not have tags.
  git clone -b "master" https://github.com/egison/egison-tutorial.git "${REPODIR}"
  cd "${REPODIR}"
  sed -i "/Executable egison-tutorial/,\${s/ghc-options.*/& $GCC_OPT/}" egison-tutorial.cabal
  cabal v2-update
  cabal v2-configure
  cabal v2-build

  ## Create bin
  mkdir bin
  cp "$(find dist-newstyle/ -type f  -name egison-tutorial)" ./bin/egison-tutorial-impl
  printf '%s\n%s\n' '#!/bin/sh' 'egison_datadir=/usr/lib/egison-tutorial egison-tutorial-impl "$@"' > ./bin/egison-tutorial
  chmod +x ./bin/egison-tutorial

  ## Create lib
  mkdir -p ./lib/egison-tutorial
  git clone -b "${VERSION}" https://github.com/egison/egison.git
  cp -rf egison/lib ./lib/egison-tutorial/lib

  echo "name : egison-tutorial
cmdname : egison-tutorial
summary : A tutorial program for the Egison programming language
description : A tutorial program for the Egison programming language
version : ${VERSION}
changelog : Support Egison ${VERSION}
url : https://www.egison.org/
author : Satoshi, Egi
email : <egison@egison.org>
libdir : /usr/lib" > .tar2package.yml

  tar zcvf "$TARBALL_FILE" -C "$PWD" bin lib .tar2package.yml
} >&2
cat "$PWD/$TARBALL_FILE"
