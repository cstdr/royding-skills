# Royding Skills

Personal AI Agent Skills.

[中文](./README.md)

## Skills

### pregnancy-meal-planner

Night-before pregnancy meal planner. Daily meal plans, grocery lists, and prenatal nutrition mapping.

**What it solves:**
- No more daily "what should I eat" mental load
- Trimester-specific nutrition needs handled automatically
- 2-3 weeks of variety, no repeated main dishes
- Clear visibility into whether nutrition targets are being met

**Core features:**

| Feature | Description |
|---------|-------------|
| User profile | Trimester, due date, taste preferences, allergies, doctor notes |
| Daily plan | 3 meals + snacks, each dish mapped to prenatal nutrients |
| Grocery list | Organized by produce / meat / dairy / grains / fruit |
| History tracking | Rolling 3-week log, no major repeats |
| Personal dish library | Add favorites anytime, auto-prioritized in future plans |
| 6 life phases | Auto-detects: preparing/pregnancy(1st/2nd/3rd trimester)/postpartum/normal |
| Medical conditions | Gestational diabetes→lowGI / Anemia→iron boost / Weight→low-oil |

**⚕️ Evidence-Based Medicine (EBM) Principle:**
- All dish recommendations backed by reliable nutrition data (USDA/Nutrients database)
- Proactively debunks myths: bone soup for calcium, red dates for iron, "shape-to-organ" folk logic
- Real nutrient data with absorption rate comparisons (heme iron vs non-heme iron)

**How to trigger:**
```
明天吃什么？
帮我规划这周菜单
把这个菜加到菜单库
我想吃酸的
更新一下孕期状态
```

**Install:**
```
帮我安装这个 skill：https://github.com/cstdr/royding-skills/pregnancy-meal-planner
```

**Nutrients covered:** Folate (from dark leafy greens, not tomatoes), Iron (heme-first: liver/blood/red meat), Calcium (dairy/tofu/sesame, not bone broth), DHA, Iodine, Vitamin D, Choline, Zinc

**Safety screening:** Auto-excludes raw meat, high-mercury fish, alcohol, unpasteurized dairy

**Myth-busting — proactive corrections:**

| ❌ Myth | ✅ Correct |
|--------|-----------|
| Bone broth for calcium | Dairy, tofu, sesame |
| Red dates/sugar for iron | Animal blood, liver, red meat |
| Tomatoes for folate | Dark leafy greens (20x denser) |
| "Drink soup, skip meat" | Eat the meat, soup is optional |

**Platform support:**

![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-D97706?style=flat-square&logo=anthropic&logoColor=white)
![Codex](https://img.shields.io/badge/Codex-Skill-10B981?style=flat-square&logo=openai&logoColor=white)
![OpenCode](https://img.shields.io/badge/OpenCode-Skill-3B82F6?style=flat-square)
![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8B5CF6?style=flat-square)

---

## 📐 Architecture

Data files live under `$PREGNANCY_SKILL_DIR`.

**File structure:**
```
$PREGNANCY_SKILL_DIR/
├── pregnancy-profile.json        # User state
├── pregnancy-meal-history.json  # 3-week rolling history
└── pregnancy-favorite-dishes.json # Personal dish library
```

**profile (user state):**
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

**history:**
```json
{
  "history": [
    { "weekOf": "2026-W20", "days": { "monday": { "breakfast": "..." } } }
  ]
}
```
Only the most recent 3 weeks are kept; older data is pruned automatically.

**dishes:**
```json
{ "dishes": [{ "name": "Tomato Beef", "category": "dinner", "added": "2026-05-10" }] }
```

---

## 🔧 Design Notes

**Why JSON instead of a database?**

Agents natively read/write local files. JSON is lightweight, requires no dependencies, and the data volume here is trivial — O(n) lookups are negligible in practice. Adding a database would only increase deployment complexity.

**Why "check history" instead of "build a menu pool"?**

A menu pool requires pre-maintaining a large dish database, takes significant effort to keep fresh, and can't adapt to changing preferences. The history approach uses actual consumption data — "what you ate before determines what you won't eat next." It's more accurate with zero maintenance overhead.

**Why phase differentiation driven by profile instead of hardcoded?**

There are 6 life phases (preparing/1st/2nd/3rd trimester/postpartum/normal). Phase changes over time. Hardcoding in the prompt means updating the skill every time. Profile-driven logic means the agent auto-calculates current phase from `currentWeek`, `isPlanningPregnancy`, and `postpartumWeek` — the skill itself stays stable.

**Why emphasize Evidence-Based Medicine?**

Pregnancy nutrition is riddled with pseudoscience — bone broth for calcium, red dates for iron, "eat shape for shape" folk logic. This skill proactively debunks these myths and backs every recommendation with real nutrient data, so bad nutrition advice doesn't reach pregnant users.

---

## 🔬 Development Methodology

This skill was built with TDD (Test-Driven Development):

1. **RED** — Run the agent without the skill, document all failure patterns
2. **GREEN** — Write skill rules targeting each specific failure
3. **REFACTOR** — Pressure-test with time pressure, conflicting conditions, format drift, and profile-skip attempts; patch holes iteratively

Pressure tests cover: time pressure, dietary restriction conflicts, format compliance, and defense against profile-skip shortcuts.

---

⚠️ **Disclaimer**: This skill provides nutrition reference only, not medical advice. Follow your doctor's guidance for any dietary changes during pregnancy. Consult a healthcare provider for any concerns.
