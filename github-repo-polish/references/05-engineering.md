# 阶段 5: .github/ 工程化 —— Issue / PR / CI / Dependabot

> 仓库看起来"工程化"靠的不是多,而是**该有的都有**。
> 这一阶段让你扫一眼 `.github/` 目录就知道"作者在认真维护"。

## 目标

- [ ] `.github/ISSUE_TEMPLATE/` 至少 bug + feature 两份
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` 存在
- [ ] `.github/workflows/ci.yml` 跑 build + lint + test
- [ ] README 顶部 CI badge 亮绿
- [ ] (可选)`dependabot.yml` 自动 PR 依赖更新
- [ ] (可选)`CONTRIBUTING.md` / `CODE_OF_CONDUCT.md` / `SECURITY.md`

## 5.1 Issue Templates

### 用 GitHub 推荐的 .yml 形式(2020 后)

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: 🐛 Bug Report
description: Report something that's broken
title: "[Bug]: "
labels: ["bug", "triage"]
assignees: []

body:
  - type: markdown
    attributes:
      content: |
        Thanks for reporting! Please fill out the info below.

  - type: input
    id: version
    attributes:
      label: Version
      placeholder: "v1.2.3 / commit abc1234 / main HEAD"
    validations:
      required: true

  - type: textarea
    id: reproduce
    attributes:
      label: Steps to reproduce
      placeholder: |
        1. Run `my-tool init`
        2. Then `my-tool run --foo bar`
        3. See error
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual behavior
    validations:
      required: true

  - type: input
    id: env
    attributes:
      label: Environment
      placeholder: "macOS 14.2 / Node 20.10.0 / Apple M2"
    validations:
      required: false
```

### 为什么用 .yml 而不是 .md

- 强制用户填必填项(版本、reproduce 步骤)
- 标签自动打
- 减少"我遇到个问题"这种空 issue

### 模板选什么(看你的项目)

| 模板 | 适合 |
|---|---|
| `bug_report.yml` | 任何项目 |
| `feature_request.yml` | 工具 / 库 |
| `question.yml` | 框架 / 学习资源 |
| `docs_issue.yml` | 文档为主的项目 |

**不要做太多。** 5 用户以下的仓库,bug + feature 2 个就够,加 question 反而劝退新用户。

## 5.2 PULL_REQUEST_TEMPLATE

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->

## What does this PR do?

<!-- 1-3 句话说清,不要写"see diff" -->

## Why?

<!-- 解决了哪个 issue / 哪个痛点? 重要:写"为什么"而不是"做了什么" -->

Fixes #

## How to test

<!-- 1. 步骤 -->

## Checklist

- [ ] My code follows the project's style
- [ ] I've added tests
- [ ] I've updated relevant docs
- [ ] I've run `make lint` and `make test` locally

## Screenshots (if applicable)

<!-- UI 改动必加 -->
```

### 活人感元素(可选加分项)

```markdown
## What I struggled with

<!-- 写 PR 的人自己踩的坑,reviewer 看了会很有共鸣 -->

## What I'm not sure about

<!-- 诚实的"我不太确定",可以寻求 review -->
```

## 5.3 CI workflow

### 最小可用(任何语言都适用)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        # 想要 windows 也跑就加 windows-latest,但启动慢
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        if: ${{ hashFiles('package.json') != '' }}
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install
        run: |
          if [ -f package.json ]; then npm ci; fi
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f go.mod ]; then go mod download; fi

      - name: Lint
        run: |
          if [ -f package.json ]; then npm run lint || true; fi
          if command -v golangci-lint > /dev/null; then golangci-lint run || true; fi

      - name: Test
        run: |
          if [ -f package.json ]; then npm test; fi
          if [ -f go.mod ]; then go test ./...; fi
          if [ -f pytest.ini ] || [ -d tests ]; then pytest; fi
```

### 各语言推荐 CI

| 语言 | GitHub Action |
|---|---|
| Node.js | `actions/setup-node` + `npm ci` + `npm test` |
| Python | `actions/setup-python` + `pip install` + `pytest` |
| Go | 自带 `go test`,加 `golangci-lint` |
| Rust | `dtolnay/rust-toolchain` + `cargo test` |
| Tauri | `tauri-apps/tauri-action` |

### 缓存加速(关键)

- Node: `cache: 'npm'` 上面已经有
- Python: `actions/cache@v4` + `~/.cache/pip`
- Go: `actions/cache@v4` + `~/go/pkg/mod`

跑过的 pipeline 知道这一步从 3 分钟降到 30 秒。

## 5.4 Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
    groups:
      patch-and-minor:
        applies-to: version-updates
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
    groups:
      actions:
        applies-to: version-updates
```

### Dependabot 的活人感

Dependabot 自动 PR 默认标题很烦:`Bump lodash from 4.17.20 to 4.17.21`。可以在 `.github/dependabot.yml` 配置 commit-message prefix:

```yaml
commit-message:
  prefix: "chore"
  prefix-development: "chore(dev)"
  include: "scope"
```

这样 PR 标题变 `chore(deps): bump lodash from 4.17.20 to 4.17.21`,符合 conventional commits。

## 5.5 CONTRIBUTING.md(选做)

**小项目不必有**,但写一份 200 行的简单版,可以省去 80% 的"如何贡献"问答。

```markdown
# Contributing to [Project]

## Quick start

\`\`\`bash
git clone https://github.com/USER/REPO
cd REPO
make setup  # 或 npm install / pip install -e .
\`\`\`

## Workflow

1. Fork & create branch (`git checkout -b feat/my-thing`)
2. Make changes
3. Add tests
4. Run `make test` (everything should pass)
5. Open PR(参考 PR 模板)

## Code style

- [本项目用 X 工具]
- `make lint` 跑过

## Commit messages

- Conventional Commits 格式
- `feat: ...` `fix: ...` `docs: ...`

## Reporting bugs

Use [bug report template](../../issues/new/choose)

## Suggesting features

Open an issue with the `feature_request` label.

## Anything else

直接开 issue 问。
```

## 5.6 CODE_OF_CONDUCT.md(选做)

用 GitHub 推荐的 Contributor Covenant:

```bash
curl -o .github/CODE_OF_CONDUCT.md https://raw.githubusercontent.com/ContributorCovenant/ContributorCovenant/main/code_of_conduct.md
# 改里面的 [INSERT CONTACT METHOD] 联系方式
```

**5 个用户以下不必有**。

## 5.7 SECURITY.md

```markdown
# Security Policy

## Supported versions

| Version | Supported          |
|---------|--------------------|
| 1.x     | ✅                 |
| < 1.0   | ❌                 |

## Reporting a vulnerability

**请不要在 public issue 报告安全漏洞。**

发邮件到 [your-email] 或 [GitHub Security Advisories](../../security/advisories/new)。

我会在 48 小时内回复,7 天内给修复时间表。
```

## 5.8 阶段 5 退出标准

- [ ] `.github/ISSUE_TEMPLATE/` 至少有 bug + feature 两个 .yml
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` 存在
- [ ] `.github/workflows/ci.yml` 在 main 上跑通
- [ ] README 顶部 CI badge 引用了这个 workflow
- [ ] (可选)`.github/dependabot.yml` 已配置
- [ ] 跑 `tree .github/` 结构清晰

---

## 下一个:阶段 6 截图与演示
