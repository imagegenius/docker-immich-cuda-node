# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/baseimage-ubuntu:lunar

# set version label
ARG BUILD_DATE
ARG VERSION
ARG TORCH_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz, martabal"

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    g++ \
    python3-dev \
    python3-fastapi \
    python3-nltk \
    python3-numpy \
    python3-pil \
    python3-pip \
    python3-sentencepiece \
    python3-tqdm \
    python3-uvicorn && \
  echo "**** download immich ****" && \
  mkdir -p \
    /tmp/immich && \
  IMMICH_VERSION=$(curl -sL https://api.github.com/repos/immich-app/immich/releases/latest | \
    jq -r '.tag_name'); \
  curl -o \
    /tmp/immich.tar.gz -L \
    "https://github.com/immich-app/immich/archive/${IMMICH_VERSION}.tar.gz" && \
  tar xf \
    /tmp/immich.tar.gz -C \
    /tmp/immich --strip-components=1 && \
  echo "**** build machine-learning ****" && \
  cd /tmp/immich/machine-learning && \
  pip install --break-system-packages -U --no-cache-dir --pre -f https://download.pytorch.org/whl/nightly/cpu/torch_nightly.html \
    coloredlogs \
    flatbuffers \
    insightface \
    packaging \
    protobuf \
    scikit-learn \
    scipy \
    sentence-transformers \
    sympy \
    torch \
    transformers && \
  pip install -U --no-cache-dir --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/ORT-Nightly/pypi/simple/ \
    ort-nightly-gpu && \
  mkdir -p \
    /app/immich/machine-learning && \
  cp -a \
    src \
    /app/immich/machine-learning && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apt/lists/*

# copy local files
COPY root/ /

# environment settings
ENV HOME="/config" \
  MACHINE_LEARNING_CACHE_FOLDER="/config/machine-learning" \
  TORCH_VERSION=${TORCH_VERSION}

# ports and volumes
EXPOSE 3003
VOLUME /config
