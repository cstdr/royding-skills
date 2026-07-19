---
name: github-repo-polish
description: Use when preparing a GitHub repository for public release, including auditing for leaked secrets, cleaning commit history, writing a professional README, adding CI badges, drafting issue/PR templates, and adding personal touches that make the repo feel human-maintained rather than AI-generated. Triggered by phrases like "我要开源了", "准备公开仓库", "repo 准备公开", "open source 准备", "整理下仓库再推", "想给这个仓库加 README", "提交历史太乱想整理", "不小心提交了密钥".
license: MIT
metadata:
  scope: pre-public-launch repo polish
  audience: solo developer or small team
  baseline: top-1000-starred public repos (awesome-readme, best-readme-template, conventional-commits 等)
---

# GitHub Repo Polish

把一个"能跑但像半成品"的仓库,打磨成"专业人士扫一眼就觉得维护用心"的公开仓库。

**核心目标:**
1. **零隐私泄露** —— 密钥、API key、个人信息绝不出现在代码或历史里
2. **结构一眼可读** —— README / Issue / PR / CI / License 全部到位
3. **真实活人感** —— 不像 AI 模板填空,每个仓库都有你自己的故事和判断

## When to use

- 决定要把私有仓库转公开 / 推到 GitHub 前
- 仓库跑得好好的,但 README 仍是默认 `# Project Name`
- 提交历史里有 `asdf`, `fix`, `WIP` 之类的废 commit
- 不小心把 `.env` / API key 提交进去了
- 想加 CI、徽章、issue 模板,让仓库看起来"工程化"
- 准备求职,想用 GitHub 主页证明自己

## When NOT to use

- 仓库还没跑通,先不急着打磨(先把 `npm start` 跑起来)
- 还在快速迭代期,功能没定型(过早 polish 是浪费)
- 已经是 1000+ stars 的成熟项目(本 skill 是 launch 阶段用的)

## 核心原则

### 原则 1: 专业感的 7 个硬指标

1. **README 必备 7 段**:Title + 价值主张 / Badges / Demo 图或 GIF / Features / Quick Start / Tech Stack / License
2. **`.github/` 5 件套**:`ISSUE_TEMPLATE/`(bug+feature)、`PULL_REQUEST_TEMPLATE.md`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`FUNDING.yml`(可选)
3. **CI Badge 亮绿**:至少 `ci.yml` 跑 build/lint,README 顶部挂 badge
4. **License 选对**:开源 = MIT / Apache-2.0,商业慎用 GPL,不要用"No License"(默认是 copyright,你没放弃权利但别人也不敢用)
5. **提交风格统一**:Conventional Commits(`feat: ...` / `fix: ...` / `docs: ...`),不是强求但顶尖仓库都在用
6. **隐私扫描 0 命中**:`gitleaks detect` 跑过,历史里也没有遗留
7. **首页有图**:README 顶部 1-2 张截图/GIF,胜过千言

### 原则 2: 活人感的 5 个反 AI 信号(关键!)

| AI 模板感 ❌ | 活人感 ✅ |
|---|---|
| "A modern, blazing-fast, type-safe solution" | "这个工具解决了我每天手动跑命令的痛点" |
| README 全是 bullets,没有一句"我" | "我本来想用 X 库,但 Y 问题让我换成自己撸" |
| Issues 全是 closed 完美回答 | "X 我还没想清楚,先放着,如果你有想法欢迎 issue" |
| Roadmap 写"Global domination" | "下一步想加 A,但 B 比 A 难,先 A" |
| Commit 全是 `feat: add feature` | 偶尔有 `wip: still rough, but working` / `oops, fix typo` |

**所有"活人感"内容必须来自你本人,不能由 AI 编造。** 本 skill 在多处会停下问你"这件事你怎么想",必须由你回答。

### 原则 3: 不要 over-engineer

- 5 个用户的项目,不需要 `CONTRIBUTING.md` 1000 字
- 个人玩具,不需要 Code of Conduct
- 内部工具,不需要 Issue 模板 5 选 1
- 看仓库实际规模,该省就省。**删比加更显专业。**

## 流程:9 阶段(可重入)

```
阶段 0: 准备 —— 采集你的故事(活人感素材)
   ↓
阶段 1: 隐私审计 —— gitleaks + git filter,0 命中
   ↓
阶段 2: 仓库骨架 —— .gitignore / LICENSE / README 头
   ↓
阶段 3: 提交历史整理 —— 废 commit 压缩 / 改写 / squash
   ↓
阶段 4: README 架构 —— 7 段式 + demo 图
   ↓
阶段 5: .github/ 工程化 —— Issue / PR 模板 + CI badge
   ↓
阶段 6: 截图与演示 —— GIF / 终端录屏 / 架构图
   ↓
阶段 7: 个人信息与活人感 —— author / bio / pinned / 个人网站
   ↓
阶段 8: 发布前 checklist —— 最后一遍扫,推送
```

**任一阶段失败都可跳到阶段 0 重来或回滚**(比如发现隐私泄露 → 回阶段 1;觉得 README 太干 → 回阶段 0 补素材)。

## 入口:如何启动

用户说"我要准备把 X 仓库公开了",或者"open source 准备" / "公开仓库" → 进入本 skill。

第一件事是**进入阶段 0,采集你的故事**。不要直接进技术活,因为"活人感"必须本人提供素材,AI 没法编。

## 阶段总览(细节在 references/ 里)

- **阶段 0: 准备** —— 见 `references/00-prep-story.md`,8 个必答题采集你的素材
- **阶段 1: 隐私** —— 见 `references/01-privacy-audit.md`,gitleaks + git-filter-repo
- **阶段 2: 骨架** —— 见 `references/02-repo-skeleton.md`,`.gitignore` / `LICENSE` / `README` 头
- **阶段 3: 提交历史** —— 见 `references/03-commit-history.md`,conventional commits + 历史重写
- **阶段 4: README** —— 见 `references/04-readme-architecture.md`,7 段式骨架 + 活人感填空
- **阶段 5: 工程化** —— 见 `references/05-engineering.md`,issue / PR / CI / dependabot
- **阶段 6: 演示** —— 见 `references/06-screenshots-demo.md`,截图、终端 GIF、架构图
- **阶段 7: 个人信息** —— 见 `references/07-personal-touch.md`,bio / pinned / 个人主页
- **阶段 8: 发布前** —— 见 `references/08-launch-checklist.md`,最后一遍扫

## 辅助脚本(在 scripts/)

- `privacy-scan.sh` —— 一键跑 gitleaks + 检测常见误提交(`.env` / `node_modules` / `*.key`)
- `commit-stats.sh` —— 统计 commit 质量(平均长度、emoji 使用、conventional 比例)
- `readme-skeleton.sh` —— 从 README.md 提取章节,看是否漏 7 段必备
- `pre-publish-check.sh` —— 阶段 8 的自动化 checklist

## 测试记录

- 用户 cstdr 的 `royding-skills` 仓库(本仓库)用本 skill 跑过完整 9 阶段,公开后从 0 stars 到 5 stars 用时 3 天(求职方向:AI Engineer)
- 用户的 Live Wallpaper 仓库经本 skill 整理后,提交历史从 200+ 杂乱 commit 重写为 30+ 语义化 commit,README 添加 demo GIF
- 用户的 USB 数据恢复 skill 仓库经本 skill 整理后,新增 CI badge、issue 模板、SCRIPTS 目录

## 关联资源

- **Conventional Commits 规范**:https://www.conventionalcommits.org/
- **gitleaks**:https://github.com/gitleaks/gitleaks
- **git-filter-repo**:https://github.com/newren/git-filter-repo
- **choosealicense.com**:https://choosealicense.com/(License 选择的权威指南)
- **shields.io**:https://shields.io/(徽章生成)
- **awesome-readme 案例库**:https://github.com/matiassingers/awesome-readme
- **GitHub 官方仓库设置指南**:https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features
