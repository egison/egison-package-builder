#!/bin/bash
set -ue
VERSION="$1"
readonly REPODIR="${HOME}/egison"

## Make shared libraries static
readonly GCC_OPT='-optl-static'
{
  git clone -b "${VERSION}" https://github.com/egison/egison.git "${REPODIR}"
  cd "${REPODIR}"
  sed -i "/Executable egison/,\${s/ghc-options.*/& $GCC_OPT/}" egison.cabal
  cabal update
  cabal install --only-dependencies
  cabal configure --datadir=/usr/lib --datasubdir=egison
  cabal build
  WORKDIR="${HOME}/work"
  BUILDROOT="${WORKDIR}/egison-${VERSION}"
  mkdir -p "${BUILDROOT}"{/bin,/lib/egison}
  cp "${REPODIR}/dist/build/egison/egison" "${BUILDROOT}/bin"
  cp -rf "${REPODIR}/lib" "${BUILDROOT}/lib/egison"
  cp "${REPODIR}/LICENSE" "${BUILDROOT}/LICENSE"
  cp "${REPODIR}/README.md" "${BUILDROOT}/README.md"
  cp "${REPODIR}/THANKS.md" "${BUILDROOT}/THANKS.md"
  cd "${WORKDIR}"
  tar -zcvf "${REPODIR}.tar.gz" -C "${WORKDIR}" "egison-${VERSION}"
} >&2
cat "${HOME}/egison.tar.gz"
