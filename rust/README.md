# Ruoyi Code — Rust Workspace

Rust 实现的 CLI Agent 工具。

详细使用说明见 [`../USAGE.md`](../USAGE.md)。

## 快速开始

```bash
cd rust/
cargo build --workspace
cargo run -p ruoyi-cli -- --help
cargo run -p ruoyi-cli -- --model deepseek-chat prompt "explain this codebase"
```

## Crate 结构

```
rust/
├── crates/
│   ├── api/                  # LLM Provider 通信层
│   ├── commands/             # 命令处理
│   ├── compat-harness/       # 兼容性测试
│   ├── mock-anthropic-service/ # Mock 服务
│   ├── plugins/              # 插件系统
│   ├── runtime/              # 运行时核心
│   ├── ruoyi-cli/            # CLI 入口 (ruoyi 二进制)
│   ├── telemetry/            # 遥测
│   └── tools/                # 工具系统 (40+ 内置工具)
└── Cargo.toml
```

## 验证

```bash
cargo fmt
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```
