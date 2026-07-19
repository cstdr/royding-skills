# 阶段 8: 发布前 checklist —— 最后一遍扫

> 9 阶段流程的最后一步。
> 把所有工作收尾,确认每个环节都到位,然后推送。

## 目标

- [ ] 8 个阶段都过
- [ ] 自动化扫描 0 命中
- [ ] 远程仓库配置正确(SSH / HTTPS / 权限)
- [ ] 推送 + 设默认分支
- [ ] 监控与反馈渠道(可选)

## 8.1 自动化检查(跑这个)

```bash
# 跑 scipts/pre-publish-check.sh
bash <(curl -sL https://raw.githubusercontent.com/cstdr/royding-skills/main/github-repo-polish/scripts/pre-publish-check.sh) .
```

或手动跑下面命令:

### 隐私

```bash
# 0 命中
gitleaks detect --source . --no-banner
gitleaks detect --source . --log-opts="--all" --no-banner
```

### 结构

```bash
# 必须存在的文件
ls -1 | grep -E '^(README.md|LICENSE|.gitignore)$'
# 期望 3 个文件都有

# .github/ 结构
tree .github -L 2
# 期望:
# .github/
# ├── ISSUE_TEMPLATE/
# │   ├── bug_report.yml
# │   └── feature_request.yml
# ├── workflows/
# │   └── ci.yml
# └── PULL_REQUEST_TEMPLATE.md
```

### 提交质量

```bash
# 平均 commit 长度
git log --pretty=format:'%s' | awk '{ print length }' | awk '{ s += $1; n++ } END { if (n>0) print "avg:", s/n }'

# 总 commit 数(不要太离谱)
git rev-list --count HEAD
# < 200 通常 OK
# > 500 考虑 squash

# conventional 比例
git log --pretty=format:'%s' | awk '{print $1}' | sed 's/(.*//' | sort | uniq -c | sort -rn | head
```

### README 必备 7 段

```bash
# 用 scipts/readme-skeleton.sh 检查
bash scipts/readme-skeleton.sh README.md
```

手动:
```bash
# 看 README 是否提到这些
grep -E "(Features|Quick Start|Install|Tech Stack|License)" README.md
# 期望全部命中
```

### Badge 检查

```bash
# README 顶部 30 行内应该有几个 badge
head -30 README.md | grep -c "img.shields.io"
# 期望 ≥ 3
```

## 8.2 手动检查清单

### 8.2.1 隐私

- [ ] 仓库 working tree 无密钥(`gitleaks` 0 命中)
- [ ] 仓库历史无密钥
- [ ] 没有公司邮箱 / 内部 URL
- [ ] `.env` / `.env.local` 等被 .gitignore

### 8.2.2 License

- [ ] `LICENSE` 文件存在
- [ ] Copyright 年份和姓名正确
- [ ] 与你预期一致(MIT / Apache-2.0 / GPL)

### 8.2.3 README

- [ ] 第一屏:Title + 一句话价值主张 + 1-2 badges
- [ ] 第二屏:演示图(GIF / 截图)
- [ ] 7 段齐(Features / Why / Quick Start / Tech Stack / License / 联系 / 致谢)
- [ ] 内部链接都能点开
- [ ] 没有 broken image

### 8.2.4 工程化

- [ ] CI badge 亮绿
- [ ] 至少 2 个 Issue 模板
- [ ] 1 个 PR 模板
- [ ] Dependabot 配置(可选)

### 8.2.5 活人感

- [ ] "Why I built this" 段是本人素材
- [ ] commit 不全是模板(允许少量非标)
- [ ] Roadmap 具体、不夸张
- [ ] 个人主页 / pinned 仓库完善

## 8.3 远程仓库准备

### 创建 GitHub 仓库

```bash
# CLI 创建
gh repo create my-cool-project --public --source=. --remote=origin --description "一句话价值主张"

# 或网页创建
# https://github.com/new
# 不要勾选 "Add README" / "Add .gitignore" / "Add License"(本仓库已有)
```

### 配置 git 身份(避免提交时泄漏公司邮箱)

```bash
# 全局(不推荐,会污染其他项目)
git config --global user.name "Your Name"
git config --global user.email "personal@gmail.com"

# 推荐:本仓库单独配
cd /path/to/repo
git config user.name "Your Name"
git config user.email "personal@gmail.com"
```

### 验证远程

```bash
# HTTPS(简单)
git remote -v
# origin  https://github.com/USER/REPO.git (fetch)
# origin  https://github.com/USER/REPO.git (push)

# SSH(推荐,长期用)
# origin  git@github.com:USER/REPO.git (fetch)
# origin  git@github.com:USER/REPO.git (push)
```

切换 SSH:
```bash
git remote set-url origin git@github.com:USER/REPO.git
```

## 8.4 推送

```bash
# 检查最后状态
git status

# 第一次推送
git push -u origin main

# 之后推送
git push
```

## 8.5 推送后立即做的事

### 8.5.1 GitHub 仓库设置

- **Settings → General**:
  - ✅ Allow issues
  - ✅ Allow pull requests
  - ✅ Allow discussions(社区感)
  - ❌ Allow wiki(很少用)
  - ❌ Allow projects(简单项目不用)
  
- **Settings → Pages**(如果有静态站点):
  - Source: GitHub Actions
  - 或 gh-pages branch

- **Settings → Security**:
  - ✅ Enable Dependabot alerts
  - ✅ Enable Dependabot security updates
  - ✅ Enable secret scanning
  - ✅ Enable push protection(防误推密钥)

- **About**(右上角齿轮):
  - Description: 一句话价值主张
  - Website: 个人主页(强烈推荐)
  - Topics: 5-10 个标签(`cli` / `rust` / `developer-tools` 等)
  - ✅ Releases
  - ✅ Packages
  - ❌ (不要勾)Sponsorship(除非真的要)

### 8.5.2 GitHub Social Preview

- Settings → Social preview → Upload
- 上传 1280x640 PNG
- 自己设计或用 README 顶部 banner

### 8.5.3 第一次 Issue 自我检查

发一个 self-issue 验证一切工作:
```markdown
<!-- .github/ISSUE_TEMPLATE 触发的样子 -->
标题: "Test: Issue template works"
内容: 随便填一填
```

看看模板是否正确触发。发完关掉。

### 8.5.4 第一次 PR 自我检查

```bash
# 在 GitHub 网页上,点 "Compare & pull request" 测试 PR 模板
```

## 8.6 推广(选做,不要 over-do)

### 8.6.1 立刻做

- **Hacker News**:https://news.ycombinator.com/submit
  - 标题要具体(不夸张)
  - 帖子第一行解释"为什么做"
  - 不要发"Show HN: My New Project" 这种
  
- **Reddit**:
  - r/programming, r/opensource
  - r/[你的领域]

- **X / Twitter**:
  - "刚开源了 X,解决了我自己的 Y 痛点"
  - 附 GIF / 截图
  - @ 几个相关 KOL

### 8.6.2 一周内做

- 写一篇博客 / 知乎
- 录一段 3-5 分钟 demo 视频
- 在 HN 评论自己帖子里回应评论

### 8.6.3 不要做

- ❌ Spammy promotion
- ❌ "求 star"
- ❌ 在多个无关社区刷

## 8.7 持续维护

### 8.7.1 响应 issue

- 48 小时内至少 acknowledge("看到了,这周看")
- 1 周内给方向
- 1 月内给方案或 close

### 8.7.2 监控

- 启用 GitHub Watch → All Activity
- 设 Dependabot alerts
- 周一 / 周五各看一次

### 8.7.3 更新

- 修一个 bug 就发 release
- 不要攒半年一次性发
- 小步快跑,每 1-2 周一个 release

## 8.8 阶段 8 退出标准

- [ ] 自动化扫描 0 命中
- [ ] 手动 checklist 全过
- [ ] 远程仓库配置正确
- [ ] 推送成功
- [ ] GitHub 仓库设置完成
- [ ] 至少发了一次自测 issue / PR

---

## 🎉 完成

到这里,你的仓库从"能跑但杂乱的本地项目"升级为"专业人士看了觉得维护用心的公开项目"。

最后一句:**保持维护。** 一个干净的仓库 6 个月不更新,比"乱但活跃"的仓库更显得"弃坑"。如果真要停更,在 README 顶部标注 `⚠️ Unmaintained`,这比装作还活着更显专业。
