FROM ubuntu:23.10 AS builder

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y wget ca-certificates build-essential zlib1g-dev ffmpeg

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

COPY gradlew settings.gradle build.gradle ./
COPY gradle/libs.versions.toml ./gradle/
COPY gradle/wrapper/* ./gradle/wrapper/
RUN ./gradlew dependencies

COPY . .
RUN ./gradlew -Pagent test
RUN ./gradlew nativeCompile

FROM scratch AS bot
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /
COPY --from=builder /app/build/native/nativeCompile/Stickerify /
ENTRYPOINT ["/Stickerify", "-Djava.io.tmpdir=/"]
