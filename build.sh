#!/bin/bash
set -ue
git clone https://github.com/egison/egison.git "$HOME"/egison
cd "${HOME}"/egison
cabal update
cabal install --only-dependencies
cabal configure --datadir=/usr/lib --datasubdir=egison
cabal build
cat "${HOME}/egison/dist/build/egison/egison"
