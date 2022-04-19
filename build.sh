#!/usr/bin/env bash

set -euxo pipefail

UBUNTU_VERSION="${UBUNTU_VERSION:-focal}"
UBUNTU_IMAGE="ubuntu:${UBUNTU_VERSION}"

docker pull ubuntu:${UBUNTU_VERSION} \
&& docker build \
  --tag ghcr.io/cameo-engineering/set:latest \
  --build-arg UBUNTU_VERSION \
  --build-arg GIT_COMMIT_ID=$(git rev-parse -q --verify HEAD) \
  --build-arg BUILD_DATE_TIME="$(date --utc --rfc-3339=seconds)" \
  --build-arg UBUNTU_IMAGE_DIGEST=$(docker images --no-trunc --quiet ${UBUNTU_IMAGE}) \
  .
