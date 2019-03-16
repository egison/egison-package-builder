#!/bin/bash

set -u
VERSION="$1"
{
  sed -i "s/@@@VERSION@@@/${VERSION}/" /tmp/egison.spec
  rpmbuild --undefine=_disable_source_fetch --define="_libdir /usr/lib" -ba /tmp/egison.spec
} >&2
# It is expectec to be single file.
cat "${HOME}/rpmbuild/RPMS/$(uname -m)"/egison*.rpm
