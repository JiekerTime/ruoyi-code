#!/usr/bin/env bash
# Ruoyi Code 安装脚本
#
# 自动检测系统环境，安装 Rust 工具链（如缺失），编译 ruoyi-cli 二进制，
# 并安装到 PATH。支持 Linux、macOS 和 WSL。
#
# 用法:
#   ./install.sh                # 调试构建（快速，默认）
#   ./install.sh --release      # 优化发布构建
#   ./install.sh --no-verify    # 跳过安装后验证
#   ./install.sh --help         # 显示帮助

set -euo pipefail

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_RESET="$(tput sgr0)"; C_BOLD="$(tput bold)"; C_DIM="$(tput dim)"
    C_RED="$(tput setaf 1)"; C_GREEN="$(tput setaf 2)"; C_YELLOW="$(tput setaf 3)"
    C_BLUE="$(tput setaf 4)"; C_CYAN="$(tput setaf 6)"
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""
    C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

CURRENT_STEP=0
TOTAL_STEPS=6

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    printf '\n%s[%d/%d]%s %s%s%s\n' \
        "${C_BLUE}" "${CURRENT_STEP}" "${TOTAL_STEPS}" "${C_RESET}" \
        "${C_BOLD}" "$1" "${C_RESET}"
}

info()  { printf '%s  →%s %s\n' "${C_CYAN}" "${C_RESET}" "$1"; }
ok()    { printf '%s  ✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$1"; }
warn()  { printf '%s  ⚠%s %s\n' "${C_YELLOW}" "${C_RESET}" "$1"; }
error() { printf '%s  ✗%s %s\n' "${C_RED}" "${C_RESET}" "$1" 1>&2; }

print_banner() {
    printf '%s' "${C_BOLD}"
    cat <<'EOF'
    / \__
   (    @\___    RUOYI
   /         O
  /   (_____/
 /_____/   U
EOF
    printf '%s\n' "${C_RESET}"
    printf '%s让每个人都能用上 AI 编码%s\n' "${C_DIM}" "${C_RESET}"
}

print_usage() {
    cat <<'EOF'
用法: ./install.sh [选项]

选项:
  --release       构建优化版本（更慢，但二进制更小）
  --debug         构建调试版本（默认，编译更快）
  --no-verify     跳过安装后验证
  -h, --help      显示帮助
EOF
}

BUILD_PROFILE="${RUOYI_BUILD_PROFILE:-debug}"
SKIP_VERIFY="${RUOYI_SKIP_VERIFY:-0}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --release) BUILD_PROFILE="release" ;;
        --debug)   BUILD_PROFILE="debug" ;;
        --no-verify) SKIP_VERIFY="1" ;;
        -h|--help) print_usage; exit 0 ;;
        *) error "未知参数: $1"; print_usage; exit 2 ;;
    esac
    shift
done

print_troubleshooting() {
    cat <<EOF

${C_BOLD}常见问题排查${C_RESET}

  ${C_BOLD}1. 缺少 Rust 工具链${C_RESET}
     手动安装: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
     然后执行: source "\$HOME/.cargo/env"

  ${C_BOLD}2. Linux 缺少系统包${C_RESET}
     Debian/Ubuntu: sudo apt-get install -y git pkg-config libssl-dev build-essential
     Fedora: sudo dnf install -y git pkgconf-pkg-config openssl-devel gcc

  ${C_BOLD}3. macOS 缺少 Xcode CLT${C_RESET}
     执行: xcode-select --install

  ${C_BOLD}4. 编译失败${C_RESET}
     尝试清理后重新编译: cd rust && cargo clean && cargo build --workspace

  ${C_BOLD}5. 卸载${C_RESET}
     执行: ./uninstall.sh        # 移除二进制
     执行: ./uninstall.sh --all  # 同时清理编译产物和 Rust 工具链

EOF
}

trap 'rc=$?; if [ "$rc" -ne 0 ]; then error "安装失败 (exit ${rc})"; print_troubleshooting; fi' EXIT

require_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---- Step 1: 检测系统环境 ----

print_banner
step "检测系统环境"

UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
UNAME_M="$(uname -m 2>/dev/null || echo unknown)"
OS_FAMILY="unknown"
IS_WSL="0"

case "${UNAME_S}" in
    Linux*)
        OS_FAMILY="linux"
        grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && IS_WSL="1"
        ;;
    Darwin*) OS_FAMILY="macos" ;;
    MINGW*|MSYS*|CYGWIN*) OS_FAMILY="windows-shell" ;;
esac

info "系统: ${UNAME_S} ${UNAME_M}"
[ "${IS_WSL}" = "1" ] && info "WSL 环境: 是"

case "${OS_FAMILY}" in
    linux|macos) ok "支持的平台" ;;
    windows-shell)
        error "检测到原生 Windows Shell (MSYS/Cygwin/MinGW)"
        error "请在 WSL 中运行此脚本，或使用 install.ps1"
        exit 1 ;;
    *)
        error "不支持的系统: ${UNAME_S}"
        exit 1 ;;
esac

# ---- Step 2: 定位 Rust 工作空间 ----

step "定位 Rust 工作空间"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="${SCRIPT_DIR}/rust"

if [ ! -f "${RUST_DIR}/Cargo.toml" ]; then
    error "未找到 ${RUST_DIR}/Cargo.toml"
    exit 1
fi
ok "工作空间: ${RUST_DIR}"

# ---- Step 3: 检查前置条件 ----

step "检查前置条件"

MISSING=0

if require_cmd rustc && require_cmd cargo; then
    ok "rustc: $(rustc --version 2>/dev/null)"
    ok "cargo: $(cargo --version 2>/dev/null)"
else
    info "未找到 Rust 工具链，正在自动安装..."
    if require_cmd curl; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck source=/dev/null
        . "$HOME/.cargo/env"
        if require_cmd rustc && require_cmd cargo; then
            ok "Rust 安装成功: $(rustc --version 2>/dev/null)"
        else
            error "Rust 安装失败"; MISSING=1
        fi
    else
        error "未找到 curl，无法自动安装 Rust"
        error "请手动安装: https://rustup.rs"
        MISSING=1
    fi
fi

require_cmd git && ok "git: $(git --version 2>/dev/null)" || warn "未找到 git，部分功能可能受限"

if [ "${OS_FAMILY}" = "linux" ]; then
    require_cmd pkg-config && ok "pkg-config: 已安装" || warn "未找到 pkg-config，可能影响 OpenSSL 编译"
fi

[ "${MISSING}" -ne 0 ] && { error "缺少必要工具，请查看上方提示"; exit 1; }

# ---- Step 4: 编译 ----

step "编译 ruoyi-cli (${BUILD_PROFILE})"

CARGO_FLAGS=("build" "--workspace")
[ "${BUILD_PROFILE}" = "release" ] && CARGO_FLAGS+=("--release")

info "执行: cargo ${CARGO_FLAGS[*]}"
info "首次编译可能需要几分钟，请耐心等待..."

( cd "${RUST_DIR}"; CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-always}" cargo "${CARGO_FLAGS[@]}" )

RUOYI_BIN="${RUST_DIR}/target/${BUILD_PROFILE}/ruoyi-cli"

if [ ! -x "${RUOYI_BIN}" ]; then
    error "编译产物未找到: ${RUOYI_BIN}"
    exit 1
fi
ok "编译成功: ${RUOYI_BIN}"

# ---- Step 5: 验证 ----

step "验证安装"

if [ "${SKIP_VERIFY}" = "1" ]; then
    warn "已跳过验证"
else
    if VERSION_OUT="$("${RUOYI_BIN}" --version 2>&1)"; then
        ok "版本: ${VERSION_OUT}"
    else
        error "ruoyi-cli --version 失败"; exit 1
    fi
    if "${RUOYI_BIN}" --help >/dev/null 2>&1; then
        ok "ruoyi-cli --help 正常"
    else
        error "ruoyi-cli --help 失败"; exit 1
    fi
fi

# ---- Step 6: 安装到 PATH ----

step "安装到 PATH"

if [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
else
    mkdir -p "$HOME/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
fi

LINK_PATH="${INSTALL_DIR}/ruoyi-cli"

if ln -sf "${RUOYI_BIN}" "${LINK_PATH}" 2>/dev/null; then
    ok "创建链接: ${LINK_PATH} → ${RUOYI_BIN}"
elif cp "${RUOYI_BIN}" "${LINK_PATH}" 2>/dev/null; then
    ok "复制到: ${LINK_PATH}"
else
    warn "无法安装到 ${INSTALL_DIR}，请手动执行: sudo ln -sf ${RUOYI_BIN} /usr/local/bin/ruoyi-cli"
fi

case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
        info "添加 ${INSTALL_DIR} 到 PATH"
        for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
            if [ -f "${RC}" ] && ! grep -q "${INSTALL_DIR}" "${RC}" 2>/dev/null; then
                printf '\n# Added by Ruoyi Code installer\nexport PATH="%s:$PATH"\n' "${INSTALL_DIR}" >> "${RC}"
                ok "已更新 ${RC}"
            fi
        done
        export PATH="${INSTALL_DIR}:${PATH}"
        ;;
esac

if command -v ruoyi-cli >/dev/null 2>&1; then
    ok "ruoyi-cli 已可全局使用"
else
    warn "安装完成，请打开新终端或执行: source ~/.zshrc"
fi

# ---- 完成 ----

cat <<EOF

${C_GREEN}Ruoyi Code 安装完成！${C_RESET}

  ${C_BOLD}快速开始：${C_RESET}

  ${C_DIM}# 1. 全局配置 API Key（一次配置到处可用）：${C_RESET}
  mkdir -p ~/.ruoyi-cli && echo 'DEEPSEEK_API_KEY=sk-...' > ~/.ruoyi-cli/.env

  ${C_DIM}# 2. 启动交互式 REPL：${C_RESET}
  ruoyi-cli

  ${C_DIM}# 3. 或者单次提问：${C_RESET}
  ruoyi-cli prompt "总结这个仓库"

  ${C_DIM}# 卸载：${C_RESET}
  ./uninstall.sh

EOF

trap - EXIT
