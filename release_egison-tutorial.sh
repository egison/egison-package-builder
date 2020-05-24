#!/bin/bash

# ===================================
# Automated build script for Egison
# Required Environment Variables:
#  * TRAVIS_BUILD_DIR -- Given by TravisCI
#  * ID_RSA           -- Given by GitHub secrets.
#  * API_AUTH         -- Given by GitHub secrets.
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
readonly COMMON_HEADER=("--retry" "5" "-H" "User-Agent: Travis/1.0" "-H" "Authorization: token $API_AUTH" "-H" "Accept: application/vnd.github.v3+json" "-L" "-f")

# Initialize SSH keys
init_ssh () {
  mkdir -p "$HOME/.ssh/"
  printf "Host github.com\\n\\tStrictHostKeyChecking no\\n" >> "$HOME/.ssh/config"
  echo "${ID_RSA}" | base64 --decode | gzip -d > "$HOME/.ssh/id_rsa"
  chmod 600 "$HOME/.ssh/id_rsa"
  git config --global user.name "greymd"
  git config --global user.email "yamadagrep@gmail.com"
}

set_configures () {
  local _package_builder_repo="$1" ;shift
  local _build_target_repo="$1" ;shift
  LATEST_VERSION=$(get_latest_release_cabal "${_build_target_repo}") # target repo is basically egison/egison-tutorial
  CURRENT_VERSION=$(get_latest_release_file "${_package_builder_repo}" "VERSION_egison-tutorial" ) # Repo is egison/egison-package-builder
  readonly FNAME="egison-tutorial-${LATEST_VERSION}.$(uname -m)"
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

get_latest_release_cabal () {
  local _repo="$1"
  echo "get_latest_release_cabal start $_repo" >&2
  curl --retry 3 -f -v -H "User-Agent: Travis/1.0" \
       -H "Authorization: token $API_AUTH" \
       -L "https://raw.githubusercontent.com/${_repo}/master/${_repo/*\/}.cabal" \
       | awk '/Version:/{print $NF}' > ./latest
  _ret=$?
  if [[ $_ret != 0 ]] || [[ ! -s "./latest" ]]; then
    exit 1
  fi
  cat "./latest"
  rm "./latest"
  echo "get_latest_release end $_repo" >&2
}

get_latest_release_file () {
  local _repo="$1" ;shift
  local _file="$1"
  echo "get_latest_release_file start $_repo" >&2
  curl --retry 3 -f -v -H "User-Agent: Travis/1.0" \
       -H "Authorization: token $API_AUTH" \
       -L "https://raw.githubusercontent.com/${_repo}/master/${_file}" \
       | awk -F- '{print $1}' > ./latest
  _ret=$?
  if [[ $_ret != 0 ]] || [[ ! -s "./latest" ]]; then
    exit 1
  fi
  cat "./latest"
  rm "./latest"
  echo "get_latest_release end $_repo" >&2
}

build_tarball () {
  local _file="$1" ;shift
  local _ver="$1"
  docker run "${DOCKERHUB_ACCOUNT}"/egison-tutorial-tarball-builder bash /tmp/build.sh "${_ver}" > "${_file}"
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
  docker run -i "${DOCKERHUB_ACCOUNT}"/tar2rpm:1.0.1 < "${_tarfile}" > "${_file}"
  file "${_file}"
  ## Result is like : "file.rpm: RPM v3.0 bin i386/x86_64 file-1.2.3"
  file "${_file}" | grep 'RPM' || {
    echo "Failed to create ${_file}" >&2
    exit 1
  }
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
  docker run -i "${DOCKERHUB_ACCOUNT}"/tar2deb:1.0.1 < "${_tarfile}" > "${_file}"
  file "${_file}"
  ## Result is like : "file.deb: Debian binary package (format 2.0)"
  file "${_file}" | grep 'Debian' || {
    echo "Failed to create ${_file}" >&2
    exit 1
  }
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

is_releasable () {
  local _package_builder_repo="$1" ;shift
  _release_id=$(get_release_list "${_package_builder_repo}" | jq '.[] | select(.tag_name == "'"${LATEST_VERSION}"'") | .id')
  if [[ "${_release_id}" =~ ^[0-9][0-9]*$ ]]; then
    return 0
  else
    echo "Egison should be released first. Skip build process." >&2
    return 1
  fi
}

bump_version () {
  local _package_builder_repo="$1" ;shift
  local _release_id
  local _repo_name=${_package_builder_repo##*/}

  rm -rf "${THIS_DIR:?}/${_repo_name}"
  git clone -b "${TARGET_BRANCH}" \
    "git@github.com:${_package_builder_repo}.git" \
    "${THIS_DIR}/${_repo_name}"

  cd "${THIS_DIR}/${_repo_name}"

  echo "${LATEST_VERSION}-$(date +%s)" > "./VERSION_egison-tutorial"

  # Crete versions and make changes to GitHub
  git add "./VERSION_egison-tutorial"
  git commit -m "[skip ci] Bump version to ${LATEST_VERSION} (egison-tutorial)"

  ## Push changes
  git push origin "${TARGET_BRANCH}"
}

commit_package () {
  local _package_builder_repo="$1" ;shift
  local _ver="$1" ;shift
  local _package="$1" ;shift
  local _release_id
  local _repo_name=${_package_builder_repo##*/}

  rm -rf "${THIS_DIR:?}/${_repo_name}"
  git clone -b "${TARGET_BRANCH}" \
    "git@github.com:${_package_builder_repo}.git" \
    "${THIS_DIR}/${_repo_name}"

  mkdir "${THIS_DIR}/${_repo_name}/packages"
  cp "$_package" "${THIS_DIR}/${_repo_name}/packages"
  cd "${THIS_DIR}/${_repo_name}"
  git add "./packages"

  ## No changes
  [[ "$(git status --porcelain | grep -c .)" == "0" ]] && return 0

  git commit -m "[skip ci] Update package ${_package} to ${_ver}"
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
    return 0
  else
    echo "$_fname is NOT uploaded yet" >&2
    return 1
  fi
  set -e
}

download_asset() {
  local _repo="$1" ;shift
  local _ver="$1" ;shift
  local _download_file="$1" ;shift
  local _saved_file="$1" ;shift
  local _download_url
  _download_url="$(get_release_list "${_repo}" \
    | jq ".[] | select(.tag_name == \"${_ver}\")" \
    | jq -r ".assets[] | select(.name == \"${_download_file}\") | .browser_download_url")"
  [[ "$_download_url" =~ ^https.*${_download_file}$ ]] || return 1
  curl -o "$_saved_file" -L -f --retry 5 "$_download_url"
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
      ;;
    upload-tarball)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_releasable "${_package_builder_repo}" || exit 0
      is_uploaded "${_package_builder_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.tar.gz")" && exit 0
      build_tarball "${RELEASE_ARCHIVE}.tar.gz" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.tar.gz"
      ;;
    upload-rpm)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_releasable "${_package_builder_repo}" || exit 0
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.rpm")" && exit 0
      build_rpm "${RELEASE_ARCHIVE}.tar.gz" "${RELEASE_ARCHIVE}.rpm" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.rpm"
      ;;
    upload-deb)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_releasable "${_package_builder_repo}" || exit 0
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.deb")" && exit 0
      build_deb "${RELEASE_ARCHIVE}.tar.gz" "${RELEASE_ARCHIVE}.deb" "${LATEST_VERSION}"
      upload_assets "${_upload_target_repo}" "${LATEST_VERSION}" "${RELEASE_ARCHIVE}.deb"
      ;;
    commit-deb)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_releasable "${_package_builder_repo}" || exit 0
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.deb")" || exit 1
      download_asset "${_package_builder_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.deb")" "egison-tutorial.$(uname -m).deb"
      commit_package "${_upload_target_repo}" "${LATEST_VERSION}" "egison-tutorial.$(uname -m).deb"
      ;;
    commit-rpm)
      _package_builder_repo="$2"
      _build_target_repo="$3"
      _upload_target_repo="$4"
      set_configures "$_package_builder_repo" "$_build_target_repo"
      is_releasable "${_package_builder_repo}" || exit 0
      is_uploaded "${_upload_target_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.rpm")" || exit 1
      download_asset "${_package_builder_repo}" "${LATEST_VERSION}" "$(basename "${RELEASE_ARCHIVE}.rpm")" "egison-tutorial.$(uname -m).rpm"
      commit_package "${_upload_target_repo}" "${LATEST_VERSION}" "egison-tutorial.$(uname -m).rpm"
      ;;
    *)
      exit 1
  esac
}

main "$@"
