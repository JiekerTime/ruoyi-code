#!/usr/bin/env bash
# Ruoyi Code 卸载脚本
#
# 用法:
#   ./uninstall.sh              # 卸载 ruoyi-cli 二进制和 symlink
#   ./uninstall.sh --all        # 同时清理编译产物和 Rust 工具链
#   ./uninstall.sh --help       # 显示帮助

set -euo pipefail

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_RESET="$(tput sgr0)"; C_BOLD="$(tput bold)"; C_RED="$(tput setaf 1)"
    C_GREEN="$(tput setaf 2)"; C_YELLOW="$(tput setaf 3)"; C_CYAN="$(tput setaf 6)"
else
    C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

ok()   { printf '%s  ✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$1"; }
warn() { printf '%s  ⚠%s %s\n' "${C_YELLOW}" "${C_RESET}" "$1"; }
info() { printf '%s  →%s %s\n' "${C_CYAN}" "${C_RESET}" "$1"; }

CLEAN_ALL=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --all) CLEAN_ALL=1 ;;
        -h|--help)
            cat <<'EOF'
用法: ./uninstall.sh [选项]

选项:
  --all     同时清理编译产物 (rust/target/) 和卸载 Rust 工具链
  -h        显示帮助
EOF
            exit 0
            ;;
        *) echo "未知参数: $1"; exit 2 ;;
    esac
    shift
done

printf '%s卸载 Ruoyi Code...%s\n\n' "${C_BOLD}" "${C_RESET}"

# 1. 移除 symlink / 二进制
REMOVED=0
for BIN_PATH in "$HOME/.local/bin/ruoyi-cli" "/usr/local/bin/ruoyi-cli"; do
    if [ -f "${BIN_PATH}" ] || [ -L "${BIN_PATH}" ]; then
        rm -f "${BIN_PATH}" 2>/dev/null && ok "已移除 ${BIN_PATH}" || warn "无法移除 ${BIN_PATH}，请手动执行: sudo rm ${BIN_PATH}"
        REMOVED=1
    fi
done

if [ "${REMOVED}" -eq 0 ]; then
    info "未找到已安装的 ruoyi-cli 二进制"
fi

# 2. 清理编译产物
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${SCRIPT_DIR}/rust/target"

if [ "${CLEAN_ALL}" -eq 1 ]; then
    if [ -d "${TARGET_DIR}" ]; then
        rm -rf "${TARGET_DIR}"
        ok "已清理编译产物 ${TARGET_DIR}"
    else
        info "编译产物目录不存在，跳过"
    fi
fi

# 3. 卸载 Rust（仅 --all 模式）
if [ "${CLEAN_ALL}" -eq 1 ]; then
    if command -v rustup >/dev/null 2>&1; then
        printf '\n%s是否卸载 Rust 工具链？(y/N): %s' "${C_YELLOW}" "${C_RESET}"
        read -r answer
        if [ "${answer}" = "y" ] || [ "${answer}" = "Y" ]; then
            rustup self uninstall -y
            ok "Rust 工具链已卸载"
        else
            info "保留 Rust 工具链"
        fi
    else
        info "未检测到 Rust 工具链"
    fi
fi

# 4. 清理 shell rc 中的 PATH 条目
for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "${RC_FILE}" ] && grep -q "Added by Ruoyi Code installer" "${RC_FILE}" 2>/dev/null; then
        sed -i '' '/# Added by Ruoyi Code installer/d; /ruoyi/d' "${RC_FILE}" 2>/dev/null || \
        sed -i '/# Added by Ruoyi Code installer/d; /ruoyi/d' "${RC_FILE}" 2>/dev/null
        ok "已清理 ${RC_FILE} 中的 PATH 配置"
    fi
done

printf '\n%s卸载完成。%s\n' "${C_GREEN}" "${C_RESET}"
