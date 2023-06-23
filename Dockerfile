FROM ghcr.io/graalvm/native-image-community:20-muslib AS builder

COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin
RUN microdnf install -y findutils # import xargs for gradlew

WORKDIR /app

COPY gradlew ./
COPY gradle/wrapper/* ./gradle/wrapper/
RUN ./gradlew --version --no-daemon

COPY settings.gradle build.gradle ./
COPY gradle/libs.versions.toml ./gradle/
RUN ./gradlew dependencies --no-daemon

COPY . .
# disabled for now https://github.com/graalvm/native-build-tools/issues/455
# RUN ./gradlew -Pagent test --no-daemon
# RUN ./gradlew metadataCopy --task test --dir src/main/resources/META-INF/native-image --no-daemon
RUN ./gradlew nativeCompile --no-daemon
RUN strip --strip-all build/native/nativeCompile/Stickerify

FROM scratch AS bot

COPY --from=builder /usr/local/bin/ffmpeg /
COPY --from=builder /app/build/native/nativeCompile/Stickerify /

ENTRYPOINT ["/Stickerify", "-Djava.io.tmpdir=/"]
