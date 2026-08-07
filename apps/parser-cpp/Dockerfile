FROM ubuntu:24.04 AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends cmake g++ \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY CMakeLists.txt ./
COPY src ./src
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && cmake --build build

FROM ubuntu:24.04
RUN useradd --system --uid 10001 --create-home skybridge
WORKDIR /app
COPY --from=build --chown=skybridge:skybridge /src/build/skybridge-parser ./skybridge-parser
USER 10001
EXPOSE 8080
ENV PARSER_PORT=8080
ENTRYPOINT ["/app/skybridge-parser"]