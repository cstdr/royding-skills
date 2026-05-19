# Contributing to Royding Skills

欢迎提交 Issue 和 PR。

## Skill 开发规范

### 命名
- 目录名和 SKILL.md 文件名一致
- 全部小写，用连字符分隔

### SKILL.md 结构
```
---
name: skill-name
description: Use when [触发条件，描述用户场景]
---
```

description 字段要求：
- 以 "Use when" 开头
- 只写触发条件，不写 skill 的操作流程
- 描述用户场景，不是功能说明

### 测试
- 新 skill 必须经过压力测试才能合并
- 测试记录留在 conversation 里，不需要单独文件

## 问题反馈

有 bug 或功能建议，先开 Issue 讨论。
