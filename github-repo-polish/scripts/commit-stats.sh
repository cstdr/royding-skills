#!/usr/bin/env bash
# commit-stats.sh — 阶段 3 的 commit 质量统计
# 跑法: bash commit-stats.sh [N=100]
# 看最近 N 个 commit 的质量
set -uo pipefail

N="${1:-100}"

echo "📊 GitHub Repo Polish - Commit 质量统计"
echo "========================================="
echo "📁 目标: $(pwd)"
echo "📊 范围: 最近 $N 个 commit"
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

# ========== 1. 总数 ==========
echo "--- 总量 ---"
TOTAL=$(git rev-list --count HEAD)
echo "总 commit 数: $TOTAL"

if [ "$TOTAL" -gt 500 ]; then
    warn "commit 数 > 500,考虑 squash 历史(只在 launch 阶段)"
fi

# ========== 2. 平均长度 ==========
echo ""
echo "--- Commit 信息平均长度 ---"
AVG_LEN=$(git log -n "$N" --pretty=format:'%s' 2>/dev/null | awk '{ print length }' | awk '{ s += $1; n++ } END { if (n>0) printf "%.1f", s/n; else print 0 }')
echo "平均主题行长度: $AVG_LEN 字符"

# 评价
if [ "${AVG_LEN%.*}" -lt 20 ]; then
    fail "平均长度 < 20,commit 信息太短,讲不清'为什么'"
elif [ "${AVG_LEN%.*}" -lt 30 ]; then
    warn "平均长度 < 30,建议加长到 30-50 字符讲清'做了什么 + 为什么'"
elif [ "${AVG_LEN%.*}" -lt 60 ]; then
    pass "平均长度 $AVG_LEN,符合 conventional commits 推荐"
else
    info "平均长度 $AVG_LEN,可能偏长(主题行建议 < 72)"
fi

# ========== 3. Conventional 比例 ==========
echo ""
echo "--- Conventional Commits 比例 ---"

# 提取第一行的第一个 word(type)
TYPES=$(git log -n "$N" --pretty=format:'%s' 2>/dev/null | awk '{print $1}' | sed -E 's/[:(].*//' | tr -d '!')

CONV_TYPES="feat fix docs style refactor perf test build ci chore revert"

CONV_COUNT=0
TOTAL_COUNT=0
while IFS= read -r t; do
    [ -z "$t" ] && continue
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if echo "$CONV_TYPES" | grep -wq "$t"; then
        CONV_COUNT=$((CONV_COUNT + 1))
    fi
done <<< "$TYPES"

if [ "$TOTAL_COUNT" -gt 0 ]; then
    RATIO=$((CONV_COUNT * 100 / TOTAL_COUNT))
    echo "Conventional: $CONV_COUNT / $TOTAL_COUNT = ${RATIO}%"

    if [ "$RATIO" -ge 80 ]; then
        pass "Conventional 占比 ≥ 80%,很规范"
    elif [ "$RATIO" -ge 50 ]; then
        info "Conventional 占比 50-80%,建议加 commitlint 强制"
    else
        warn "Conventional 占比 < 50%,commit 不够规范"
    fi
else
    warn "没有 commit"
fi

# ========== 4. type 分布 ==========
echo ""
echo "--- type 分布 ---"
git log -n "$N" --pretty=format:'%s' 2>/dev/null \
    | awk '{print $1}' | sed -E 's/[:(].*//' | tr -d '!' \
    | sort | uniq -c | sort -rn | head -10 \
    | awk '{ printf "  %4d  %s\n", $1, $2 }'

# ========== 5. 烂 commit 检测 ==========
echo ""
echo "--- 烂 commit 检测 ---"

# 常见的烂 commit
BAD_PATTERNS=(
    "^fix$"
    "^update$"
    "^wip$"
    "^tmp$"
    "^asdf$"
    "^test$"
    "^\\.$"
    "^commit$"
    "^[0-9]+$"
)

BAD_HITS=0
for pattern in "${BAD_PATTERNS[@]}"; do
    cnt=$(git log -n "$N" --pretty=format:'%s' 2>/dev/null | grep -cE "$pattern" || true)
    if [ "$cnt" -gt 0 ]; then
        warn "发现 $cnt 个 '$pattern' 风格 commit"
        BAD_HITS=$((BAD_HITS + cnt))
    fi
done

if [ "$BAD_HITS" -eq 0 ]; then
    pass "无烂 commit"
else
    info "考虑用 git rebase -i 合并到相邻 commit,或写新 commit 时避免这些关键词"
fi

# ========== 6. 大 commit 检测(单 commit 改太多文件) ==========
echo ""
echo "--- 大 commit 检测(单 commit 改 > 20 文件) ---"

LARGE_COMMITS=$(git log -n "$N" --pretty=format:'%H %s' --name-only 2>/dev/null \
    | awk 'BEGIN{commit=""} 
           /^$/{ if(file_count>20 && commit!="") print file_count, commit; file_count=0; commit=""; next }
           /^[0-9a-f]{40} /{ commit=$0; file_count=0; next }
           { file_count++ }' | head -10)

if [ -n "$LARGE_COMMITS" ]; then
    warn "以下 commit 改了 > 20 文件,考虑 squash 或拆分:"
    echo "$LARGE_COMMITS" | awk '{ printf "  %4d 文件  %s\n", $1, substr($0, index($0, $2)) }'
else
    pass "无大 commit"
fi

# ========== 7. 活人感检测 ==========
echo ""
echo "--- 活人感信号 ---"

# 活人感关键词
HUMAN_KEYWORDS="wip|oops|typo|debug|hmm|actually|wait|todo|fixme|hack"

HUMAN_COUNT=$(git log -n "$N" --pretty=format:'%s' 2>/dev/null | grep -ciE "$HUMAN_KEYWORDS" || true)
echo "含活人感关键词的 commit: $HUMAN_COUNT / $N"

if [ "$HUMAN_COUNT" -eq 0 ] && [ "$TOTAL_COUNT" -gt 20 ]; then
    warn "完全没有活人感 commit,看着像 AI 模板"
    info "偶尔加一些 'wip' 'oops' 'fix typo' 类型的 commit 更真实"
elif [ "$HUMAN_COUNT" -gt 0 ] && [ "$HUMAN_COUNT" -lt 5 ]; then
    pass "活人感 commit 数量合理($HUMAN_COUNT 个)"
elif [ "$HUMAN_COUNT" -ge 5 ] && [ "$HUMAN_COUNT" -lt "$TOTAL_COUNT" ]; then
    pass "活人感 commit 数量合理($HUMAN_COUNT 个)"
else
    warn "活人感 commit 占比过高($HUMAN_COUNT / $N),commit 看起来太杂"
fi

# ========== 8. 工具配置检测 ==========
echo ""
echo "--- 工具配置 ---"

if [ -f .commitlintrc.json ] || [ -f .commitlintrc.js ] || [ -f .commitlintrc.yaml ] || [ -f commitlint.config.js ]; then
    pass "commitlint 已配置"
else
    info "未配置 commitlint(可选,推荐)"
fi

if [ -d .husky ] || grep -q "husky" package.json 2>/dev/null; then
    pass "husky pre-commit 已配置"
else
    info "未配置 husky(可选,推荐)"
fi

# ========== 总结 ==========
echo ""
echo "========================================="

# 给个总体评分
SCORE=0
[ "${AVG_LEN%.*}" -ge 30 ] && SCORE=$((SCORE + 25))
[ "$TOTAL_COUNT" -gt 0 ] && [ $((CONV_COUNT * 100 / TOTAL_COUNT)) -ge 50 ] && SCORE=$((SCORE + 25))
[ "$BAD_HITS" -eq 0 ] && SCORE=$((SCORE + 25))
[ "$HUMAN_COUNT" -gt 0 ] && [ "$HUMAN_COUNT" -lt "$TOTAL_COUNT" ] && SCORE=$((SCORE + 25))

if [ "$SCORE" -ge 80 ]; then
    echo -e "${GREEN}🎉 Commit 质量评分: $SCORE/100 — 优秀${NC}"
elif [ "$SCORE" -ge 50 ]; then
    echo -e "${YELLOW}📈 Commit 质量评分: $SCORE/100 — 还行,继续打磨${NC}"
else
    echo -e "${RED}⚠️  Commit 质量评分: $SCORE/100 — 需要改进${NC}"
fi

echo ""
echo "下一步:"
echo "  - 详见 references/03-commit-history.md"
echo "  - 工具: commitlint + husky + standard-version"
