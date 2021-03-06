ARG UBUNTU_VERSION=focal
FROM ubuntu:${UBUNTU_VERSION}
ARG UBUNTU_VERSION

ARG UBUNTU_IMAGE_DIGEST
LABEL \
  org.opencontainers.image.authors="Andrey Gulitsky <agulitsky@cameo.engineering>" \
  org.opencontainers.image.base.name="docker.io/library/ubuntu:${UBUNTU_VERSION}" \
  org.opencontainers.image.base.digest=${UBUNTU_IMAGE_DIGEST} \
  org.opencontainers.image.description="Docker-powered Solidity development and CI/CD environment." \
  org.opencontainers.image.documentation="https://github.com/cameo-engineering/set#readme" \
  org.opencontainers.image.licenses="ISC" \
  org.opencontainers.image.ref.name="latest" \
  org.opencontainers.image.source="https://github.com/cameo-engineering/set" \
  org.opencontainers.image.title="Set" \
  org.opencontainers.image.url="https://github.com/cameo-engineering/set" \
  org.opencontainers.image.vendor="Cameo Engineering" \
  org.opencontainers.image.version="1.0.0"

ARG BUILD_DATE_TIME
LABEL org.opencontainers.image.created=${BUILD_DATE_TIME}

ARG GIT_COMMIT_ID
LABEL org.opencontainers.image.revision=${GIT_COMMIT_ID}

# Prerequisites
ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux \
  && apt-get update -qq \
  && apt-get install -qq --no-install-recommends \
  apt-utils \
  build-essential \
  ca-certificates \
  curl \
  gnupg \
  git \
  jq \
  python3-dev \
  python-is-python3 \
  python3-pip \
  wget \
  < /dev/null > /dev/null \
  && rm -rf /var/lib/apt/lists/* /var/log/*

# Node.js / pnpm / zx
ARG NODE_JS_VERSION="16"
ARG PNPM_VERSION="7.0.0-rc.8"
RUN set -eux \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
  | gpg --dearmor > /usr/share/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_JS_VERSION.x $UBUNTU_VERSION main" > /etc/apt/sources.list.d/nodesource.list\
  \
  && apt-get update -qq \
  && apt-get install -qq --no-install-recommends \
  nodejs \
  < /dev/null > /dev/null \
  && rm -rf /var/lib/apt/lists/* /var/log/* \
  \
  && corepack enable \
  && corepack prepare pnpm@${PNPM_VERSION} --activate \
  \
  && npm install --global zx \
  && npm cache clean --force

# Just
ARG JUST_VERSION="1.1.2"
RUN set -eux \
  && curl -fsSL https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz -o ./just.tar.gz \
  && tar -xzf ./just.tar.gz -C /usr/local/bin/ just \
  && rm -rf ./just.tar.gz

# Foundry
ARG FOUNDRY_VERSION="nightly-5490c4a0fef0a83827e4d5642730ea9ceff641b2"
RUN set -eux \
  && curl -fsSL https://github.com/foundry-rs/foundry/releases/download/${FOUNDRY_VERSION}/foundry_nightly_linux_amd64.tar.gz -o ./foundry.tar.gz \
  && tar -xzf ./foundry.tar.gz -C /usr/local/bin/ \
  && rm -rf ./foundry.tar.gz

# Slither / Mythrill / Manticore / solc-select
RUN set -eux \
  && pip3 install \
  slither-analyzer \
  mythril \
  manticore \
  solc-select -qqq --no-cache-dir

# Echidna
ARG ECHIDNA_VERSION="2.0.1"
RUN set -eux \
  && curl -fsSL https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz -o ./echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz \
  && curl -fsSL https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz.sha256 -o ./echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz.sha256 \
  \
  && sha256sum -c ./echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz.sha256 \
  \
  && tar -xzf ./echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04.tar.gz -C /usr/local/bin/ \
  && rm -rf ./echidna*

ARG USER="cameo"
RUN set -eux \
  && adduser \
  --system \
  --group \
  --shell /bin/bash \
  --disabled-password \
  --gecos '' \
  --home /home/${USER}/ \
  ${USER}
WORKDIR /home/${USER}/