#!/bin/bash

# ===================================
# Automated build script for Egison
# Required Environment Variables:
#  * TRAVIS_BUILD_DIR -- Given by TravisCI
#  * ID_RSA           -- Given by TravisCI's settings screen
#                        FYI: https://travis-ci.org/egison/<reponame>/settings
#  * GITHUB_AUTH      -- Given by TravisCI's settings screen.
#                        Auth token for GitHub Rest API.
# ===================================
set -xue

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERHUB_ACCOUNT="greymd"
LATEST_VERSION=
CURRENT_VERSION=
RELEASE_ARCHIVE=
readonly TARGET_BRANCH="master"
## User-Agent starts with Travis is required (https://github.com/travis-ci/travis-ci/issues/5649)
readonly COMMON_HEADER=("--retry" "5" "-H" "User-Agent: Travis/1.0" "-H" "Authorization: token $GITHUB_AUTH" "-H" "Accept: application/vnd.github.v3+json" "-L" "-f")

# Initialize SSH keys
init_ssh () {
  printf "Host github.com\\n\\tStrictHostKeyChecking no\\n" >> "$HOME/.ssh/config"
  echo "${ID_RSA}" | base64 --decode | gzip -d > "$HOME/.ssh/id_rsa"
  chmod 600 "$HOME/.ssh/id_rsa"
  git config --global user.name "greymd"
  git config --global user.email "greengregson@gmail.com"
}

set_configures () {
  local _package_builder_repo="$1" ;shift
  local _build_target_repo="$1" ;shift
  LATEST_VERSION=$(get_latest_release "${_build_target_repo}")
  CURRENT_VERSION=$(get_latest_release "${_package_builder_repo}")
  readonly FNAME="egison-${LATEST_VERSION}.$(uname -m)"
  RELEASE_ARCHIVE="${TRAVIS_BUILD_DIR:-$THIS_DIR}/${FNAME}"
  readonly LATEST_VERSION CURRENT_VERSION RELEASE_ARCHIVE
}

get_release_list () {
  local _repo="$1"
  local _api_url="https://api.github.com/repos/${_repo}/releases"
  curl "${COMMON_HEADER[@]}" "${_api_url}"
}

delete_release () {
  local _package_builder_repo="$1" ;shift
  local _id="$1" ;shift
  local _api_url="https://api.github.com/repos/${_package_builder_repo}/releases"
  curl "${COMMON_HEADER[@]}" \
  -X DELETE "${_api_url}/${_id}"
}

create_release () {
  local _package_builder_repo="$1" ;shift
  local _tag="$1" ;shift
  local _branch="$1" ;shift
  local _api_url="https://api.github.com/repos/${_package_builder_repo}/releases"
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
  "${_api_url}"
}

upload_assets () {
  local _repo="$1" ;shift
  local _tag="$1"; shift
  local _file="$1"; shift
  local _url=
  _url="$(get_upload_url "${_repo}" "${_tag}")"
  curl "${COMMON_HEADER[@]}" \
    -H "Content-Type: $(file -b --mime-type "${_file}")" \
    --data-binary @"${_file}" \
    "${_url}?name=$(basename "${_file}")"
}

get_latest_release () {
  local _repo="$1"
  curl "${COMMON_HEADER[@]}" \
       -L "https://api.github.com/repos/${_repo}/releases/latest" > "./latest.json"
  # shellcheck disable=SC2181
  if [[ $? != 0 ]] || [[ ! -s "./latest.json" ]]; then
    exit 1
  fi
  jq -r .tag_name < "./latest.json"| tr -d '\n'
  rm "./latest.json"
}

build_tarball () {
  local _file="$1" ;shift
  local _ver="$1"
  docker run "${DOCKERHUB_ACCOUNT}"/egison-tarball-builder bash /tmp/build.sh "${_ver}" > "${_file}"
  file "${_file}"
  {
    file "${_file}" | grep 'gzip compressed'
  } && echo "${_file} is successfully created." >&2
  if [[ ! -s "${_file}" ]];then
    echo "Failed to create '${_file}'"
    exit 1
  fi
}

build_rpm () {
  local _tarfile="$1" ;shift
  local _file="$1" ;shift
  local _ver="$1"
  if [[ ! -e "${_tarfile}" ]];then
    build_tarball "${_tarfile}" "${_ver}"
  fi
  docker run -i "${DOCKERHUB_ACCOUNT}"/egison-rpm-builder bash /tmp/build.sh "${_ver}" > "${_file}"  < "${_tarfile}"
  file "${_file}"
  ## Result is like : "file.rpm: RPM v3.0 bin i386/x86_64 file-1.2.3"
  file "${_file}" | grep 'RPM'
  echo "${_file} is successfully created." >&2
  if [[ ! -s "${_file}" ]];then
    echo "Failed to create '${_file}'"
    exit 1
  fi
}

build_deb () {
  local _tarfile="$1" ;shift
  local _file="$1" ;shift
  local _ver="$1"
  if [[ ! -e "${_tarfile}" ]];then
    build_tarball "${_tarfile}" "${_ver}"
  fi
  docker run -i "${DOCKERHUB_ACCOUNT}"/egison-deb-builder bash /tmp/build.sh "${_ver}" > "${_file}" < "${_tarfile}"
  file "${_file}"
  ## Result is like : "file.deb: Debian binary package (format 2.0)"
  file "${_file}" | grep 'Debian'
  echo "${_file} is successfully created." >&2
  if [[ ! -s "${_file}" ]];then
    echo "Failed to create '${_file}'"
    exit 1
  fi
}

release_check () {
  if [[ "${CURRENT_VERSION}" == "${LATEST_VERSION}" ]];then
    echo "Skip git push. It is latest version." >&2
    exit 0
  fi
}

bump_version () {
  local _package_builder_repo="$1" ;shift
  local _release_id
  local _repo_name=${_package_builder_repo##*/}

  git clone -b "${TARGET_BRANCH}" \
    "git@github.com:${_package_builder_repo}.git" \
    "${THIS_DIR}/${_repo_name}"

  cd "${THIS_DIR}/${_repo_name}"

  echo "${LATEST_VERSION}-$(date +%s)" > "./VERSION"

  # Crete versions and make changes to GitHub
  git add "./VERSION"
  git commit -m "[skip ci] Bump version to ${LATEST_VERSION}"

  ## Clean tags just in case
  _release_id=$(get_release_list "${_package_builder_repo}" | jq '.[] | select(.tag_name == "'"${LATEST_VERSION}"'") | .id')
  ## If there is already same name of the release, delete it.
  if [[ "${_release_id}" != "" ]]; then
    delete_release "${_package_builder_repo}" "${_release_id}" || exit 1
    git push origin :"${LATEST_VERSION}"  || true
    git tag -d "${LATEST_VERSION}" || true
  fi

  ## Push changes
  git push origin "${TARGET_BRANCH}"
}

bump_package () {
  local _package_builder_repo="$1" ;shift
  local _release_id
  local _repo_name=${_package_builder_repo##*/}
  local _package="$1" ;shift

  git clone -b "${TARGET_BRANCH}" \
    "git@github.com:${_package_builder_repo}.git" \
    "${THIS_DIR}/${_repo_name}"

  mkdir "${THIS_DIR}/${_repo_name}/packages"
  cp "$_package" "${THIS_DIR}/${_repo_name}/packages"
  cd "${THIS_DIR}/${_repo_name}"

  git add "./packages"
  git commit -m "[skip ci] Update package ${_package}"

  ## Push changes
  git push origin "${TARGET_BRANCH}"
}

is_uploaded() {
  local _repo="$1" ;shift
  local _ver="$1" ;shift
  local _fname="$1" ;shift
  local _result=
  _result="$(get_release_list "${_repo}" \
    | jq ".[] | select (.tag_name==\"${_ver}\")" \
    | jq -r '.assets[] | .name' )"
  set +e
  if grep "${_fname}" <<<"$_result" ;then
    echo "$_fname is ALREADY uploaded" >&2
    exit 0
  else
    echo "$_fname is NOT uploaded yet" >&2
  fi
  set -e
}

get_upload_url () {
  local _repo="$1" ;shift
  local _tag="$1" ;shift
  local _release_info
  _release_info="$(get_release_list "${_repo}")"
  echo "${_release_info}" | jq ".[] | select (.tag_name==\"${_tag}\")" | jq -r .upload_url | perl -pe 's/{.*}//'
}

main () {
  local _cmd="$1"
  local _package_builder_repo _build_target_repo _upload_target_repo
  case "$_cmd" in
    init)
      init_ssh
      ;;
    bump)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      # set variables LATEST_VERSION CURRENT_VERSION RELEASE_ARCHIVE
      set_configures "$_package_builder_repo" "$_build_target_repo"
      release_check
      bump_version "$_package_builder_repo" ## IT MIGHT BE DESTRUCTIVE!! TAKE CARE THE REPOSITORY NAME!!
      create_release "$_package_builder_repo" "${LATEST_VERSION}" "${TARGET_BRANCH}"
      ;;
    upload-tarball)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_uploaded "${_package_builder_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.tar.gz")"
      build_tarball "${RELEASE_ARCHIVE}.tar.gz" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.tar.gz"
      ;;
    upload-rpm)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.rpm")"
      build_rpm "${RELEASE_ARCHIVE}.tar.gz" "${RELEASE_ARCHIVE}.rpm" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.rpm"
      ;;
    upload-deb)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.deb")"
      build_deb "${RELEASE_ARCHIVE}.tar.gz" "${RELEASE_ARCHIVE}.deb" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.deb"
      ;;
    upload-packages)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.deb")"
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.rpm")"
      cp "${RELEASE_ARCHIVE}.deb" "egison-latest.$(uname -m).deb"
      bump_package "${_package_builder_repo}" "egison-latest.$(uname -m).deb"
      cp "${RELEASE_ARCHIVE}.rpm" "egison-latest.$(uname -m).rpm"
      bump_package "${_package_builder_repo}" "egison-latest.$(uname -m).rpm"
      ;;
    *)
      exit 1
  esac
}

main "$@"
