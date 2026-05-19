# Royding Skills

个人 AI Agent Skills 仓库。

## Skills

### pregnancy-meal-planner

孕期食谱助手。每天晚上生成明日饮食计划 + 采购清单 + 营养映射。

**解决的问题：**
- 每天不用自己想"吃什么"
- 孕早/中/晚期营养重点不同，不用自己算
- 2-3 周不重样，不用担心吃腻
- 营养够不够有参照，不用猜

**核心功能：**

| 功能 | 说明 |
|------|------|
| 用户状态 | 孕周、预产期、口味偏好、过敏/忌口、医生建议 |
| 每日计划 | 三餐+加餐，每道菜对应孕期营养 |
| 采购清单 | 按蔬菜/肉类/蛋奶/谷物/水果分组 |
| 历史查重 | 滚动保留 3 周记录，主菜不重复 |
| 个人菜品库 | 喜欢吃什么随时加，优先排入计划 |
| 孕周适配 | 孕早期止吐/孕中期铁钙DHA/孕晚期控盐防水肿 |
| 特殊情况 | 妊娠糖尿病→控糖、贫血→补铁、增重过快→控油 |

**支持的触发方式：**
```
明天吃什么？
帮我规划这周菜单
把这个菜加到菜单库
我想吃酸的
更新一下孕期状态
```

**安装：**
```
帮我安装这个 skill：https://github.com/cstdr/royding-skills/pregnancy-meal-planner
```

**覆盖的营养素：** 叶酸、铁、钙、DHA、碘、维生素D、胆碱、锌

**禁忌检查：** 自动排除生肉、高汞鱼、酒精、未经巴氏消毒的奶酪等孕期危险食物

**平台支持：**

![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-D97706?style=flat-square&logo=anthropic&logoColor=white)
![Codex](https://img.shields.io/badge/Codex-Skill-10B981?style=flat-square&logo=openai&logoColor=white)
![OpenCode](https://img.shields.io/badge/OpenCode-Skill-3B82F6?style=flat-square)
![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8B5CF6?style=flat-square)

---

⚠️ **免责声明**：本 skill 仅供营养参考，不构成医疗建议。孕期饮食调整请谨遵产检医生指示，有任何异常或疑虑应及时就医。
