ARG BIN=vault-auto-unseal

FROM messense/rust-musl-cross:x86_64-musl AS chef
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
ENV BIN=$BIN

COPY --from=planner /app/recipe.json .

RUN cargo chef cook --release

COPY vault-auto-unseal/app/src ./src
COPY vault-auto-unseal/app/Cargo.toml ./Cargo.lock ./

RUN cargo build --release --bin $BIN
RUN mv ./target/x86_64-unknown-linux-musl/release/$BIN ./app

FROM alpine

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /app
COPY --from=builder /app/app /usr/local/bin/

CMD ["app"]