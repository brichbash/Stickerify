FROM ubuntu:23.10 AS builder

RUN rm -f /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends wget ca-certificates build-essential zlib1g-dev ffmpeg && \
    rm -rf /var/lib/apt/lists/*

ARG JAVA_VERSION=20
ARG MUSL_VERSION=10.2.1
ARG ZLIB_VERSION=1.2.13

RUN mkdir /opt/graalvm-jdk-${JAVA_VERSION} && \
    wget https://download.oracle.com/graalvm/${JAVA_VERSION}/latest/graalvm-jdk-${JAVA_VERSION}_linux-x64_bin.tar.gz -P /tmp && \
    tar zxvf /tmp/graalvm-jdk-${JAVA_VERSION}_linux-x64_bin.tar.gz -C /opt/graalvm-jdk-${JAVA_VERSION} --strip-components 1 && \
    wget http://more.musl.cc/${MUSL_VERSION}/x86_64-linux-musl/x86_64-linux-musl-native.tgz -P /tmp && \
    mkdir /opt/musl-${MUSL_VERSION} && \
    tar -zxvf /tmp/x86_64-linux-musl-native.tgz -C /opt/musl-${MUSL_VERSION}/ && \
    wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz -P /tmp && \
    tar -zxvf /tmp/zlib-${ZLIB_VERSION}.tar.gz -C /tmp

ENV TOOLCHAIN_DIR=/opt/musl-${MUSL_VERSION}/x86_64-linux-musl-native
ENV PATH=${TOOLCHAIN_DIR}/bin:${PATH}
ENV CC=${TOOLCHAIN_DIR}/bin/gcc

WORKDIR /tmp/zlib-${ZLIB_VERSION}
RUN ./configure --prefix=${TOOLCHAIN_DIR} --static && make && make install

ENV JAVA_HOME=/opt/graalvm-jdk-${JAVA_VERSION}
ENV PATH=${JAVA_HOME}/bin:${PATH}

RUN rm -rf /tmp/*

WORKDIR /app

COPY gradlew ./
COPY gradle/wrapper/* ./gradle/wrapper/
RUN ./gradlew --version --no-daemon

COPY settings.gradle build.gradle ./
COPY gradle/libs.versions.toml ./gradle/
RUN --mount=type=cache,target=/home/gradle/.gradle/caches \
    ./gradlew dependencies --no-daemon

COPY . .
RUN ./gradlew -Pagent test --no-daemon
RUN ./gradlew metadataCopy --task test --dir src/main/resources/META-INF/native-image --no-daemon
RUN ./gradlew nativeCompile --no-daemon
RUN strip --strip-all build/native/nativeCompile/Stickerify

FROM scratch AS bot
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /
COPY --from=builder /app/build/native/nativeCompile/Stickerify /
ENTRYPOINT ["/Stickerify", "-Djava.io.tmpdir=/"]
