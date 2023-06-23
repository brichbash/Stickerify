FROM ghcr.io/graalvm/native-image-community:20-muslib AS builder
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin
RUN --mount=type=cache,target=/var/cache/yum \
    microdnf install -y findutils # import xargs for gradlew

WORKDIR /app
COPY . .
# disabled for now https://github.com/graalvm/native-build-tools/issues/455
# RUN ./gradlew -Pagent test --no-daemon
# RUN ./gradlew metadataCopy --task test --dir src/main/resources/META-INF/native-image --no-daemon
RUN ./gradlew nativeCompile --no-daemon

FROM scratch AS bot
COPY --from=builder /usr/local/bin/ffmpeg /
COPY --from=builder /app/build/native/nativeCompile/Stickerify /

ENTRYPOINT ["/Stickerify"]
