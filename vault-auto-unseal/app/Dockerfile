ARG TARGET=x86_64-unknown-linux-musl
ARG BIN=vault-auto-unseal

FROM profidev/rust-musl-builder:latest AS chef
RUN rustup update

RUN cargo install cargo-chef 
WORKDIR /app

FROM chef AS planner

ARG BIN
ENV BIN=$BIN

COPY vault-auto-unseal/app/src ./src
COPY vault-auto-unseal/app/Cargo.toml ./Cargo.lock ./

RUN cargo chef prepare --recipe-path recipe.json --bin $BIN

FROM chef AS builder

ARG BIN
ARG TARGET
ENV BIN=$BIN
ENV TARGET=$TARGET

COPY --from=planner /app/recipe.json .

RUN cargo chef cook --release --target $TARGET

COPY vault-auto-unseal/app/src ./src
COPY vault-auto-unseal/app/Cargo.toml ./Cargo.lock ./

RUN cargo build --release --target $TARGET --bin $BIN
RUN mv ./target/$TARGET/release/$BIN ./app

FROM alpine

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /app
COPY --from=builder /app/app /usr/local/bin/

CMD ["app"]