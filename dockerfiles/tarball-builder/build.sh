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
  cabal v2-update
  cabal v2-install --only-dependencies --lib
  cabal v2-configure
  cabal v2-build
  _pathsfile="$(find "${REPODIR}/dist-newstyle" -type f -name 'Paths_egison.hs' | head -n 1)"
  perl -i -pe 's@datadir[ ]*=[ ]*.*$@datadir = "/usr/lib/egison"@' "$_pathsfile"
  cp "$_pathsfile" ./hs-src
  cabal v2-build
  _binfile="$(find "${REPODIR}/dist-newstyle" -type f -name 'egison')"
  WORKDIR="${HOME}/work"
  BUILDROOT="${WORKDIR}/egison-${VERSION}"
  mkdir -p "${BUILDROOT}"{/bin,/lib/egison}
  cp "${_binfile}" "${BUILDROOT}/bin"
  cp -rf "${REPODIR}/lib" "${BUILDROOT}/lib/egison"
  cp "${REPODIR}/LICENSE" "${BUILDROOT}/LICENSE"
  cp "${REPODIR}/README.md" "${BUILDROOT}/README.md"
  cp "${REPODIR}/THANKS.md" "${BUILDROOT}/THANKS.md"
  cd "${WORKDIR}"
  tar -zcvf "${REPODIR}.tar.gz" -C "${WORKDIR}" "egison-${VERSION}"
} >&2
cat "${HOME}/egison.tar.gz"
