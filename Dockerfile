# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG IMMICH_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz, martabal"

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    g++ \
    libcublas11 \
    libcublaslt11 \
    libcudart11.0 \
    libcufft10 \
    libcurand10 \
    python3-dev \
    python3-venv && \
  echo "**** download immich ****" && \
  mkdir -p \
    /tmp/immich && \
  if [ -z ${IMMICH_VERSION} ]; then \
    IMMICH_VERSION=$(curl -sL https://api.github.com/repos/immich-app/immich/releases/latest | \
      jq -r '.tag_name'); \
  fi && \
  curl -o \
    /tmp/immich.tar.gz -L \
    "https://github.com/immich-app/immich/archive/${IMMICH_VERSION}.tar.gz" && \
  tar xf \
    /tmp/immich.tar.gz -C \
    /tmp/immich --strip-components=1 && \
  echo "**** install machine-learning ****" && \
  cd /tmp/immich/machine-learning && \
  mkdir -p \
    /app/immich/machine-learning && \
  cp -a \
    src \
    /app/immich/machine-learning && \
  echo "**** cleanup ****" && \
  apt-get autoremove -y --purge && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apt/lists/*

# copy local files
COPY root/ /

# environment settings
ENV MACHINE_LEARNING_CACHE_FOLDER="/config/machine-learning"

# ports and volumes
EXPOSE 3003
VOLUME /config
