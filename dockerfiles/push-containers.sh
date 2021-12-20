#!/usr/bin/env bash
set -eu
TAG="$1"
(
  cd ./tarball-builder
  docker build -t egison-tarball-builder .
  docker tag egison-tarball-builder ghcr.io/egison/egison-tarball-builder:latest
  docker tag egison-tarball-builder ghcr.io/egison/egison-tarball-builder:"$TAG"
  docker push ghcr.io/egison/egison-tarball-builder:latest
  docker push ghcr.io/egison/egison-tarball-builder:"$TAG"
)
(
  cd ./deb-builder
  docker build -t egison-deb-builder .
  docker tag egison-deb-builder ghcr.io/egison/egison-deb-builder:latest
  docker tag egison-deb-builder ghcr.io/egison/egison-deb-builder:"$TAG"
  docker push ghcr.io/egison/egison-deb-builder:latest
  docker push ghcr.io/egison/egison-deb-builder:"$TAG"
)
(
  cd ./rpm-builder
  docker build -t egison-rpm-builder .
  docker tag egison-rpm-builder ghcr.io/egison/egison-rpm-builder:latest
  docker tag egison-rpm-builder ghcr.io/egison/egison-rpm-builder:"$TAG"
  docker push ghcr.io/egison/egison-rpm-builder:latest
  docker push ghcr.io/egison/egison-rpm-builder:"$TAG"
)
(
  cd ./egison-tutorial-tarball-builder
  docker build -t egison-tutorial-tarball-builder .
  docker tag egison-tutorial-tarball-builder ghcr.io/egison/egison-tutorial-tarball-builder:latest
  docker tag egison-tutorial-tarball-builder ghcr.io/egison/egison-tutorial-tarball-builder:"$TAG"
  docker push ghcr.io/egison/egison-tutorial-tarball-builder:latest
  docker push ghcr.io/egison/egison-tutorial-tarball-builder:"$TAG"

)
