FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /src
COPY src ./src
RUN mkdir -p build/classes \
    && javac --release 21 -d build/classes src/SkybridgeGateway.java \
    && jar --create --file build/gateway-java.jar --main-class SkybridgeGateway -C build/classes .

FROM eclipse-temurin:21-jre-jammy
RUN useradd --system --uid 10001 --create-home skybridge
WORKDIR /app
COPY --from=build --chown=skybridge:skybridge /src/build/gateway-java.jar ./gateway-java.jar
USER 10001
EXPOSE 4561
ENV GATEWAY_PORT=4561 \
    PARSER_URL=http://parser:8080 \
    GATEWAY_PARSER_TIMEOUT_MS=3000
ENTRYPOINT ["java", "-jar", "/app/gateway-java.jar"]