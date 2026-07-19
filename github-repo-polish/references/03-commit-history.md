# 阶段 3: 提交历史整理

> 提交历史 = 你这个项目的"过程记录"。
> 顶尖仓库的 commit 不是 `fix` `update` `asdf`,而是一行能讲清"为什么改"的语义化记录。
> 这一步是"活人感"在最深一层的体现。

## 目标

- [ ] commit 风格统一(推荐 Conventional Commits)
- [ ] 历史里没有 `asdf` / `WIP` / `tmp` 这类无意义 commit
- [ ] 每个 commit 信息能讲清"做了什么 + 为什么"(而不仅是"做了什么")
- [ ] 总 commit 数合理(不要 500+ 杂乱 commit,能 squash 就 squash)

## 3.1 Conventional Commits 入门

### 标准格式

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### 常用 type

| type | 含义 | 示例 |
|---|---|---|
| `feat` | 新功能 | `feat(cli): add --dry-run option` |
| `fix` | 修 bug | `fix(parser): handle nested quotes in YAML` |
| `docs` | 只改文档 | `docs: fix typo in installation section` |
| `style` | 格式(不影响逻辑) | `style: go fmt` |
| `refactor` | 重构 | `refactor: extract config validation` |
| `perf` | 性能 | `perf: cache config parse result` |
| `test` | 测试 | `test: add e2e for backup command` |
| `chore` | 构建/工具/CI | `chore: bump deps` |
| `build` | 构建系统 | `build: switch to esbuild` |
| `ci` | CI 配置 | `ci: add macos to test matrix` |
| `revert` | 回滚 | `revert: feat(api): add OAuth` |

### 顶级仓库常见 practice

- 主题行不超过 50 字符
- 主题行首字母不大写
- 主题行不写句号
- body 和主题行之间空一行
- body 解释"为什么"而不是"做了什么"
- 用 `BREAKING CHANGE:` 在 footer 标注破坏性改动

## 3.2 现状评估

```bash
# 总 commit 数
git rev-list --count HEAD

# 看 commit 平均长度
git log --pretty=format:'%s' | awk '{ print length }' | awk '{ s += $1; n++ } END { print s/n }'

# 看 type 分布(如果有 conventional 前缀)
git log --pretty=format:'%s' | awk '{print $1}' | sed 's/(.*//' | sort | uniq -c | sort -rn
```

## 3.3 三种处理方式

### 方式 A: 直接发(适合 100+ stars 的成熟项目)

如果仓库已经在用,只允许:
- 后续 commit 用 conventional 风格
- 跑 `commitlint` + `husky` 防止回退
- **不重写历史**(会丢 forks / 影响现有协作者)

```bash
# npm 项目
npm install --save-dev @commitlint/{config-conventional,cli} husky
npx husky init
echo "npx --no-install commitlint --edit \$1" > .husky/commit-msg
```

### 方式 B: 清理后重写(适合 < 100 stars 的 launch 阶段项目)

**前提:仓库还没公开,或者你接受所有 stars/forks 失效。**

```bash
# 1. 看哪些 commit 想合并 / 删除
git log --oneline

# 2. 交互式 rebase 最近 20 个 commit
git rebase -i HEAD~20

# 在编辑器里:
#   pick abc1234 feat: add X
#   squash def5678 fix typo
#   squash ghi9012 still fix
#   pick jkl3456 feat: add Y
```

**实战小技巧**:把同主题的 commit 全部 squash 成一个,且 squash 时改写 message 写清"为什么"。

### 方式 C: 推到新仓库(适合历史太乱、5+ 年、几十个密钥散落)

1. working tree 拷出来
2. `git init` 新仓库
3. 写一个干净的初始 commit:

```bash
# 把整个当前代码 + README + LICENSE 当作 v1.0 首发
git add .
git commit -m "$(cat <<'EOF'
feat: initial public release

包含功能:
- CLI 主流程(X / Y / Z)
- 配置文件解析
- --dry-run 模式
- 单元测试覆盖率 65%
- 集成测试覆盖主要场景

已知问题(欢迎 issue):
- macOS 上偶发段错误,概率 < 0.1%
- 大文件(>1GB)处理慢,后续加 streaming

Refs: 内部项目代号 royding-v1
EOF
)"
```

4. 推送到新仓库

## 3.4 自动生成 changelog(可选)

用 conventional-changelog / standard-version / release-please:

```bash
# npm 项目
npm install --save-dev standard-version

# package.json 加 script
"scripts": {
  "release": "standard-version"
}

# 跑一下
npm run release
# 自动 bump version + 更新 CHANGELOG.md + git tag
```

或 GitHub Actions 自动(推荐,完全自动化):

```yaml
# .github/workflows/release.yml
name: release-please
on:
  push:
    branches: [main]
jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

## 3.5 活人感在 commit 里的体现

顶尖仓库的 commit 不是全 conventional 模板,允许少量"非标"commit 出现,反而更像活人:

- `wip: refactor config layer, don't merge yet` —— 进行时感
- `fix: typo in help text (was embarrassing)` —— 自嘲
- `chore: bump deps, again` —— 平淡但真实
- `oops, revert` —— 出错就承认

**原则:90% 规范化,10% 自由。** 全是模板 = AI,全自由 = 杂乱。

## 3.6 阶段 3 退出标准

- [ ] 新 commit 用 conventional 格式(如果用了)
- [ ] 历史里没有 `asdf` / `tmp` / `WIP` 这种废 commit
- [ ] commit message 平均长度 > 30 字符(太短说明没讲清"为什么")
- [ ] 有 changelog / release 机制(自动或手动)
- [ ] 跑 `git log --oneline | head -20` 看到的是讲清"做了什么 + 为什么"的列表

---

## 关联脚本

`scipts/commit-stats.sh` 自动统计上述指标。

## 下一个:阶段 4 README 架构
