ARG IMAGE=nginx:1.21.6-alpine

FROM ${IMAGE}

WORKDIR /app

RUN apk add --no-cache make cmake gcc g++ git
RUN apk add --no-cache build-base linux-headers alpine-sdk
RUN apk add --no-cache pkgconfig autoconf gnupg libtool
RUN apk add --no-cache curl ca-certificates
RUN apk add --no-cache curl-dev pcre-dev zlib-dev protobuf-dev
RUN apk add --no-cache c-ares-dev re2-dev
RUN apk add --no-cache libstdc++


RUN git clone --shallow-submodules --recurse-submodules -b v1.49.2 \
  https://github.com/grpc/grpc \
  && cd grpc \
  && mkdir -p cmake/build \
  && cd cmake/build \
  && cmake \
    -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=/install \
    -DCMAKE_BUILD_TYPE=Release \
    -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
    -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
    -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
    -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
    -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
    -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
    -DCMAKE_CXX_STANDARD=17 \
    ../.. \
  && make -j2 \
  && make install

RUN git clone --shallow-submodules --depth 1 --recurse-submodules -b v1.8.1 \
  https://github.com/open-telemetry/opentelemetry-cpp.git \
  && cd opentelemetry-cpp \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/install \
    -DCMAKE_PREFIX_PATH=/install \
    -DWITH_OTLP=ON \
    -DWITH_OTLP_GRPC=ON \
    -DWITH_OTLP_HTTP=OFF \
    -DBUILD_TESTING=OFF \
    -DWITH_EXAMPLES=OFF \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    .. \
  && make -j2 \
  && make install

RUN git clone https://github.com/open-telemetry/opentelemetry-cpp-contrib.git \
  && cd opentelemetry-cpp-contrib/instrumentation/nginx \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release \
    -DNGINX_BIN=/usr/sbin/nginx \
    -DCMAKE_PREFIX_PATH=/install \
    -DCMAKE_INSTALL_PREFIX=/usr/lib/nginx/modules/ \
    .. \
  && make -j2 \
  && make install
