#!/bin/bash
set -eu
VERSION="$1"
REPO="greymd/rpm-egison"
{
  cd /tmp
  wget "https://github.com/${REPO}/releases/download/${VERSION}/egison_linux_$(uname -m)_${VERSION}.tar.gz"
  tar zxvf "egison_linux_$(uname -m)_${VERSION}.tar.gz"
  cp -rf "egison-${VERSION}"/bin deb-template/bin
  cp -rf "egison-${VERSION}"/lib deb-template/lib
  bash changelog.sh
  mv deb-template "egison-${VERSION}"
  cd "egison-${VERSION}"
  debuild -sd <<<y
} >&2
