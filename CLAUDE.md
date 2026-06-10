# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概述

这是 **royding-skills** 仓库（github.com/cstdr/royding-skills），一个 AI Agent Skills 集合。目前有两个 skill：`pregnancy-meal-planner`（孕期饮食规划）和 `usb-mac-recovery`（macOS USB 数据恢复）。

**这不是代码项目**，没有构建系统、没有测试框架、没有 npm/node 依赖。所有内容都是 Markdown 文档。

## 当前 skill 概况

### pregnancy-meal-planner（v1.4）
孕期食谱助手，基于循证医学原则生成每日饮食计划。

**数据文件路径**由 `$PREGNANCY_SKILL_DIR` 环境变量决定：
- OpenClaw: `~/.openclaw/`
- Claude Code: `~/.claude/`
- Codex: `~/.codex/`

三个 JSON 数据文件：
- `pregnancy-profile.json` — 用户状态（孕周/预产期/口味偏好/医生建议）
- `pregnancy-meal-history.json` — 滚动保留3周历史，用于主菜查重
- `pregnancy-favorite-dishes.json` — 用户收藏菜品库

**用户记忆系统**：用户偏好和背景信息存储在 `~/.claude/projects/-Users-ningningmao-Documents-ai-project-20260519-skills/memory/`，参考 pregnancy-meal-planner.md 获取 skill 规范。

### usb-mac-recovery（v1.0）
macOS 拒挂 USB 存储时的零数据丢失恢复助手。

**触发条件**：U 盘在 `diskutil list` 可见但 `Mounted: No`，同盘在 Windows/Android/Linux 能读
**安全红线**：原盘零写入，所有操作在 `dd` 备份的 `.img` 副本上
**5 阶段流程**：诊断 → 备份 → 跨设备验证 → 修复 → 软件提取
**关键技术**：pyfatfs 失败时降级到手写 FAT32 解析器（playbook.md 第 6 节有完整代码）

## 常用操作

### 推送更新到 GitHub
```bash
# 获取当前 SHA
gh api repos/cstdr/royding-skills/contents/<path> -q '.sha'

# 上传/更新文件（需要 content 做 base64 编码）
gh api repos/cstdr/royding-skills/contents/<path> \
  -X PUT \
  -f message="commit message" \
  -f content="$(base64 -i <file>)" \
  -f sha="<sha>"
```

### 获取远程文件
```bash
gh api repos/cstdr/royding-skills/contents/<path> --jq '.content' | base64 -d
```

### 列出远程目录
```bash
gh api repos/cstdr/royding-skills/contents/<dir> --jq '.[].name'
```

## Skill 开发规范（agentskills.io + CONTRIBUTING.md）

### agentskills.io 规范要点

**SKILL.md 必须包含 YAML frontmatter + Markdown body。**

**frontmatter 字段要求：**

| 字段 | 约束 |
|------|------|
| `name` | 最多64字符，只含小写字母/数字/连字符，不能以连字符开头或结尾，不能有连续 `--` |
| `description` | 最多1024字符，描述"做什么"和"何时用"，应包含关键词帮助 agent 发现 |
| `license` | 可选，简短 |
| `compatibility` | 可选，最多500字符，说明环境要求 |
| `metadata` | 可选，键值对 |
| `allowed-tools` | 可选，实验性，预批准工具列表 |

**SKILL.md body：**
- 建议 < 500 行，body token 建议 < 5000
- 详细参考文档拆分到 `references/` 目录，按需加载
- 文件引用保持一层嵌套，避免深层链

**渐进加载机制（progressive disclosure）：**
1. 启动时只加载 `name` + `description`（~100 token）用于发现
2. skill 被激活时加载完整 SKILL.md body
3. 脚本/参考资料按需加载

### CONTRIBUTING.md 补充规则

- 目录名和 SKILL.md 文件名一致，全部小写，用连字符分隔
- `description` 必须以 "Use when" 开头，只写触发条件，不写操作流程
- 新 skill 必须经过压力测试才能合并
- 测试记录留在 conversation 里，不需要单独文件

## 快速参考：pregnancy-meal-planner 核心机制

**阶段自动检测**（根据 currentWeek 计算）：
- 备孕 → 孕早期(1-12周) → 孕中期(13-27周) → 孕晚期(≥28周) → 月子期

**循证原则**：主动纠错伪科学（骨头汤补钙、红枣补血等），所有推荐基于可靠营养数据

**待办任务**（见 TaskList）：
1. 支持周维度计划输出格式
2. 孕晚期饮水量监控提醒
3. 碘来源食材补充
4. 胆碱来源具体食材表

## 快速参考：usb-mac-recovery 核心机制

**5 阶段流程**（任一阶段失败可跳到阶段 5）：
1. 诊断（只读）— `diskutil info` 看 `Volume Total Space`、`File System Personality`
2. 备份 — 用户终端 `sudo dd if=/dev/diskX of=/tmp/disk.img bs=1m conv=noerror,sync`
3. 跨设备验证（关键拐点）— 任一非 Mac 设备能读 = 数据完整
4. 在 `.img` 上 fsck 修复 — `hdiutil attach -nomount` + `diskutil repairVolume`
5. 软件层自救 — pyfatfs / 手写 FAT32 解析器

**macOS 驱动特殊性**：`msdosfs.kext` 比 BSD `fsck_msdos` / Android `vfat` / Linux `vfat` 都严格；macOS 拒绝 ≠ 卷坏了

**测试记录**：用户 2 GB FAT32 U 盘在 Mac 拒挂、Android 电视能读场景下实战验证，8 mp4 + 24 jpg 全部成功提取，零数据丢失
