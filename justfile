docker_image := "ghcr.io/rust-cross/cargo-zigbuild"
project_dir := justfile_directory()

default:
    @just --list

build:
    cargo build

build-release:
    cargo build --release

build-all: build-macos-arm64 build-macos-x86_64 build-linux-x86_64 build-windows-x86_64

build-all-release: build-macos-arm64-release build-macos-x86_64-release build-linux-x86_64-release build-windows-x86_64-release

# macOS ARM64 (Docker)
build-macos-arm64:
    docker run --rm -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --target aarch64-apple-darwin

build-macos-arm64-release:
    docker run --rm -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --release --target aarch64-apple-darwin

# macOS x86_64 (Docker)
build-macos-x86_64:
    docker run --rm -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --target x86_64-apple-darwin

build-macos-x86_64-release:
    docker run --rm -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --release --target x86_64-apple-darwin

# Linux x86_64 musl (静态链接)
build-linux-x86_64:
    cargo zigbuild --target x86_64-unknown-linux-musl

build-linux-x86_64-release:
    cargo zigbuild --release --target x86_64-unknown-linux-musl

# Windows x86_64 MSVC
build-windows-x86_64:
    cargo xwin build --target x86_64-pc-windows-msvc

build-windows-x86_64-release:
    cargo xwin build --release --target x86_64-pc-windows-msvc

test:
    cargo test

lint:
    cargo clippy -- -D warnings

fmt:
    cargo fmt --check

fmt-fix:
    cargo fmt
