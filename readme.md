# {{project-name}}

基于 [rs-project-template](https://github.com/wpf375516041/rs-project-template) 生成的 Rust 项目。

## 特性

- **Tokio** 异步运行时
- **Tracing** 结构化日志
- **Jemalloc** 内存分配器（非 MSVC 平台）
- **pprof** 内存分析支持（按需开启）

## 前置要求

- Rust 稳定版工具链

## 快速开始

```shell
# 从模板生成新项目
cargo generate --git https://github.com/wpf375516041/rs-project-template

# 构建
cargo build -r --bin main

# 运行
cargo run -r --bin main
```