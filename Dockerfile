# Build tensorflow from source with extra CPU (SSE4.1 SSE4.2 AVX AVX2 FMA) instructions
ARG PYTHON_VERSION
FROM python:$PYTHON_VERSION-slim-buster as tensorflow_builder

# prefix with OVERRIDE_ to prevent base image ENV var being used
ARG OVERRIDE_PIP_VERSION
ENV PIP_VERSION=$OVERRIDE_PIP_VERSION

RUN apt-get update -yqq \
  && apt-get install -yqq --no-install-recommends \
  python3-dev \
  python3-pip \
  git \
  wget \
  unzip \
  gcc \
  g++ \
  && rm -rf /var/lib/apt/lists/*

# Install bazel
# must match any version between _TF_MIN_BAZEL_VERSION and _TF_MAX_BAZEL_VERSION as specified in tensorflow/configure.py
ARG BAZEL_VERSION=0.26.1
ARG BAZELISK_VERSION=1.10.1
ENV USE_BAZEL_VERSION=${BAZEL_VERSION}
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64 -q && \
  mv bazelisk-linux-amd64 /bin/bazel && \
  chmod +x /bin/bazel

RUN pip install -U --user --no-cache-dir pip==${PIP_VERSION} wheel six mock "numpy<1.18.5" \
  && pip install -U --user --no-cache-dir keras_applications --no-deps \
  && pip install -U --user --no-cache-dir keras_preprocessing --no-deps

ARG TENSORFLOW_VERSION=1.15.5
RUN git -c advice.detachedHead=false \
  clone --depth 1 --branch v${TENSORFLOW_VERSION} https://github.com/tensorflow/tensorflow /tensorflow

WORKDIR /tensorflow

ENV \
  GCC_HOST_COMPILER_PATH="/usr/bin/gcc" \
  CC_OPT_FLAGS="-march=native"

RUN echo "Building tensorflow with $(nproc) parallel workers" \
  && gcc --version \
  && ./configure \
  && bazel build --config=v1 --config=opt \
  --config=nogcp \
  --config=nohdfs \
  --config=nokafka \
  --config=noignite \
  --copt=-w \
  --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2 --copt=-msse4.1 \
  --jobs=$(nproc) \
  //tensorflow/tools/pip_package:build_pip_package

RUN bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg \
  && ls /tmp/tensorflow_pkg
