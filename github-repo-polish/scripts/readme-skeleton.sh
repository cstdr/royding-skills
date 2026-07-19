#!/usr/bin/env bash
# readme-skeleton.sh — 阶段 4 的 README 必备 7 段检查
# 跑法: bash readme-skeleton.sh [path-to-readme]
# 默认检查 README.md
set -uo pipefail

README="${1:-README.md}"

echo "📋 GitHub Repo Polish - README 必备段检查"
echo "=========================================="
echo "📄 目标: $README"
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

if [ ! -f "$README" ]; then
    fail "找不到 $README"
    echo "  修复:在仓库根目录创建 README.md"
    exit 1
fi

HITS=0
WARNINGS=0

# 读取 README 内容
CONTENT=$(cat "$README")
TOTAL_LINES=$(wc -l < "$README")
echo "📏 行数: $TOTAL_LINES"

# 评价
if [ "$TOTAL_LINES" -lt 30 ]; then
    fail "README 太短(< 30 行),专业感不足"
elif [ "$TOTAL_LINES" -lt 80 ]; then
    warn "README < 80 行,内容偏少"
elif [ "$TOTAL_LINES" -lt 300 ]; then
    pass "README 长度合理"
else
    info "README > 300 行,考虑分页(用 docs/ 子目录)"
fi

# ========== 7 段必备 ==========
echo ""
echo "--- 7 段必备检查 ---"

# 1. 标题(第一个 #)
echo ""
echo "[1/7] 标题"
FIRST_HEADING=$(echo "$CONTENT" | grep -m 1 "^# " | sed 's/^# //')
if [ -n "$FIRST_HEADING" ]; then
    pass "标题: $FIRST_HEADING"
else
    fail "没有 H1 标题"
    HITS=$((HITS + 1))
fi

# 2. 一句话价值主张(在标题下方一段)
echo ""
echo "[2/7] 一句话价值主张"
# 看标题下面 5 行内有没有"做什么"的相关描述
HAS_VALUE=$(echo "$CONTENT" | head -10 | grep -iE "(why|what|解决|做|tool|library|cli|app|framework)" | head -1)
if [ -n "$HAS_VALUE" ]; then
    pass "有'这是什么'的描述"
else
    warn "标题下面没有'这是什么'的描述,visitor 不知道你做什么"
    WARNINGS=$((WARNINGS + 1))
fi

# 3. Badges
echo ""
echo "[3/7] Badges"
BADGE_COUNT=$(echo "$CONTENT" | head -30 | grep -cE "(img\.shields\.io|\!\[.*\]\(.*badge)" || true)
if [ "$BADGE_COUNT" -ge 3 ]; then
    pass "$BADGE_COUNT 个 badge(sufficient)"
elif [ "$BADGE_COUNT" -ge 1 ]; then
    info "$BADGE_COUNT 个 badge,可加到 3-5 个(license, CI, stars, version)"
else
    warn "没有 badge,显得'没有维护'"
    WARNINGS=$((WARNINGS + 1))
fi

# 4. Demo(图或 GIF)
echo ""
echo "[4/7] Demo 图"
HAS_IMAGE=$(echo "$CONTENT" | head -40 | grep -ciE "!\[[^]]*\]\([^)]*\.(png|jpg|gif|webp)|<img[^>]+src=[^>]*\.(png|jpg|gif|webp)" || true)
if [ "$HAS_IMAGE" -ge 1 ]; then
    pass "有 demo 图/GIF"
else
    fail "头部 40 行内没有 demo 图,3 秒抓不住人"
    HITS=$((HITS + 1))
fi

# 5. Features
echo ""
echo "[5/7] Features 段"
HAS_FEATURES=$(echo "$CONTENT" | grep -E "^##" | grep -iE "✨|🌟|⭐|[Ff]eatures|功能|特性" | head -1)
if [ -n "$HAS_FEATURES" ]; then
    pass "Features 段: $HAS_FEATURES"
else
    fail "没有 Features 段(## Features)"
    HITS=$((HITS + 1))
fi

# Features 内的列表项数
if [ -n "$HAS_FEATURES" ]; then
    FEATURES_LINE=$(echo "$CONTENT" | grep -nE "^##" | grep -E "✨|🌟|⭐|[Ff]eatures|功能|特性" | head -1 | cut -d: -f1)
    FEATURE_COUNT=$(echo "$CONTENT" | awk -v start="$FEATURES_LINE" 'NR > start && /^## / {exit} NR > start && /^[[:space:]]*[-*]/ {n++} END{print n+0}')
    if [ "$FEATURE_COUNT" -ge 4 ] && [ "$FEATURE_COUNT" -le 8 ]; then
        pass "Features 列表: $FEATURE_COUNT 条(合理)"
    elif [ "$FEATURE_COUNT" -lt 4 ]; then
        warn "Features 列表只有 $FEATURE_COUNT 条(< 4),显得空"
        WARNINGS=$((WARNINGS + 1))
    else
        info "Features 列表 $FEATURE_COUNT 条(> 8),可能太长,挑重点"
    fi
fi

# 6. Quick Start / Installation
echo ""
echo "[6/7] Quick Start / Installation"
HAS_INSTALL=$(echo "$CONTENT" | grep -E "^##" | grep -iE "🚀|⚡|[Ii]nstall|[Uu]sage|[Qq]uick [Ss]tart|getting started|上手|安装|快速开始" | head -1)
if [ -n "$HAS_INSTALL" ]; then
    pass "安装/使用段: $HAS_INSTALL"
    # 看是否有可复制的命令
    CODE_BLOCK=$(echo "$CONTENT" | awk '/^```/{c=!c; next} c' | head -50)
    if echo "$CODE_BLOCK" | grep -qE "(npm|pip|cargo|brew|go install|apt install|git clone|docker run)"; then
        pass "有可复制的安装命令"
    else
        warn "没有常见的安装命令(npm / pip / cargo / brew 等)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    fail "没有 Install / Quick Start 段"
    HITS=$((HITS + 1))
fi

# 7. License
echo ""
echo "[7/7] License 段"
HAS_LICENSE=$(echo "$CONTENT" | grep -E "^##" | grep -iE "📄|📜|[Ll]icense|许可证|许可" | head -1)
if [ -n "$HAS_LICENSE" ]; then
    pass "License 段: $HAS_LICENSE"
else
    fail "没有 License 段(## License)"
    HITS=$((HITS + 1))
fi

# 看 LICENSE 文件是否存在
if [ -f LICENSE ] || [ -f LICENSE.md ] || [ -f LICENSE.txt ]; then
    pass "LICENSE 文件存在"
else
    warn "LICENSE 文件不存在(只有 README 提到还不够)"
    WARNINGS=$((WARNINGS + 1))
fi

# ========== 加分项 ==========
echo ""
echo "--- 加分项(可选)---"

# 活人感:Why this exists
echo ""
echo "[+] Why this exists(活人感关键)"
HAS_WHY=$(echo "$CONTENT" | grep -E "^##" | grep -iE "[Ww]hy\s+(I\s+built|this|exist|did)|[Mm]otivation|[Bb]ackground|背景|缘起" | head -1)
if [ -n "$HAS_WHY" ]; then
    pass "Why 段: $HAS_WHY"
else
    warn "没有 'Why I built this' 段,缺活人感"
    WARNINGS=$((WARNINGS + 1))
fi

# 活人感:第一人称
FIRST_PERSON=$(echo "$CONTENT" | grep -cE "(\b我\b|\bI (built|wrote|made|created|use|was)\b|\b我自己\b|\bmy (own|project|day)\b)" || true)
if [ "$FIRST_PERSON" -ge 1 ]; then
    pass "有第一人称内容($FIRST_PERSON 处)"
else
    warn "完全没有第一人称,看起来像 AI 生成"
    WARNINGS=$((WARNINGS + 1))
fi

# AI 套话检测
echo ""
echo "[+] AI 套话检测"
BUZZWORDS=$(echo "$CONTENT" | grep -ciE "(blazing.fast|blazing-fast|modern solution|next.generation|seamless experience|cutting.edge|type.safe|lightning.fast|state.of.the.art|empower|revolutionize|unleash|effortless)" || true)
if [ "$BUZZWORDS" -ge 1 ]; then
    fail "检测到 $BUZZWORDS 处 AI 套话(blazing-fast / type-safe / seamless / cutting-edge 等)"
    HITS=$((HITS + 1))
else
    pass "无 AI 套话"
fi

# Tech Stack
HAS_TECH=$(echo "$CONTENT" | grep -iE "^##\s*(tech|stack|built with|技术栈|技术)" | head -1)
if [ -n "$HAS_TECH" ]; then
    pass "Tech Stack 段: $HAS_TECH"
else
    info "没有 Tech Stack 段(可加)"
fi

# Contributing
HAS_CONTRIB=$(echo "$CONTENT" | grep -iE "^##\s*(contribut|贡献)" | head -1)
if [ -n "$HAS_CONTRIB" ]; then
    pass "Contributing 段: $HAS_CONTRIB"
else
    info "没有 Contributing 段(可加)"
fi

# Roadmap
HAS_ROADMAP=$(echo "$CONTENT" | grep -iE "^##\s*(roadmap|todo|计划|路线图|🛣)" | head -1)
if [ -n "$HAS_ROADMAP" ]; then
    pass "Roadmap 段: $HAS_ROADMAP"
else
    info "没有 Roadmap 段(可加)"
fi

# ========== 总结 ==========
echo ""
echo "=========================================="
SCORE=0
[ "$TOTAL_LINES" -ge 80 ] && [ "$TOTAL_LINES" -le 400 ] && SCORE=$((SCORE + 5))
if [ "$HITS" -eq 0 ]; then SCORE=$((SCORE + 35)); fi
[ "$BADGE_COUNT" -ge 3 ] && SCORE=$((SCORE + 10))
[ "$HAS_IMAGE" -ge 1 ] && SCORE=$((SCORE + 15))
[ -n "$HAS_FEATURES" ] && SCORE=$((SCORE + 10))
[ -n "$HAS_INSTALL" ] && SCORE=$((SCORE + 10))
[ -n "$HAS_LICENSE" ] && SCORE=$((SCORE + 5))
[ -n "$HAS_WHY" ] && SCORE=$((SCORE + 5))
[ "$FIRST_PERSON" -ge 1 ] && SCORE=$((SCORE + 5))

if [ "$SCORE" -ge 90 ]; then
    echo -e "${GREEN}🎉 README 评分: $SCORE/100 — 优秀${NC}"
elif [ "$SCORE" -ge 70 ]; then
    echo -e "${GREEN}📈 README 评分: $SCORE/100 — 良好${NC}"
elif [ "$SCORE" -ge 50 ]; then
    echo -e "${YELLOW}📊 README 评分: $SCORE/100 — 及格,需要打磨${NC}"
else
    echo -e "${RED}⚠️  README 评分: $SCORE/100 — 不及格${NC}"
fi

echo ""
echo "❌ 错误: $HITS 个"
echo "⚠️  警告: $WARNINGS 个"

if [ $HITS -gt 0 ]; then
    echo ""
    echo "下一步:"
    echo "  1. 解决上面的 ❌ 错误(7 段必备)"
    echo "  2. 详见 references/04-readme-architecture.md"
    exit 1
fi
