#!/bin/bash
set -e

_THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"
_tmpfile="/tmp/latest.json"
curl --retry 5 -f -so- https://api.github.com/repos/egison/egison/releases/latest > "${_tmpfile}"
cp "${_THIS_DIR}/deb-template/debian/changelog" /tmp/changelog

_version=$(cat "${_tmpfile}" | jq -r .tag_name | sed 's/^v//')
_body=$(cat "${_tmpfile}" | jq -r .body | tr -d '\r')

{
  echo "egison (${_version}-1) trusty; urgency=medium"
  echo
  echo "${_body}" | sed 's/^/  /'
  echo
  echo " -- Satoshi, Egi <egison@egison.org>  $(date --rfc-2822)"
  echo
  cat /tmp/changelog
} > "$_THIS_DIR/changelog.new"

mv "$_THIS_DIR/changelog.new" "${_THIS_DIR}/deb-template/debian/changelog"

rm /tmp/changelog
rm "${_tmpfile}"
