# Royding Skills

Personal AI Agent Skills.

[中文](./README.md)

<p align="left">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/cstdr/royding-skills?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/github/last-commit/cstdr/royding-skills?style=flat-square" alt="Last commit">
  <img src="https://img.shields.io/badge/skills-3-7c3aed?style=flat-square" alt="Skills">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square" alt="PRs welcome">
</p>

## Skills

| Skill | Purpose | Use case | Install |
| --- | --- | --- | --- |
| `pregnancy-meal-planner` | Pregnancy daily meal plan + grocery list + nutrition mapping | "What should I eat tomorrow?" / weekly menu planning | `Help me install this skill: https://github.com/cstdr/royding-skills/pregnancy-meal-planner` |
| `usb-mac-recovery` | Zero-data-loss recovery when macOS refuses to mount a USB drive | "Mac won't read my USB" / grey drive / `Invalid argument` | `Help me install this skill: https://github.com/cstdr/royding-skills/usb-mac-recovery` |
| `github-repo-polish` | Polish a "runs locally but feels half-baked" repo into a "professionally maintained" public release (9 stages + 4 scripts) | "I'm open-sourcing this" / "preparing for public release" / "my commit history is a mess" | `Help me install this skill: https://github.com/cstdr/royding-skills/github-repo-polish` |

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

**How to trigger:**
```
What should I eat tomorrow?
Help me plan this week's menu
Add this dish to my menu library
I'm craving something sour
Update my pregnancy status
```

**Install:**
```
Help me install this skill: https://github.com/cstdr/royding-skills/pregnancy-meal-planner
```

**Nutrients covered:** Folate, Iron, Calcium, DHA, Iodine, Vitamin D, Choline, Zinc

**Safety screening:** Auto-excludes raw meat, high-mercury fish, alcohol, unpasteurized dairy

**Platform support:**

![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-D97706?style=flat-square&logo=anthropic&logoColor=white)
![Codex](https://img.shields.io/badge/Codex-Skill-10B981?style=flat-square&logo=openai&logoColor=white)
![OpenCode](https://img.shields.io/badge/OpenCode-Skill-3B82F6?style=flat-square)
![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8B5CF6?style=flat-square)

### usb-mac-recovery

**Read-only emergency data recovery** when macOS refuses to mount a USB drive. When `diskutil` sees the device but won't mount it (`Invalid argument` / `Volume Total Space: 0 B` / grey in Finder), and the same device reads fine on Windows / Android / Linux, this skill extracts files from a `dd` backup `.img` with **zero data loss**.

**What it solves:**
- macOS reports `Invalid argument` / `not mounted` / `Volume Total Space: 0 B`
- Cross-device works (TV/Windows/Linux) but Mac won't read it
- `fsck_msdos` exits 0 but `mount` fails (macOS driver is stricter than BSD `fsck`)
- Confusion about whether to `dd` backup or just run `fsck_msdos -y`

**Core features:**

| Feature | Description |
|---------|-------------|
| 5-stage read-only flow | Diagnose → backup → cross-device verify → repair → software extract |
| Zero-write guarantee | All repair/extract on `.img` copy; original disk untouched after `dd` backup |
| Cross-device pivot | Android/Windows/Linux test decides fsck vs software-extract path |
| pyfatfs + hand-rolled FAT32 parser | Falls back to manual BPB + FAT-chain traversal when pyfatfs fails |
| Failure-mode cheat sheet | `Permission denied` / `(NO WRITE)` / "exit 0 ≠ success" and 7+ more |

**How to trigger:**
```
Mac doesn't read my USB drive
USB drive won't mount
diskutil sees the drive but Mounted: No
Invalid argument error
Grey USB drive in Finder
USB plays on TV but not on Mac
I can't lose any data
```

**Install:**
```
Help me install this skill: https://github.com/cstdr/royding-skills/usb-mac-recovery
```

**Safety red lines** (never write to the original disk):
- ⚠️ Never run `fsck_msdos -y` / `diskutil eraseDisk` / `diskutil repairVolume` on the original disk
- ⚠️ Never `dd` write to the original disk (`of=` must be a file, not a device)
- ⚠️ All repair/extract happens on the `.img` copy
- ⚠️ `mountDisk` exit code 0 ≠ actually mounted; verify with `mount` / `ls /Volumes/`

**Platform support:**

![macOS](https://img.shields.io/badge/macOS-Skill-000000?style=flat-square&logo=apple&logoColor=white)

### github-repo-polish

Polish a "runs locally but feels half-baked" repo into a "professionally maintained" public release. 9-stage workflow + 4 automated check scripts.

**Problems it solves:**
- README is still the default `# Project Name`, no idea where to start
- Commit history full of `asdf` / `WIP` / `tmp`
- Accidentally committed `.env` / API key to git
- Want to add CI / Issue templates but don't know what standard to follow

**9-stage workflow:**
- Stage 0: collect "why I built this" (anti-AI-tell, must come from author)
- Stage 1: privacy audit (gitleaks + git-filter-repo)
- Stage 2: repo skeleton (.gitignore / LICENSE / structure)
- Stage 3: commit history (conventional commits)
- Stage 4: 7-section README architecture
- Stage 5: .github/ engineering (Issue templates + CI)
- Stage 6: screenshots / GIF / arch diagrams
- Stage 7: personal info + human touch
- Stage 8: pre-publish automated checklist

**Install:**
```
Help me install this skill: https://github.com/cstdr/royding-skills/github-repo-polish
```

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

---

## 🔬 Development Methodology

This skill was built with TDD (Test-Driven Development):

1. **RED** — Run the agent without the skill, document all failure patterns
2. **GREEN** — Write skill rules targeting each specific failure
3. **REFACTOR** — Pressure-test with time pressure, conflicting conditions, format drift, and profile-skip attempts; patch holes iteratively

Pressure tests cover: time pressure, dietary restriction conflicts, format compliance, and defense against profile-skip shortcuts.

---

⚠️ **Disclaimer**: This skill provides nutrition reference only, not medical advice. Follow your doctor's guidance for any dietary changes during pregnancy. Consult a healthcare provider for any concerns.
