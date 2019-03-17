#!/bin/bash
set -eu
VERSION="$1"
{
  cd /tmp
  (
    mkdir /tmp/extract
    cd /tmp/extract
    cat | tar zxv
  )
  cp -rf "/tmp/extract/egison-${VERSION}"/{bin,lib} /tmp/deb-template/
  rm -rf "/tmp/extract"
  bash -x /tmp/changelog.sh
  sed -i "s/@@@VERSION@@@/${VERSION}/g" /tmp/deb-template/debian/control
  mv /tmp/deb-template "/tmp/egison-${VERSION}"
  cd "/tmp/egison-${VERSION}"
  debuild -sd <<<y || true
} >&2
cat /tmp/egison*.deb
