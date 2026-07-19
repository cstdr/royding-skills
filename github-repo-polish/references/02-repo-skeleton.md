# 阶段 2: 仓库骨架 —— 基础文件

> 阶段 1 通过(零泄露)后,开始搭骨架。
> 这一阶段全是"地基"——没有 README 内容,但仓库打开来不会"空荡"。

## 目标

- [ ] `.gitignore` 完整,不漏 `node_modules` / `__pycache__` / `.env`
- [ ] `LICENSE` 选对(不是 "No License")
- [ ] `README.md` 至少有 1 行 placeholder,不至于默认 # Project Name
- [ ] `CHANGELOG.md` 空架子(后面填)
- [ ] `.github/` 目录创建

## 2.1 .gitignore

### 快速开始:用 gitignore.io

```bash
# 一行命令生成针对你技术栈的 .gitignore
curl -sL https://www.toptal.com/developers/gitignore/api/node,python,macos,windows,vim,vscode > .gitignore
```

或访问 https://www.toptal.com/developers/gitignore/

### 无论什么语言,以下 5 类必加

```gitignore
# 1. 密钥 / 配置
.env
.env.*
!.env.example
*.key
*.pem
*.p12
*.pfx
config/local.*
secrets.yaml
secrets.json

# 2. 编辑器 / 系统
.DS_Store
Thumbs.db
*.swp
*.swo
*~
.idea/
.vscode/
.fleet/
.cursor/
# 例外:让 .vscode/settings.json 进库(团队共享配置)
!.vscode/settings.json
!.vscode/extensions.json

# 3. 构建产物
dist/
build/
out/
target/
bin/
obj/
*.o
*.so
*.dylib
*.dll
*.exe

# 4. 依赖
node_modules/
__pycache__/
*.pyc
.venv/
venv/
env/
vendor/
.gradle/
.idea/

# 5. 运行时数据
*.log
logs/
.cache/
.tmp/
tmp/
coverage/
.nyc_output/
```

### 验证:确保没有误提交

```bash
# 检查是否有已 tracked 的 .env
git ls-files | grep -E '\.env$|\.key$|\.pem$'
# 如果有,先 untrack:
git rm --cached .env
# 重新 commit
```

## 2.2 LICENSE

### 选 License 的决策

| 你的情况 | 推荐 License |
|---|---|
| 想要"被人随便用、提 PR 也行、最好别删我名字" | **MIT**(最常见,90% 公开仓库) |
| 想要"被人用,但改了要说明" | **Apache-2.0**(大公司偏好,有专利授权) |
| 想要"改了我得能拿到源码" | **GPL-3.0**(慎用,会限制商用) |
| 想要"完全放弃权利" | **Unlicense** / **CC0** |
| 文档为主,不是代码 | **CC-BY-4.0** |
| 内部工具,只是公开给熟人看 | **No License**(但别人没法合法用) |

**默认推荐 MIT。** 不确定就 MIT。

### 拿 License 文本

- **不要手写**——很多人手写漏关键条款,法律无效
- https://choosealicense.com/ 选好后直接拷
- 或 `gh repo edit --license MIT`(命令行)

### 写 License 时填三个字段

- **Copyright [year] [name]** —— 年份和真名
- 真名 vs 笔名:看你。如果不希望搜索引擎关联,放 GitHub username 而不是真名

```text
MIT License

Copyright (c) 2024 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
...
```

## 2.3 README 占位符

阶段 4 才写完整 README,但阶段 2 至少放 1 个 placeholder,免得仓库空荡荡:

```markdown
# Project Name

> 一句话价值主张(阶段 4 会展开)

🚧 准备公开中,文档会持续更新。
```

## 2.4 .github/ 目录

```bash
mkdir -p .github/ISSUE_TEMPLATE
```

后续阶段会填,这里只创建目录。

## 2.5 CHANGELOG.md(可选)

```markdown
# Changelog

所有值得注意的改动都记录在这里。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/),
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added
### Changed
### Fixed
```

或者用 release-drafter / conventional-changelog 自动生成,阶段 3 展开。

## 2.6 阶段 2 退出标准

- [ ] `.gitignore` 完整,`git status` 不显示应被忽略的文件
- [ ] `LICENSE` 已选并提交
- [ ] `README.md` 至少 1 行(占位符)
- [ ] `.github/` 目录已创建
- [ ] 整个仓库跑 `tree -L 2 -a -I '.git'` 结构清晰

## 完成后下一步

进入**阶段 3: 提交历史整理**。
