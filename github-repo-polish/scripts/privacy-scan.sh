#!/usr/bin/env bash
# privacy-scan.sh — 阶段 1 的隐私扫描脚本
# 跑法: bash privacy-scan.sh [path-to-repo]
# 默认扫当前目录
set -uo pipefail

REPO_PATH="${1:-.}"
cd "$REPO_PATH" || { echo "❌ 路径不存在: $REPO_PATH"; exit 1; }

echo "🔍 GitHub Repo Polish - 隐私扫描"
echo "================================="
echo "📁 目标: $(pwd)"
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; HITS=$((HITS + 1)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

HITS=0

# ========== Step 1: 检测常见误提交文件 ==========
echo "--- Step 1: 检测常见误提交文件 ---"

# 已 tracked 的敏感文件
SENSITIVE_FILES=(
    '\.env$'
    '\.env\.local$'
    '\.env\.production$'
    '\.env\.development$'
    '\.env\.test$'
    'secrets\.(yaml|yml|json|toml)$'
    '\.aws/credentials$'
    '\.ssh/id_(rsa|ed25519|dsa|ecdsa)$'
    '.*\.pem$'
    '.*\.key$'
    '.*\.p12$'
    '.*\.pfx$'
    'credentials\.json$'
    'service-account.*\.json$'
    '.*-credentials\.json$'
)

for pattern in "${SENSITIVE_FILES[@]}"; do
    hits=$(git ls-files 2>/dev/null | grep -E "$pattern" || true)
    if [ -n "$hits" ]; then
        fail "敏感文件被 tracked: $hits"
        echo "    修复: git rm --cached <file>"
    fi
done

# 检查 .gitignore
if [ -f .gitignore ]; then
    pass ".gitignore 存在"
    # .env 是否在 .gitignore
    if grep -qE '^\.env' .gitignore; then
        pass ".env 在 .gitignore 中"
    else
        fail ".env 不在 .gitignore 中"
    fi
    if grep -qE '\*\.key|\*\.pem' .gitignore; then
        pass "密钥文件在 .gitignore 中"
    else
        warn "密钥文件 (*.key, *.pem) 不在 .gitignore 中"
    fi
else
    fail ".gitignore 不存在"
fi

# ========== Step 2: gitleaks 扫描(如果可用) ==========
echo ""
echo "--- Step 2: gitleaks 扫描 ---"

if command -v gitleaks >/dev/null 2>&1; then
    info "gitleaks 已安装,跑全扫描"

    # 当前 working tree
    if gitleaks detect --source . --no-banner --quiet 2>/dev/null; then
        pass "working tree 无密钥命中"
    else
        fail "working tree 有密钥命中,跑 gitleaks detect --source . 看详情"
    fi

    # 全历史
    if gitleaks detect --source . --log-opts="--all" --no-banner --quiet 2>/dev/null; then
        pass "git history 无密钥命中"
    else
        fail "git history 有密钥命中,跑 gitleaks detect --source . --log-opts=\"--all\" 看详情"
    fi
else
    warn "gitleaks 未安装,跳过"
    info "安装: brew install gitleaks / apt install gitleaks"
fi

# ========== Step 3: trufflehog 扫描(如果可用) ==========
echo ""
echo "--- Step 3: trufflehog 扫描 ---"

if command -v trufflehog >/dev/null 2>&1; then
    info "trufflehog 已安装,跑全扫描"
    if trufflehog git file://"$(pwd)" --quiet --no-update 2>/dev/null; then
        pass "trufflehog 无密钥命中"
    else
        warn "trufflehog 有命中,跑 trufflehog git file://. 看详情"
    fi
else
    warn "trufflehog 未安装(可选)"
    info "安装: brew install trufflehog"
fi

# ========== Step 4: 人工兜底 grep ==========
echo ""
echo "--- Step 4: 人工兜底 grep ---"

if command -v rg >/dev/null 2>&1; then
    info "ripgrep 已安装,跑强匹配"

    # 私钥头
    if rg -q "BEGIN.*PRIVATE KEY" -g '!*.md' --type-not text 2>/dev/null; then
        fail "检测到 PRIVATE KEY 头"
    else
        pass "无 PRIVATE KEY"
    fi

    # 强 token
    if rg -q "ghp_[0-9a-zA-Z]{36}" -g '!*.md' 2>/dev/null; then
        fail "检测到 GitHub PAT (ghp_*)"
    fi
    if rg -q "AKIA[0-9A-Z]{16}" -g '!*.md' 2>/dev/null; then
        fail "检测到 AWS Access Key (AKIA*)"
    fi
    if rg -q "sk-[0-9a-zA-Z]{48}" -g '!*.md' 2>/dev/null; then
        fail "检测到 OpenAI API Key (sk-*)"
    fi
    if rg -q "xox[baprs]-[0-9a-zA-Z]{10,}" -g '!*.md' 2>/dev/null; then
        fail "检测到 Slack Token"
    fi
else
    warn "ripgrep 未安装,跳过强匹配"
    info "安装: brew install ripgrep"
fi

# ========== Step 5: 公司邮箱检测 ==========
echo ""
echo "--- Step 5: 公司邮箱检测 ---"

# 常见公司域名(用户可以扩展)
COMPANY_DOMAINS=(
    "@bytedance.com"
    "@alibaba-inc.com"
    "@tencent.com"
    "@baidu.com"
    "@jd.com"
    "@meituan.com"
    "@xiaomi.com"
    "@huawei.com"
    "@microsoft.com"
    "@google.com"
    "@amazon.com"
    "@apple.com"
)

if command -v rg >/dev/null 2>&1; then
    hits=0
    for domain in "${COMPANY_DOMAINS[@]}"; do
        if rg -q "$domain" -g '!*.md' -g '!.git/*' 2>/dev/null; then
            fail "检测到公司邮箱 $domain"
            hits=$((hits + 1))
        fi
    done
    if [ $hits -eq 0 ]; then
        pass "未检测到公司邮箱"
    fi
else
    warn "ripgrep 未安装,跳过公司邮箱检测"
fi

# ========== Step 6: 大文件检测 ==========
echo ""
echo "--- Step 6: 大文件检测 ---"

LARGE_FILES=$(git ls-files 2>/dev/null | xargs -I {} ls -la {} 2>/dev/null | awk '$5 > 1048576 { print $5, $9 }' | sort -rn | head -5)

if [ -n "$LARGE_FILES" ]; then
    warn "大文件 (>1MB) 存在,考虑加进 .gitignore 或用 git-lfs:"
    echo "$LARGE_FILES" | awk '{ printf "    %.2f MB  %s\n", $1/1048576, $2 }'
else
    pass "无大文件"
fi

# ========== 总结 ==========
echo ""
echo "================================="
if [ $HITS -eq 0 ]; then
    echo -e "${GREEN}✅ 隐私扫描通过,0 命中${NC}"
    exit 0
else
    echo -e "${RED}❌ 发现 $HITS 个问题${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 上面列出的文件加进 .gitignore"
    echo "  2. 已经被 tracked 的文件: git rm --cached <file>"
    echo "  3. 命中密钥:先轮换密钥,再 git filter-repo 清理历史"
    echo "  4. 详见 references/01-privacy-audit.md"
    exit 1
fi
