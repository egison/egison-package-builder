#!/bin/bash
set -ue

readonly WORKDIR="${HOME}/work"
readonly REPODIR="${HOME}/egison"

{
  git clone https://github.com/egison/egison.git "${REPODIR}"
  cd "${REPODIR}"
  cabal update
  cabal install --only-dependencies
  cabal configure --datadir=/usr/lib --datasubdir=egison
  cabal build
  mkdir -p "${WORKDIR}"{/bin,/lib/egison}
  cp "${REPODIR}/dist/build/egison/egison" "${WORKDIR}/bin"
  cp -rf "${REPODIR}/lib" "${WORKDIR}/lib/egison"
  cp "${REPODIR}/LICENSE" "${WORKDIR}/LICENSE"
  cp "${REPODIR}/README.md" "${WORKDIR}/README.md"
  cp "${REPODIR}/THANKS.md" "${WORKDIR}/THANKS.md"
  tar -zcvf "${REPODIR}.tar.gz" -C "${WORKDIR}" bin lib LICENSE README.md THANKS.md
} >&2
cat "${HOME}/egison.tar.gz"
