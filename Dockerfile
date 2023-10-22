FROM rust:1.73 as builder

WORKDIR /usr/src/downloads
WORKDIR /usr/src/protoc
ENV PROTOC_DIR /usr/src/protoc

ENV PB_REL="https://github.com/protocolbuffers/protobuf/releases"
ENV PB_VER="24.4"
ENV PB_ARCH="x86_64"
RUN curl -LO --output-dir /usr/src/downloads "$PB_REL/download/v${PB_VER}/protoc-${PB_VER}-linux-${PB_ARCH}.zip" && \
  unzip /usr/src/downloads/protoc-${PB_VER}-linux-${PB_ARCH}.zip -d "${PROTOC_DIR}"
ENV PATH="${PATH}:${PROTOC_DIR}/bin"
ENV PROTOC="${PROTOC_DIR}/bin/protoc"

WORKDIR /usr/src/anki

RUN git clone https://github.com/ankitects/anki.git . && \
  git checkout 2.1.66

RUN cargo build -p configure
RUN mkdir out
RUN cargo run -p configure

WORKDIR /usr/src/n2

RUN git clone https://github.com/evmar/n2 .
RUN cargo build --release

WORKDIR /usr/src/anki

RUN cargo build -p runner --release
RUN mkdir -p out/rust/release && cp target/release/runner out/rust/release
RUN /usr/src/n2/target/release/n2 -f out/build.ninja ftl

RUN cargo build -p anki-sync-server --release

FROM debian:stable

RUN useradd -ms /bin/bash anki

USER anki

WORKDIR /data

ENV SYNC_BASE /data

WORKDIR /home/anki

COPY --chown=anki:root --chmod=0500 --from=builder /usr/src/anki/target/release/anki-sync-server /usr/local/bin/anki-sync-server

COPY --chown=anki:root --chmod=0500 entrypoint.sh /entrypoint.sh
#RUN whoami && ls -l /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/local/bin/anki-sync-server"]
