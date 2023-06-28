FROM ghcr.io/graalvm/native-image-community:20-muslib AS builder
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin
RUN --mount=type=cache,target=/var/cache/yum \
    microdnf install -y findutils which

WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/root/.gradle/wrapper \
    --mount=type=cache,target=/root/.gradle/caches/jars-9 \
    --mount=type=cache,target=/root/.gradle/caches/modules-2 \
    ./gradlew -Pagent test --no-daemon && \
    ./gradlew metadataCopy --no-daemon && \
    ./gradlew nativeCompile --no-daemon

FROM gcr.io/distroless/static-debian11:latest AS bot
COPY --from=builder /usr/local/bin/ffmpeg /
COPY --from=builder /app/build/native/nativeCompile/Stickerify /
COPY --from=builder /app/build/native/nativeCompile/*.so /lib/

ENTRYPOINT ["/Stickerify"]
