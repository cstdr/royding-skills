# 阶段 7: 个人信息 & 活人感植入

> 这是让"专业"和"AI 模板填空"拉开差距的关键阶段。
> 前面所有阶段可以让仓库看起来"规范",但只有这一阶段让它看起来"有人在维护"。

## 核心原则

**所有"活人感"内容必须来自你本人,AI 不能编。** 这一阶段我会问你"你怎么想",你回答,我帮你整理成 README / Issue / 个人主页的语言。

## 7.1 仓库里的活人感(每个仓库都要做的)

### 7.1.1 commit 信息里的小细节

不要全 conventional 模板,**允许 10% 的"非标" commit**:

✅ 活人感 commit:
```
wip: refactor config layer, don't merge yet
fix: typo in help text (was embarrassing)
chore: bump deps, again
oops, forgot to add the .example
```

❌ 模板感 commit:
```
feat: add new feature
fix: fix bug
chore: update dependencies
```

### 7.1.2 README 里的"我"段

```markdown
## Why I built this

我每天 [痛点]。所以写了 [项目名]。

第一版是 [Q2 第一版],后来 [Q3 重构过程]。

还没支持 [X 功能],因为 [理由]。

如果你也 [Q6 什么样的人会喜欢],欢迎试用。
```

### 7.1.3 Roadmap 里的诚实

```markdown
## Roadmap

- [x] CLI 主流程
- [x] 配置文件
- [x] 单元测试

下一步(这个月):
- [ ] --dry-run 模式
- [ ] 修复 macOS 段错误(目前 reproduce 不出来,有点难)
- [ ] 也许加 fish shell 支持?看需求

明确不做:
- ❌ GUI(用 CLI 的人更多,维护成本不值)
- ❌ Windows native(WSL 够了,精力有限)
```

### 7.1.4 Issue 互动里的礼貌和诚实

被问问题时:

✅ 活人感回复:
> "好问题!这个我之前没想到过。我看下,大概这周能给反馈。先 mark `help wanted`,欢迎其他用过的人补充。"

❌ AI 模板回复:
> "Thank you for your feedback. We will consider this in future releases."

## 7.2 个人主页活人感(cstdr/<username>)

### 7.2.1 头像

**不要用默认 placeholder**。优先顺序:
1. 真人照片(脱敏处理过的)
2. 风格化插画(https://thispersondoesnotexist.com 生成)
3. Logo / 品牌
4. 抽象图形

### 7.2.2 bio

✅ 活人感 bio:
```
building tools I wish existed
or: my-day-job-is-X, my-side-quest-is-Y
📍 杭州 / Remote
Currently hacking on [项目名]
```

❌ AI 模板 bio:
```
Passionate software engineer with expertise in full-stack development.
Building modern solutions for tomorrow's problems.
```

### 7.2.3 pinned 仓库的 README

**6 个 pinned 仓库的 README 头部** 都应该有一段"为什么我维护这个":

```markdown
# repo-name

> 一句话价值主张

这是我的 [X 类项目]。

为什么做这个: [个人故事 1-2 句]
```

## 7.3 跨仓库的"个人主页"仓库

GitHub 支持 `<username>/<username>` 仓库作为 profile README。必做。

### 模板

```markdown
# 你好,我是 [Name] 👋

## 现在在做什么

[1-2 句话,讲当前工作/学习重点]

## 工具栈

- 主语言: [X]
- 折腾中: [Y]
- 关注: [Z]

## 最近的项目

- 📦 [项目 1](https://github.com/...): 一句话
- 📦 [项目 2](https://github.com/...): 一句话

## 写代码之外

[选填,放你写代码以外的事:写作、独立游戏、摄影等]

## 联系方式

- 邮箱: [可选,推荐 mastodon / 邮箱 alias]
- Twitter: [可选]
- 个人主页: [强烈推荐,即使是一页]
```

### 不要做的事

- ❌ 抄 "Passionate software engineer..."
- ❌ 100+ 个 badge 堆满屏
- ❌ 自动生成的 GitHub stats 卡片(已经过时,看着像 AI)
- ❌ 抄袭别人的 profile README 结构

## 7.4 真人头像去重

如果想"脱敏",用 `thispersondoesnotexist.com` 风格化插画,或用 `https://pfpfpf.com.cn/` 卡通头像。

但**最好用真人照片**。Open source = 实名(真名或 GitHub 名),越真实越信任。

## 7.5 个人主页(强烈推荐)

即使是一页,放你的:

- 自我介绍(一段)
- 现在在做什么
- 联系方式
- 你关心的事

工具:
- **GitHub Pages + Jekyll**(`github.com/<username>/<username>.github.io`)
- **Vercel + Astro / Next.js** —— 部署比 Jekyll 简单
- **Hashnode / Dev.to** —— 用现成平台,省时间

参考例子:
- https://maggieappleton.com/(设计师 + 程序员,风格化)
- https://rauchg.com/(Vercel CEO,极简)
- https://addyosmani.com/(Google Chrome 团队,博客式)

## 7.6 反 AI 检测清单

发布前,问自己 5 个问题:

1. **如果把仓库名换掉,这段 README 还能用吗?**
   - 能 → 太 AI,改具体
   - 不能 → OK
   
2. **commit 信息是不是太"完美"了?**
   - 全 conventional 没瑕疵 → 加 2-3 个"oops" "wip"
   - 有偶尔的非标 → OK
   
3. **Roadmap 是"我打算做什么"还是"市场要什么"?**
   - "我们计划进入 X 市场" → 改 "我自己想加 X"
   
4. **Issue 回复有没有"我"?**
   - 全是"We will consider" → 改成"我看了下,这个我有几个想法"
   
5. **个人主页有没有具体的事?**
   - "Loves hiking and coffee" → 改 "杭州西湖区,周末常去爬山"

## 7.7 阶段 7 退出标准

- [ ] README 里有"我"的段落(为什么做 / 还在犹豫什么)
- [ ] 提交历史有少量非标 commit(不要全模板)
- [ ] GitHub 个人 profile 完善(头像、bio、pinned)
- [ ] (可选)个人主页部署
- [ ] 反 AI 检测 5 问都过

---

## 最后一个:阶段 8 发布前 checklist
