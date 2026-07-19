#!/usr/bin/env bash
# pre-publish-check.sh — 阶段 8 发布前综合检查
# 跑法: bash pre-publish-check.sh [path-to-repo]
set -uo pipefail

REPO_PATH="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$REPO_PATH" || { echo "❌ 路径不存在: $REPO_PATH"; exit 1; }

echo "🚀 GitHub Repo Polish - 发布前综合检查"
echo "=========================================="
echo "📁 目标: $(pwd)"
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

TOTAL_SCORE=0
MAX_SCORE=0

# ========== 1. 隐私扫描 ==========
echo "--- [1/8] 隐私扫描 ---"
echo ""

if [ -x "$SCRIPT_DIR/privacy-scan.sh" ]; then
    if bash "$SCRIPT_DIR/privacy-scan.sh" "$REPO_PATH" 2>&1 | tail -20; then
        pass "隐私扫描通过"
        TOTAL_SCORE=$((TOTAL_SCORE + 15))
    else
        fail "隐私扫描未通过,见上面详情"
    fi
    MAX_SCORE=$((MAX_SCORE + 15))
else
    warn "privacy-scan.sh 不存在,跳过"
fi

# ========== 2. 仓库基础结构 ==========
echo ""
echo "--- [2/8] 仓库基础结构 ---"

# README
if [ -f README.md ]; then
    pass "README.md 存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
else
    fail "README.md 不存在"
fi
MAX_SCORE=$((MAX_SCORE + 5))

# LICENSE
if [ -f LICENSE ] || [ -f LICENSE.md ] || [ -f LICENSE.txt ]; then
    pass "LICENSE 存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
else
    fail "LICENSE 不存在"
fi
MAX_SCORE=$((MAX_SCORE + 5))

# .gitignore
if [ -f .gitignore ]; then
    pass ".gitignore 存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 3))
else
    fail ".gitignore 不存在"
fi
MAX_SCORE=$((MAX_SCORE + 3))

# CHANGELOG
if [ -f CHANGELOG.md ]; then
    pass "CHANGELOG.md 存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
else
    info "CHANGELOG.md 不存在(可选)"
fi
MAX_SCORE=$((MAX_SCORE + 2))

# ========== 3. .github/ 工程化 ==========
echo ""
echo "--- [3/8] .github/ 工程化 ---"

if [ -d .github ]; then
    pass ".github/ 目录存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 3))
else
    fail ".github/ 目录不存在"
fi
MAX_SCORE=$((MAX_SCORE + 3))

# Issue 模板
ISSUE_TPL_COUNT=$(find .github/ISSUE_TEMPLATE -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ISSUE_TPL_COUNT" -ge 2 ]; then
    pass "$ISSUE_TPL_COUNT 个 Issue 模板(≥ 2)"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
elif [ "$ISSUE_TPL_COUNT" -ge 1 ]; then
    warn "只有 $ISSUE_TPL_COUNT 个 Issue 模板(建议 ≥ 2: bug + feature)"
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
else
    fail "没有 Issue 模板"
fi
MAX_SCORE=$((MAX_SCORE + 5))

# PR 模板
if [ -f .github/PULL_REQUEST_TEMPLATE.md ]; then
    pass "PR 模板存在"
    TOTAL_SCORE=$((TOTAL_SCORE + 3))
else
    fail "PR 模板不存在"
fi
MAX_SCORE=$((MAX_SCORE + 3))

# CI workflow
WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
if [ "$WORKFLOW_COUNT" -ge 1 ]; then
    pass "$WORKFLOW_COUNT 个 GitHub Actions workflow"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
else
    fail "没有 GitHub Actions workflow"
fi
MAX_SCORE=$((MAX_SCORE + 5))

# CI badge 在 README
if [ -f README.md ] && head -30 README.md | grep -qE "github\.com/.*/actions/workflow"; then
    pass "README 引用了 CI badge"
    TOTAL_SCORE=$((TOTAL_SCORE + 3))
else
    warn "README 没引用 CI badge"
fi
MAX_SCORE=$((MAX_SCORE + 3))

# Dependabot
if [ -f .github/dependabot.yml ]; then
    pass "Dependabot 已配置"
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
else
    info "Dependabot 未配置(可选)"
fi
MAX_SCORE=$((MAX_SCORE + 2))

# ========== 4. README 必备 7 段 ==========
echo ""
echo "--- [4/8] README 必备 7 段 ---"

if [ -x "$SCRIPT_DIR/readme-skeleton.sh" ]; then
    bash "$SCRIPT_DIR/readme-skeleton.sh" README.md 2>&1 | tail -10
else
    warn "readme-skeleton.sh 不存在,跳过"
fi

# 简易评分
if [ -f README.md ]; then
    if grep -qE "^# " README.md && grep -E "^##" README.md | grep -qE "✨|🌟|⭐|[Ff]eatures|功能" && grep -E "^##" README.md | grep -qE "🚀|⚡|[Ii]nstall|[Uu]sage|[Qq]uick [Ss]tart|上手|安装" && grep -E "^##" README.md | grep -qE "📄|📜|[Ll]icense|许可"; then
        pass "README 7 段必备齐"
        TOTAL_SCORE=$((TOTAL_SCORE + 10))
    else
        fail "README 7 段必备不齐全"
    fi
fi
MAX_SCORE=$((MAX_SCORE + 10))

# ========== 5. commit 质量 ==========
echo ""
echo "--- [5/8] Commit 质量 ---"

if [ -x "$SCRIPT_DIR/commit-stats.sh" ]; then
    bash "$SCRIPT_DIR/commit-stats.sh" 50 2>&1 | tail -10
else
    warn "commit-stats.sh 不存在,跳过"
fi

TOTAL_COMMIT=$(git rev-list --count HEAD 2>/dev/null || echo 0)
if [ "$TOTAL_COMMIT" -gt 0 ]; then
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
fi
MAX_SCORE=$((MAX_SCORE + 5))

# ========== 6. 活人感信号 ==========
echo ""
echo "--- [6/8] 活人感信号 ---"

if [ -f README.md ]; then
    # 第一人称
    FIRST_PERSON=$(grep -E "(\b我\b|\bI (built|wrote|made|created|use|was)\b|\b我自己\b|\bmy (own|project|day)\b)" README.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$FIRST_PERSON" -ge 1 ]; then
        pass "README 有第一人称内容($FIRST_PERSON 处)"
        TOTAL_SCORE=$((TOTAL_SCORE + 4))
    else
        fail "README 没第一人称内容,看着像 AI 模板"
    fi

    # Why 段(宽松匹配:忽略 ## 后的 emoji 和加粗标记)
    if grep -E "^##" README.md 2>/dev/null | grep -qiE "[Ww]hy\s+(I\s+built|this|exist|did)|[Mm]otivation|[Bb]ackground|背景"; then
        pass "README 有 'Why I built this' 段"
        TOTAL_SCORE=$((TOTAL_SCORE + 4))
    else
        warn "README 没有 'Why I built this' 段,缺活人感"
    fi

    # AI 套话
    BUZZWORDS=$(grep -iE "(blazing.fast|cutting.edge|seamless experience|state.of.the.art|empower|revolutionize)" README.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BUZZWORDS" -eq 0 ]; then
        pass "无 AI 套话"
        TOTAL_SCORE=$((TOTAL_SCORE + 3))
    else
        fail "检测到 $BUZZWORDS 处 AI 套话"
    fi
fi
MAX_SCORE=$((MAX_SCORE + 11))

# ========== 7. 远程仓库配置 ==========
echo ""
echo "--- [7/8] 远程仓库配置 ---"

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$REMOTE_URL" ]; then
    pass "远程仓库: $REMOTE_URL"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))

    # 是否是 SSH 或 HTTPS
    if echo "$REMOTE_URL" | grep -qE "github\.com[:/]"; then
        pass "远程是 GitHub"
    else
        warn "远程不是 GitHub($REMOTE_URL)"
    fi
else
    fail "没有配置远程仓库"
fi
MAX_SCORE=$((MAX_SCORE + 5))

# 默认分支
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "")
if [ -n "$DEFAULT_BRANCH" ]; then
    pass "默认分支: $DEFAULT_BRANCH"
else
    info "默认分支未设置(推送后会默认 main/master)"
fi

# ========== 8. 演示资产 ==========
echo ""
echo "--- [8/8] 演示资产 ---"

if [ -d docs ]; then
    DEMO_COUNT=$(find docs -type f \( -name "*.gif" -o -name "*.png" -o -name "*.jpg" -o -name "*.webp" -o -name "*.svg" \) 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DEMO_COUNT" -ge 1 ]; then
        pass "docs/ 有 $DEMO_COUNT 个演示图"
        TOTAL_SCORE=$((TOTAL_SCORE + 3))
    else
        info "docs/ 目录存在但没有演示图"
    fi
else
    info "没有 docs/ 目录"
fi

# README 头部有图
if [ -f README.md ]; then
    HEAD_IMG=$(head -40 README.md | grep -ciE "!\[[^]]*\]\([^)]*\.(png|jpg|gif|webp)|<img[^>]+src=[^>]*\.(png|jpg|gif|webp)" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$HEAD_IMG" -ge 1 ]; then
        pass "README 头部有 demo 图($HEAD_IMG 张)"
        TOTAL_SCORE=$((TOTAL_SCORE + 3))
    else
        fail "README 头部没有 demo 图,3 秒抓不住人"
    fi
fi
MAX_SCORE=$((MAX_SCORE + 6))

# ========== 总分 ==========
echo ""
echo "=========================================="
PERCENT=$((TOTAL_SCORE * 100 / MAX_SCORE))
echo "📊 总分: $TOTAL_SCORE / $MAX_SCORE = ${PERCENT}%"
echo ""

if [ "$PERCENT" -ge 90 ]; then
    echo -e "${GREEN}🎉 优秀!可以发布了。${NC}"
    exit 0
elif [ "$PERCENT" -ge 70 ]; then
    echo -e "${GREEN}📈 良好,还有优化空间,看上面警告。${NC}"
    exit 0
elif [ "$PERCENT" -ge 50 ]; then
    echo -e "${YELLOW}📊 及格,但需要打磨关键项。${NC}"
    exit 1
else
    echo -e "${RED}⚠️  不及格,回去跑完整 9 阶段流程。${NC}"
    exit 2
fi
