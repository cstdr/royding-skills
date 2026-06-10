# Royding Skills

个人 AI Agent Skills 仓库。

[English](./README.en.md)

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
| 6 阶段自动适配 | 备孕/孕早/孕中/孕晚/月子/正常，自动切换配餐策略 |
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

### usb-mac-recovery

macOS 拒挂 USB 存储时的**只读应急数据恢复**助手。当 `diskutil` 看到盘但不挂载（`Invalid argument` / `Volume Total Space: 0 B` / 灰盘），且同盘在 Windows / Android / Linux 能读时，从 `dd` 备份的 `.img` 副本里零数据丢失地提取文件。

**解决的问题：**
- macOS 报 `Invalid argument` / `not mounted` / `Volume Total Space: 0 B`
- 跨设备（电视/Windows/Linux）能读但 Mac 不读
- `fsck_msdos` 退出码 0 但 `mount` 失败（macOS 驱动比 BSD `fsck` 严格）
- 不知道该 `dd` 备份还是直接 `fsck_msdos -y`

**核心功能：**

| 功能 | 说明 |
|------|------|
| 5 阶段只读流程 | 诊断 → 备份 → 跨设备验证 → 修复 → 软件提取 |
| 零写入保证 | 所有修复/提取在 `.img` 副本上，原盘 `dd` 备份后一字节不动 |
| 跨设备拐点判断 | Android/Windows/Linux 验证决定走 fsck 还是软件提取 |
| pyfatfs + 手写 FAT32 解析器 | pyfatfs 失败时降级到 BPB 字段手算 + FAT 链追踪 |
| 失败模式速查表 | `Permission denied` / `(NO WRITE)` / 退出码 0 ≠ 成功 等 7+ 坑 |

**支持的触发方式：**
```
Mac 不读 U 盘
U 盘插上不挂载
diskutil 看到盘但 Mounted: No
提示 Invalid argument
Mac 灰盘
U 盘在电视能放但 Mac 不能
数据丢了不能接受
```

**安装：**
```
帮我安装这个 skill：https://github.com/cstdr/royding-skills/usb-mac-recovery
```

**安全红线**（绝不动原盘）：
- ⚠️ 绝不在原盘上跑 `fsck_msdos -y` / `diskutil eraseDisk` / `diskutil repairVolume`
- ⚠️ 绝不用 `dd` 写原盘（`of=` 必须是文件不是设备）
- ⚠️ 所有修复/提取在 `.img` 副本上执行
- ⚠️ `mountDisk` 退出码 0 ≠ 真挂载，必须用 `mount` / `ls /Volumes/` 验证

**平台支持：**

![macOS](https://img.shields.io/badge/macOS-Skill-000000?style=flat-square&logo=apple&logoColor=white)

---

## 📐 Architecture

数据文件存储在 `$PREGNANCY_SKILL_DIR` 指向的目录下。

**文件结构：**
```
$PREGNANCY_SKILL_DIR/
├── pregnancy-profile.json        # 用户状态
├── pregnancy-meal-history.json  # 3 周历史记录
└── pregnancy-favorite-dishes.json # 个人菜品库
```

**profile（用户状态）：**
```json
{
  "currentWeek": 20,
  "dueDate": "2026-09-15",
  "isPlanningPregnancy": false,
  "postpartumWeek": null,
  "preferences": { "likes": [], "dislikes": [] },
  "doctorAdvice": { "gestationalDiabetes": false, "anemia": false }
}
```

**history（历史记录）：**
```json
{
  "history": [
    { "weekOf": "2026-W20", "days": { "monday": { "breakfast": "..." } } }
  ]
}
```
只保留最近 3 周，超出自动删除。

**dishes（菜品库）：**
```json
{ "dishes": [{ "name": "番茄牛腩", "category": "dinner", "added": "2026-05-10" }] }
```

---

## 🔧 Design Notes

**为什么用 JSON 文件而不是数据库？**

Agent 的核心能力是读写本地文件，JSON 足够轻量且无需额外依赖。孕期状态数据量极小，JSON 的查询成本（O(n)）在实际使用中可忽略。引入数据库只会增加部署复杂度。

**为什么不重复的策略是"查历史"而不是"建菜单库"？**

菜单库的问题是：需要预先维护大量菜品，准备时间长，且无法适应用户口味变化。查历史的方案核心思路是"你实际吃过什么"来决定"下次不吃什么"——数据来源于真实消费记录，比预设菜单库更准确，也省去了维护成本。

**为什么差异化靠 profile 驱动而不是写死？**

孕期分 6 个阶段（备孕/孕早/孕中/孕晚/月子/正常），阶段是动态变化的。写死在 prompt 里会导致每次都要改 skill。而 profile 驱动让 agent 自动根据 `currentWeek`、`isPlanningPregnancy`、`postpartumWeek` 计算当前阶段，skill 本身保持稳定。

---

## 🔬 开发方法论

本 skill 采用 TDD（测试驱动开发）流程：

1. **RED** — 不加 skill，让 agent 自由发挥，记录问题
2. **GREEN** — 针对具体问题写 skill 规则
3. **REFACTOR** — agent 在压力场景下（时间紧迫/多条件冲突/格式漂移）暴露新漏洞，持续补强

压力测试覆盖：时间压力、禁忌冲突、格式遵守、profile 跳过的防御机制。

---

⚠️ **免责声明**：本 skill 仅供营养参考，不构成医疗建议。孕期饮食调整请谨遵产检医生指示，有任何异常或疑虑应及时就医。
