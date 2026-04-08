# Ruoyi Code 🐕

<p align="center">
  <a href="https://github.com/JiekerTime/ruoyi-code">JiekerTime/ruoyi-code</a>
</p>

```
    / \__
   (    @\___    RUOYI
   /         O
  /   (_____/
 /_____/   U
```

**让每个人都能用上 AI 编码。**

Ruoyi Code 是一个基于 Rust 实现的 CLI Agent 工具，支持多 LLM Provider。

## 特性

- **多 Provider 支持**：DeepSeek（默认）、Anthropic、OpenAI、xAI、DashScope、Ollama、OpenRouter
- **工具系统**：内置 40+ 工具（Bash、文件读写、搜索、Agent 子任务等）
- **权限控制**：ReadOnly / WorkspaceWrite / DangerFullAccess 三级权限
- **MCP 支持**：Model Context Protocol 客户端与服务端
- **Session 管理**：JSONL 持久化、自动压缩、会话恢复
- **Hooks 系统**：PreToolUse / PostToolUse / PostToolUseFailure
- **插件系统**：可扩展的插件架构

## 快速开始

### 一键安装（自动安装 Rust 工具链）

**Linux / macOS：**
```bash
git clone https://github.com/JiekerTime/ruoyi-code.git
cd ruoyi-code
./install.sh
```

**Windows (PowerShell)：**
```powershell
git clone https://github.com/JiekerTime/ruoyi-code.git
cd ruoyi-code
.\install.ps1
```

### 手动编译

```bash
cd rust
cargo build --workspace
./target/debug/ruoyi-cli --help
```

### 认证配置

**全局配置（推荐，一次配置到处可用）：**

```bash
mkdir -p ~/.ruoyi-cli
echo 'DEEPSEEK_API_KEY=sk-...' > ~/.ruoyi-cli/.env
```

也可以在项目目录下创建 `.env` 文件（会覆盖全局配置）：

```bash
DEEPSEEK_API_KEY=sk-...
```

支持的 Key（按需配置一个即可）：

| Provider | 环境变量 |
|----------|----------|
| DeepSeek（默认） | `DEEPSEEK_API_KEY` |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| xAI | `XAI_API_KEY` |
| DashScope | `DASHSCOPE_API_KEY` |

### 基本用法

```bash
# 交互式 REPL
./target/debug/ruoyi-cli

# 单次提问
./target/debug/ruoyi-cli prompt "总结这个仓库"

# 指定模型
./target/debug/ruoyi-cli --model deepseek-chat prompt "解释这段代码"
./target/debug/ruoyi-cli --model claude-sonnet-4-6 prompt "review this diff"

# JSON 输出
./target/debug/ruoyi-cli --output-format json prompt "status"
```

### 运行测试

```bash
cd rust
cargo test --workspace
```

## 项目结构

- **`rust/`** — Rust workspace，`ruoyi-cli` CLI 二进制
- **`USAGE.md`** — 详细使用指南

## 支持的模型

| Provider | 模型 | 环境变量 |
|----------|------|----------|
| DeepSeek | `deepseek-chat`, `deepseek-reasoner` | `DEEPSEEK_API_KEY` |
| Anthropic | `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5` | `ANTHROPIC_API_KEY` |
| OpenAI | `gpt-4o`, `gpt-4.1-mini` | `OPENAI_API_KEY` |
| xAI | `grok-3`, `grok-3-mini` | `XAI_API_KEY` |
| DashScope | `qwen-max`, `qwen-plus` | `DASHSCOPE_API_KEY` |
| Ollama | 本地模型 | `OLLAMA_BASE_URL` |

## 配置文件

**API Key 配置（`.env` 文件）：**
- 全局：`~/.ruoyi-cli/.env`
- 项目级：`<project>/.env`

**运行时配置（hooks、权限、插件等）：**
- 全局：`~/.config/ruoyi/settings.json`
- 项目级：`<project>/.ruoyi/settings.json`
- 本地（不提交）：`<project>/.ruoyi/settings.local.json`

## 参与共建

本项目仍在早期开发阶段，功能尚不完善，欢迎参与共建。无论是提交 Issue、PR、还是使用反馈，都是对项目的支持。

你可以从以下方向参与：

- 改善对更多 LLM Provider 的兼容性
- 优化小 context 模型（DeepSeek 等）的工具调用体验
- 完善中文文档和使用指南
- 新增实用工具和插件
- 修复 Bug 和改善稳定性

欢迎在 [Issues](https://github.com/JiekerTime/ruoyi-code/issues) 中提出建议或反馈问题。

## 开源协议

MIT License
