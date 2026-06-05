# {{project-name}}

基于 [rs-project-template](https://github.com/wpf375516041/rs-project-template) 生成的 Rust 项目。

## 特性

- **Tokio** 异步运行时
- **Tracing** 结构化日志
- **Jemalloc** 内存分配器（非 MSVC 平台）
- **pprof** 内存分析支持（按需开启）
- 跨平台交叉编译支持（macOS / Linux / Windows）

## 支持平台

| 平台    | 目标三元组                    | 架构   | 构建方式                          |
| ------- | ----------------------------- | ------ | --------------------------------- |
| macOS   | `aarch64-apple-darwin`        | ARM64  | Docker (cargo-zigbuild)           |
| macOS   | `x86_64-apple-darwin`         | x86_64 | Docker (cargo-zigbuild)           |
| Linux   | `x86_64-unknown-linux-musl`   | x86_64 | Docker (cargo-zigbuild)           |
| Windows | `x86_64-pc-windows-msvc`      | x86_64 | Docker (cargo-xwin)               |

> Linux 使用 musl 静态链接，生成的二进制无 glibc 依赖，可在任意 Linux 发行版（含 CentOS 7）上运行。

## 前置要求

- Rust 稳定版工具链
- [Docker](https://docs.docker.com/get-docker/)（交叉编译，所有平台）
- [just](https://github.com/casey/just)（可选，快捷构建命令）

## 快速开始

```shell
# 从模板生成新项目
cargo generate --git https://github.com/wpf375516041/rs-project-template

# 构建
cargo build -r --bin main

# 运行
cargo run -r --bin main
```

## 使用 justfile

```shell
# 查看所有可用命令
just

# 构建当前平台
just build

# 构建 release 版本
just build-release

# 交叉编译所有平台
just build-all-release

# 交叉编译单个平台
just build-macos-arm64-release
just build-macos-x86_64-release
just build-linux-x86_64-release
just build-windows-x86_64-release

# 运行测试
just test

# 代码检查
just lint

# 格式化检查
just fmt
```

## 平台差异说明

- **Windows (MSVC)**: Jemalloc 和 pprof 不可用，自动回退到系统默认内存分配器。
- **macOS / Linux**: 完整功能，包括 Jemalloc 内存分配器和 pprof 分析支持。
