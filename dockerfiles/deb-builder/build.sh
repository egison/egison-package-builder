#!/bin/bash
set -eu
VERSION="$1"
REPO="greymd/rpm-egison"
{
  cd /tmp
  (
    mkdir /tmp/extract
    cd /tmp/extract
    wget "https://github.com/${REPO}/releases/download/${VERSION}/egison_linux_$(uname -m)_${VERSION}.tar.gz"
    tar zxvf "egison_linux_$(uname -m)_${VERSION}.tar.gz"
  )
  cp -rf "/tmp/extract/egison-${VERSION}"/{bin,lib} /tmp/deb-template/
  rm -rf "/tmp/extract"
  bash -x /tmp/changelog.sh
  mv /tmp/deb-template "/tmp/egison-${VERSION}"
  cd "/tmp/egison-${VERSION}"
  debuild -sd <<<y
} >&2
cat /tmp/egison*.deb
