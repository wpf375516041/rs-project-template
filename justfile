# Docker 镜像
docker_image := "ghcr.io/rust-cross/cargo-zigbuild"
xwin_image := "messense/cargo-xwin"
# 项目根目录
project_dir := justfile_directory()
# 缓存模式：project=项目内, shared=用户目录共享（~/.docker-rust-cross）
cache_mode := env_var_or_default("CROSS_CACHE_MODE", "shared")
# 持久化目录：缓存 Rust 工具链和 Cargo 数据，避免每次 docker run 重复下载
docker_rust := if cache_mode == "shared" { env_var("HOME") + "/.docker-rust-cross" } else { project_dir + "/.docker-rust" }
# zigbuild 和 xwin 镜像的工具链版本不同，需分开缓存
zigbuild_rust := docker_rust + "/zigbuild"
xwin_rust     := docker_rust + "/xwin"
# xwin MSVC CRT/SDK 缓存目录
cache_dir := if cache_mode == "shared" { env_var("HOME") + "/.docker-rust-cross/cache" } else { project_dir + "/.cache" }
# 以当前用户身份运行容器，避免产物属于 root；设置 HOME=/io 使缓存写入项目目录
docker_user := "--user $(id -u):$(id -g) -e HOME=/io"

# 检查 Docker 是否可用
check-docker:
    #!/usr/bin/env bash
    if ! command -v docker &>/dev/null; then
        echo "Error: docker not found. Install: https://docs.docker.com/get-docker/" >&2
        exit 1
    fi

# 初始化 zigbuild 持久化目录（从镜像中复制预装工具链）
# 挂载空目录会覆盖镜像中的预装内容，导致 cargo 找不到，所以需要先"播种"
init-zigbuild-rust: check-docker
    #!/usr/bin/env bash
    if [ -d "{{zigbuild_rust}}/rustup/toolchains" ]; then exit 0; fi
    mkdir -p "{{zigbuild_rust}}/rustup" "{{zigbuild_rust}}/cargo"
    docker run --rm --user $(id -u):$(id -g) {{docker_image}} tar -C /usr/local/rustup -cf - . | tar -C "{{zigbuild_rust}}/rustup" -xf -
    docker run --rm --user $(id -u):$(id -g) {{docker_image}} tar -C /usr/local/cargo -cf - . | tar -C "{{zigbuild_rust}}/cargo" -xf -

# 初始化 xwin 持久化目录（从镜像中复制预装工具链）
init-xwin-rust: check-docker
    #!/usr/bin/env bash
    if [ -d "{{xwin_rust}}/rustup/toolchains" ]; then exit 0; fi
    mkdir -p "{{xwin_rust}}/rustup" "{{xwin_rust}}/cargo"
    docker run --rm --user $(id -u):$(id -g) {{xwin_image}} tar -C /usr/local/rustup -cf - . | tar -C "{{xwin_rust}}/rustup" -xf -
    docker run --rm --user $(id -u):$(id -g) {{xwin_image}} tar -C /usr/local/cargo -cf - . | tar -C "{{xwin_rust}}/cargo" -xf -

default:
    @just --list

# 本地构建
build:
    cargo build

build-release:
    cargo build --release

# 交叉编译所有平台
build-all: build-macos-arm64 build-macos-x86_64 build-linux-x86_64 build-windows-x86_64

build-all-release: build-macos-arm64-release build-macos-x86_64-release build-linux-x86_64-release build-windows-x86_64-release

# macOS ARM64 (Docker + zigbuild)
build-macos-arm64: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --target aarch64-apple-darwin

build-macos-arm64-release: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --release --target aarch64-apple-darwin

# macOS x86_64 (Docker + zigbuild)
build-macos-x86_64: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --target x86_64-apple-darwin

build-macos-x86_64-release: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --release --target x86_64-apple-darwin

# Linux x86_64 musl 静态链接 (Docker + zigbuild)
build-linux-x86_64: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --target x86_64-unknown-linux-musl

build-linux-x86_64-release: init-zigbuild-rust
    docker run --rm {{docker_user}} \
        -v {{zigbuild_rust}}/rustup:/usr/local/rustup \
        -v {{zigbuild_rust}}/cargo:/usr/local/cargo \
        -v {{project_dir}}:/io -w /io {{docker_image}} \
        cargo zigbuild --release --target x86_64-unknown-linux-musl

# Windows x86_64 MSVC (Docker + cargo-xwin，zigbuild 不支持 MSVC ABI)
# XWIN_CACHE_DIR 持久化 MSVC CRT/SDK；挂载宿主机 cache_dir/xwin 到容器 /io/.cache/xwin
build-windows-x86_64: init-xwin-rust
    docker run --rm {{docker_user}} \
        -e XWIN_CACHE_DIR=/io/.cache/xwin \
        -v {{xwin_rust}}/rustup:/usr/local/rustup \
        -v {{xwin_rust}}/cargo:/usr/local/cargo \
        -v {{cache_dir}}/xwin:/io/.cache/xwin \
        -v {{project_dir}}:/io -w /io {{xwin_image}} \
        cargo xwin build --target x86_64-pc-windows-msvc

build-windows-x86_64-release: init-xwin-rust
    docker run --rm {{docker_user}} \
        -e XWIN_CACHE_DIR=/io/.cache/xwin \
        -v {{xwin_rust}}/rustup:/usr/local/rustup \
        -v {{xwin_rust}}/cargo:/usr/local/cargo \
        -v {{cache_dir}}/xwin:/io/.cache/xwin \
        -v {{project_dir}}:/io -w /io {{xwin_image}} \
        cargo xwin build --release --target x86_64-pc-windows-msvc

test:
    cargo test

lint:
    cargo clippy -- -D warnings

fmt:
    cargo fmt --check

fmt-fix:
    cargo fmt
