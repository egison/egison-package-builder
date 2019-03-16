#!/bin/bash
set -ue

readonly REPODIR="${HOME}/egison"

{
  git clone https://github.com/egison/egison.git "${REPODIR}"
  cd "${REPODIR}"
  LATEST_TAG=$(cd "${REPODIR}" && git describe --abbrev=0 --tags)
  cabal update
  cabal install --only-dependencies
  cabal configure --datadir=/usr/lib --datasubdir=egison --disable-executable-dynamic
  cabal build
  WORKDIR="${HOME}/work"
  BUILDROOT="${WORKDIR}/egison-${LATEST_TAG}"
  mkdir -p "${BUILDROOT}"{/bin,/lib/egison}
  cp "${REPODIR}/dist/build/egison/egison" "${BUILDROOT}/bin"
  cp -rf "${REPODIR}/lib" "${BUILDROOT}/lib/egison"
  cp "${REPODIR}/LICENSE" "${BUILDROOT}/LICENSE"
  cp "${REPODIR}/README.md" "${BUILDROOT}/README.md"
  cp "${REPODIR}/THANKS.md" "${BUILDROOT}/THANKS.md"
  cd "${WORKDIR}"
  tar -zcvf "${REPODIR}.tar.gz" "${BUILDROOT}"
} >&2
cat "${HOME}/egison.tar.gz"
