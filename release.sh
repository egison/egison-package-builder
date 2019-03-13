#!/bin/bash

# ===================================
# Automated build script for Egison
# Required Environment Variables:
#  * TRAVIS_BUILD_DIR -- Given by TravisCI
#  * ID_RSA           -- Given by TravisCI's settings screen
#                        FYI: https://travis-ci.org/egison/homebrew-egison/settings
#  * GITHUB_AUTH      -- Given by TravisCI's settings screen.
#                        Auth token for GitHub Rest API.
# ===================================
set -xue

readonly FNAME=$(echo "egison_$(uname)_$(uname -m)" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z0-9._')
readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LATEST_VERSION=
CURRENT_VERSION=
RELEASE_ARCHIVE=
readonly TARGET_BRANCH="master"
readonly BUILDER_REPO="greymd/rpm-egison"
readonly BUILDER_REPO_NAME=${BUILDER_REPO##*/}
readonly BUILD_REPO="egison/egison"
## User-Agent starts with Travis is required (https://github.com/travis-ci/travis-ci/issues/5649)
readonly COMMON_HEADER=("-H" "User-Agent: Travis/1.0" "-H" "Authorization: token $GITHUB_AUTH" "-H" "Accept: application/vnd.github.v3+json" "-L" "-f")
readonly RELEASE_API_URL="https://api.github.com/repos/${BUILDER_REPO}/releases"

# Initialize SSH keys
init () {
  printf "Host github.com\\n\\tStrictHostKeyChecking no\\n" >> "$HOME/.ssh/config"
  echo "${ID_RSA}" | base64 --decode | gzip -d > "$HOME/.ssh/id_rsa"
  chmod 600 "$HOME/.ssh/id_rsa"
  git config --global user.name "greymd"
  git config --global user.email "greengregson@gmail.com"
}

get_version () {
  LATEST_VERSION=$(get_latest_release "${BUILD_REPO}")
  CURRENT_VERSION=$(get_latest_release "${BUILDER_REPO}")
  RELEASE_ARCHIVE="${TRAVIS_BUILD_DIR:-$THIS_DIR}/${FNAME}_${LATEST_VERSION}.tar.gz"
  readonly LATEST_VERSION CURRENT_VERSION RELEASE_ARCHIVE
}

bump () {
  local _release_id
  local _new_release_info
  if [[ "${CURRENT_VERSION}" == "${LATEST_VERSION}" ]];then
    echo "Skip git push. It is latest version." >&2
    exit 0
  fi
  # Build tarball
  ( build )
  if [[ ! -s "${RELEASE_ARCHIVE}" ]];then
    echo "Failed to create '${RELEASE_ARCHIVE}'"
    exit 1
  fi

  git clone -b "${TARGET_BRANCH}" \
    "git@github.com:${BUILDER_REPO}.git" \
    "${THIS_DIR}/${BUILDER_REPO_NAME}"

  cd "${THIS_DIR}/${BUILDER_REPO_NAME}"

  echo "${LATEST_VERSION}-$(date +%s)" > "./VERSION"

  # Crete versions and make changes to GitHub
  git add "./VERSION"
  git commit -m "[skip ci] Bump version to ${LATEST_VERSION}"

  ## Clean tags just in case
  _release_id=$(get_release_list | jq '.[] | select(.tag_name == "'"${LATEST_VERSION}"'") | .id')
  ## If there is already same name of the release, delete it.
  if [[ "${_release_id}" != "" ]]; then
    delete_release "${_release_id}" || exit 1
    git push origin :"${LATEST_VERSION}"  || true
    git tag -d "${LATEST_VERSION}" || true
  fi

  ## Push changes
  git push origin "${TARGET_BRANCH}"

  # Create new release
  _new_release_info=$(create_release "${LATEST_VERSION}" "${TARGET_BRANCH}")
  _upload_url=$(echo "${_new_release_info}" | jq -r .upload_url | perl -pe 's/{.*}//')
  upload_assets "${_upload_url}" "${RELEASE_ARCHIVE}"
}

build () {
  docker run greymd/rpm-egison > "${RELEASE_ARCHIVE}"
  file "${RELEASE_ARCHIVE}"
  {
    file "${RELEASE_ARCHIVE}" | grep 'gzip compressed'
  } && echo "${RELEASE_ARCHIVE} is successfully created." >&2
}

get_release_list () {
  curl -v -H "User-Agent: Travis/1.0" \
    -H "Authorization: token $GITHUB_AUTH" \
    "${RELEASE_API_URL}"
}

delete_release () {
  local _id="$1"
  curl "${COMMON_HEADER[@]}" \
  -X DELETE "${RELEASE_API_URL}/${_id}"
}

create_release () {
  local _tag="$1" ;shift
  local _branch="$1" ;shift
  curl "${COMMON_HEADER[@]}" \
    -X POST \
    -d '{
      "tag_name": "'"${_tag}"'",
      "target_commitish": "'"${_branch}"'",
      "name": "'"${_tag}"'",
      "body": "Bump version to '"${_tag}"'",
      "draft": false,
      "prerelease": false
    }' \
  "${RELEASE_API_URL}"
}

upload_assets () {
  local _url="$1"; shift
  local _file="$1"; shift
  curl "${COMMON_HEADER[@]}" \
    -H "Content-Type: $(file -b --mime-type "${_file}")" \
    --data-binary @"${_file}" \
    "${_url}?name=$(basename "${_file}")"
}

get_latest_release () {
  local _repo="$1"
  curl -f -v -H "User-Agent: Travis/1.0" \
       -L "https://api.github.com/repos/${_repo}/releases/latest" > "./latest.json"
  # shellcheck disable=SC2181
  if [[ $? != 0 ]] || [[ ! -s "./latest.json" ]]; then
    exit 1
  fi
  jq -r .tag_name < "./latest.json"| tr -d '\n'
  rm "./latest.json"
}

main () {
  local _cmd
  _cmd="${1-}"
  shift || true
  case "$_cmd" in
    init)
      init
      ;;
    bump)
      get_version
      bump
      ;;
    *)
      exit 1
  esac
}

main "$@"
