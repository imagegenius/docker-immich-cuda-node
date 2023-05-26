# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG TORCH_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz, martabal"

# environment settings
ENV PIP_FLAGS="-U --no-cache-dir"

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    g++ \
    libcublas11 \
    libcublaslt11 \
    libcurand10 \
    libcufft10 \
    libcudart11.0 \
    python3-dev \
    python3-pip && \
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
  pip install ${PIP_FLAGS} \
    insightface \
    fastapi \
    nltk \
    numpy \
    onnxruntime-gpu \
    Pillow \
    scikit-learn \
    scipy \
    sentence-transformers \
    tqdm \
    transformers \
    uvicorn[standard] && \
  mkdir -p \
    /app/immich/machine-learning && \
  cp -a \
    src \
    /app/immich/machine-learning && \
  echo "**** cleanup ****" && \
  for cleanfiles in *.pyc *.pyo; do \
    find /usr/local/lib/python3.* /usr/lib/python3.* -name "${cleanfiles}" -delete; \
  done && \
  apt-get remove -y --purge \
    g++ \
    python3-dev && \
  apt-get autoremove -y --purge && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apt/lists/*

# copy local files
COPY root/ /

# environment settings
ENV HOME="/config" \
  MACHINE_LEARNING_CACHE_FOLDER="/config/machine-learning" \
  TORCH_VERSION=${TORCH_VERSION} \
  PATH="/config/.local/bin:$PATH"

# ports and volumes
EXPOSE 3003
VOLUME /config
