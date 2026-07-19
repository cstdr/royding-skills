# 阶段 4: README 架构 —— 7 段式骨架

> README 是仓库的"门面"。扫描一个仓库 5 秒,只够看 README 头部。
> 这一阶段要做的:有结构 + 有内容 + 有"我"。
> 阶段 0 采集的素材,在这里**真实地**写进去——AI 不能编。

## 目标:7 段式结构

```
[1] Title + 一句话价值主张 + Badges
[2] Demo(图或 GIF,或一段 terminal 输出)
[3] Features(列表,4-7 条)
[4] Why this exists(活人感段,选自阶段 0 素材)
[5] Quick Start(3 步能跑起来)
[6] Tech Stack(2-3 个核心依赖 + 为什么选)
[7] License + 联系 + 致谢
```

**可选 8-10 段**:
- Architecture diagram
- Roadmap
- Contributing
- FAQ
- Star History
- 类似项目对比

## 4.1 段 [1]: Title + 价值主张 + Badges

```markdown
# Project Name

> **一句话价值主张**:动词 + 对象 + 痛点
> 例:"A blazing-fast CLI to sync dotfiles across machines"
> 例:"把 Node 项目的环境变量管理从 30 秒压到 1 秒"

<p align="left">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/USER/REPO?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/github/stars/USER/REPO?style=flat-square" alt="Stars">
  <img src="https://img.shields.io/github/forks/USER/REPO?style=flat-square" alt="Forks">
  <img src="https://img.shields.io/github/issues/USER/REPO?style=flat-square" alt="Issues">
  <img src="https://img.shields.io/github/actions/workflow/status/USER/REPO/ci.yml?style=flat-square" alt="CI">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square" alt="PRs Welcome">
</p>
```

### Badge 选用原则

**有用的(选 3-6 个)**:
- License
- CI 状态
- Version / Release
- Downloads / Stars(社交证明)
- PRs welcome(降低贡献门槛)

**没用的(别加)**:
- Build passing(没意义,谁管你 build)
- 99+ 通用 badge 像 "made with ❤"
- GitHub Readme Stats(大牛不用,看起来很 AI)

### 拿 badge 的途径

- https://shields.io/ —— 选模板,改参数
- https://github.com/badges/shields —— 自己 host shields

## 4.2 段 [2]: Demo

> **3 秒抓住人:一张图 / 一段录屏。**

### 选哪种

| 形式 | 适合 | 工具 |
|---|---|---|
| **终端录屏 GIF** | CLI 工具 | `vhs` / `terminalizer` / `asciinema` |
| **截图(应用界面)** | GUI / 桌面应用 | 系统截图 + `imgbot` 压缩 |
| **架构图** | 库 / 框架 | `excalidraw` / `mermaid` |
| **Logo / Banner** | 纯展示 | `figma` / `canva` |

### 实操建议

- GIF 大小压到 < 5MB(超过 GitHub 不直接预览,要点击)
- 用 `gifski` 压,质量好体积小
- 第一帧要"有信息"(黑屏滚动 3 秒的 GIF 直接关)
- 5-15 秒最佳

### 录屏脚本示例(用 vhs)

```tape
# demo.tape
Output demo.gif
Set FontSize 14
Set Width 1200
Set Height 600

Type "npx my-tool init"
Enter
Sleep 1s
Type "npx my-tool run"
Enter
Sleep 3s
Type "npx my-tool --help"
Enter
Sleep 2s
```

跑 `vhs demo.tape` 生成 GIF。

## 4.3 段 [3]: Features

```markdown
## ✨ Features

- ✅ **Feature 1**: 动词 + 量化收益(不要"好用的 X",要"X 比 Y 快 3 倍")
- ✅ **Feature 2**: 用 emoji 分组,但别每条都加
- ✅ **Feature 3**: 4-7 条最佳,8+ 显得没重点
- ✅ **Feature 4**: 一定要有 1-2 条"和别人不一样"的
- ⚠️ **Experimental**: 这种标注"还不稳"比"完成"更活人
```

### 反面例子

```markdown
❌ 错误示范:
- Modern ✨
- Blazing-fast 🚀
- Type-safe 💎
- Open source 🌟
# 这不叫 features,叫 buzzword 列表
```

## 4.4 段 [4]: Why this exists (活人感关键!)

```markdown
## 🤔 Why this exists

[这里必须是你阶段 0 回答的 Q1 - Q5 浓缩成 1-2 段话。]

我自己每天 [痛点 Q1],所以写了 [项目名]。

第一版是 [Q2 第一版],后来 [Q3 主动选 / 被动妥协]。

目前 [Q5 还不满意的部分],但 [Q4 砍掉的功能] 决定先发出来。

如果你也 [Q6 什么样的人会喜欢],欢迎试用。
```

### 真实案例参考(改了细节)

> "我每天要把 5 个 git 仓库切到 main 拉新代码,攒一周忘了就冲突,所以写了这个工具。
> 第一版是 Bash 脚本,300 行 if-else 嵌套到我自己都看不懂。后来用 Go 重写,加单元测试,才敢开源。
> 还没支持 fish shell(用 fish 的人少,先不做)。如果你用 zsh/bash,大概率顺手;用 Windows 的朋友,WSL 应该可以,Native 我没测过。"

## 4.5 段 [5]: Quick Start

```markdown
## 🚀 Quick Start

### 安装

\`\`\`bash
# npm
npm install -g my-tool

# Homebrew
brew install my-tool

# 源码
git clone https://github.com/USER/REPO
cd REPO && make install
\`\`\`

### 30 秒上手

\`\`\`bash
# 初始化配置
my-tool init

# 跑一次
my-tool run --config ./my.yaml

# 验证
my-tool verify
\`\`\`

完成!详细用法见 [docs/](./docs) 或 `my-tool --help`。
```

### 关键点

- 安装 ≤ 3 种方式(选最常见的)
- "30 秒上手"要真的能 30 秒跑通
- **必须有可复制的命令**,不要只描述

## 4.6 段 [6]: Tech Stack

```markdown
## 🛠 Tech Stack

- **[Language]** — [为什么选]
- **[Framework]** — [为什么选]
- **[Database / Service]** — [为什么选]

> 备选方案 / 为什么没选 X: [诚实理由,体现思考]
```

### 案例

> - **Rust** — 启动 < 50ms 的硬需求,Go 不行
> - **SQLite** — 95% 场景单文件够用,Postgres 留给 v2
> - **没选 X** — X 更流行但 onboarding 成本高,本项目用户群体更熟 Rust

## 4.7 段 [7]: License + 联系 + 致谢

```markdown
## 📜 License

[MIT](LICENSE) © [Year] [Your Name]

## 📬 联系

- Issue: [GitHub Issues](../../issues)(最方便)
- Email: [可选,推荐 mastodon / 邮箱 alias]
- 个人主页: [可选]

## 🙏 致谢

- [项目名 / 个人名] — [具体帮了什么]
- [灵感来源]
- 任何引用过的代码、文档、Stack Overflow 答案(诚实标注)
```

## 4.8 可选段

### Architecture(库 / 框架必加)

```markdown
## 🏗 Architecture

\`\`\`mermaid
graph LR
  A[CLI] --> B[Parser]
  B --> C[Executor]
  C --> D[Storage]
\`\`\`
```

### Roadmap

```markdown
## 🛣 Roadmap

短期(下个月):
- [ ] Feature A
- [ ] Fix issue #XX

中期(3-6 月):
- [ ] Feature B(还在犹豫要不要做)

明确不做(欢迎 issue 反向 challenge):
- ❌ GUI(用 CLI 的人更多)
- ❌ Windows native(WSL 够了)
```

### Star History

```markdown
## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=USER/REPO&type=Date)](https://star-history.com/#USER/REPO)
```

### 关键参考:活人感填空

每个段落写完,问自己:"这段放别人项目能不能用?"
- 能 → 太 AI,改
- 不能(只适用于我) → 活人感 OK

## 4.9 完整 README 模板(可直接用)

见 `templates/README-template.md`(阶段 8 发布前最后复制用)。

## 4.10 阶段 4 退出标准

- [ ] 7 段都齐
- [ ] Features 4-7 条,每条具体(不空话)
- [ ] "Why this exists" 段是阶段 0 你本人提供的素材
- [ ] Quick Start 复制粘贴能跑
- [ ] 整体读一遍,没有"现代 / blazing / type-safe" 套话

---

## 下一个:阶段 5 工程化
