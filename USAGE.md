# Ruoyi Code 使用指南

本文档覆盖 `rust/` 目录下的 Rust workspace 和 `ruoyi-cli` CLI 二进制。

## 快速开始

```bash
cd rust
cargo build --workspace
./target/debug/ruoyi-cli
# REPL 内执行健康检查
/doctor
```

## 前置条件

- Rust 工具链（`cargo`）
- 至少一个 LLM Provider 的 API Key：
  - `DEEPSEEK_API_KEY`（默认 Provider）
  - `ANTHROPIC_API_KEY`
  - `OPENAI_API_KEY`
  - 其他（见下方 Provider 列表）

## 基本用法

### 交互式 REPL

```bash
./target/debug/ruoyi-cli
```

### 单次提问

```bash
./target/debug/ruoyi-cli prompt "总结这个仓库"
./target/debug/ruoyi-cli "解释 rust/crates/runtime/src/lib.rs"
```

### JSON 输出（用于脚本）

```bash
./target/debug/ruoyi-cli --output-format json prompt "status"
```

### 指定模型和权限

```bash
./target/debug/ruoyi-cli --model deepseek-chat prompt "review this diff"
./target/debug/ruoyi-cli --model sonnet prompt "review this diff"
./target/debug/ruoyi-cli --permission-mode read-only prompt "summarize Cargo.toml"
./target/debug/ruoyi-cli --permission-mode workspace-write prompt "update README.md"
./target/debug/ruoyi-cli --allowedTools read,glob "inspect the runtime crate"
```

权限模式：`read-only` / `workspace-write` / `danger-full-access`

## 认证配置

### 方式一：全局配置（推荐）

一次配置，所有项目都能用：

```bash
mkdir -p ~/.ruoyi-cli
echo 'DEEPSEEK_API_KEY=sk-...' > ~/.ruoyi-cli/.env
```

### 方式二：项目级 `.env` 文件

在项目根目录创建 `.env` 文件（会覆盖全局配置）：

```bash
DEEPSEEK_API_KEY=sk-...
```

### 方式三：环境变量

```bash
export DEEPSEEK_API_KEY="sk-..."
```

优先级：环境变量 > 项目 `.env` > 全局 `~/.ruoyi-cli/.env`

### 支持的 API Key

| Provider | 环境变量 |
|----------|----------|
| DeepSeek（默认） | `DEEPSEEK_API_KEY` |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI / OpenRouter | `OPENAI_API_KEY` |
| xAI | `XAI_API_KEY` |
| DashScope (Qwen) | `DASHSCOPE_API_KEY` |

### OAuth（仅 Anthropic）

```bash
./target/debug/ruoyi-cli login
./target/debug/ruoyi-cli logout
```

## Provider 列表

| Provider | 协议 | 环境变量 | 默认 Base URL |
|----------|------|----------|---------------|
| **DeepSeek**（默认） | OpenAI-compatible | `DEEPSEEK_API_KEY` | `https://api.deepseek.com/v1` |
| **Anthropic** | Messages API | `ANTHROPIC_API_KEY` | `https://api.anthropic.com` |
| **xAI** | OpenAI-compatible | `XAI_API_KEY` | `https://api.x.ai/v1` |
| **OpenAI** | Chat Completions | `OPENAI_API_KEY` | `https://api.openai.com/v1` |
| **DashScope** | OpenAI-compatible | `DASHSCOPE_API_KEY` | `https://dashscope.aliyuncs.com/compatible-mode/v1` |

OpenAI-compatible 后端也支持 **OpenRouter** 和 **Ollama**，设置 `OPENAI_BASE_URL` 即可。

### 模型别名

| 别名 | 解析为 | Provider |
|------|--------|----------|
| `deepseek` | `deepseek-chat` | DeepSeek |
| `opus` | `claude-opus-4-6` | Anthropic |
| `sonnet` | `claude-sonnet-4-6` | Anthropic |
| `haiku` | `claude-haiku-4-5-20251213` | Anthropic |
| `grok` | `grok-3` | xAI |

### Provider 检测顺序

1. 模型名以 `deepseek` 开头 → DeepSeek
2. 模型名以 `claude` 开头 → Anthropic
3. 模型名以 `grok` 开头 → xAI
4. 模型名以 `openai/` 或 `gpt-` 开头 → OpenAI
5. 模型名以 `qwen/` 或 `qwen-` 开头 → DashScope
6. Fallback：检查环境变量，`DEEPSEEK_API_KEY` 优先

### 本地模型（Ollama）

```bash
export OPENAI_BASE_URL="http://127.0.0.1:11434/v1"
./target/debug/ruoyi-cli --model "llama3.2" prompt "hello"
```

### OpenRouter

```bash
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_API_KEY="sk-or-v1-..."
./target/debug/ruoyi-cli --model "openai/gpt-4.1-mini" prompt "hello"
```

## 自定义别名

在配置文件中添加：

```json
{
  "aliases": {
    "fast": "deepseek-chat",
    "smart": "claude-opus-4-6",
    "cheap": "deepseek-chat"
  }
}
```

## Session 管理

REPL 对话持久化在 `.ruoyi/sessions/` 目录下。

```bash
# 恢复最近会话
./target/debug/ruoyi-cli --resume latest
./target/debug/ruoyi-cli --resume latest /status /diff
```

REPL 内常用命令：`/help` `/status` `/cost` `/config` `/session` `/model` `/permissions` `/export`

## 配置文件优先级

后者覆盖前者：

1. `~/.ruoyi.json`
2. `~/.config/ruoyi/settings.json`
3. `<project>/.ruoyi.json`
4. `<project>/.ruoyi/settings.json`
5. `<project>/.ruoyi/settings.local.json`（本地，不提交）

## 常用操作命令

```bash
./target/debug/ruoyi-cli status
./target/debug/ruoyi-cli sandbox
./target/debug/ruoyi-cli agents
./target/debug/ruoyi-cli mcp
./target/debug/ruoyi-cli skills
```

## HTTP 代理

支持 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY` 环境变量。

```bash
export HTTPS_PROXY="http://proxy.corp.example:3128"
./target/debug/ruoyi-cli prompt "hello via proxy"
```

## 验证

```bash
cd rust
cargo test --workspace
```

## Workspace Crate 列表

- `api` — LLM Provider 通信层
- `commands` — 命令处理
- `compat-harness` — 兼容性测试
- `mock-anthropic-service` — Mock 服务
- `plugins` — 插件系统
- `runtime` — 运行时核心（Agent 循环、权限、Session）
- `ruoyi-cli` — CLI 入口
- `telemetry` — 遥测
- `tools` — 工具系统
