---
name: usb-mac-recovery
description: Use when a USB drive is recognized by macOS diskutil but does not mount (shows `Invalid argument`, `not mounted`, `Volume Total Space: 0 B`, BPB reports FAT32 but Personality says FAT16, or appears grey in Finder), and the same device is readable on Windows / Android TV / Linux, and the user has explicitly said data must not be lost.
metadata:
  tested-on: macOS Ventura 13.x
  recovery-result: 8 mp4 + 24 jpg recovered, 0 loss
---

# USB-Mac Recovery

> **Tested on macOS Ventura 13.x.** Newer versions (Sonoma/Sequoia) have minor `diskutil` output field renames but core commands unchanged.

Mac 上 USB 存储"被识别但不挂载"时的**只读应急数据恢复**流程。
专为"绝不能丢数据"的场景设计——所有修复操作在 `.img` 副本上进行，**原盘零写入**。

## ⚠️ 核心安全红线

- **绝不**在原盘上跑写模式 `mount`
- **绝不**在原盘上跑 `fsck_msdos -y`（先用 `-n` 试）
- **绝不**在原盘上跑 `diskutil eraseDisk` / `repairDisk` / `repairVolume`
- **绝不**用 `dd if=/dev/diskX ...` 写原盘（`dd` 默认只读，但确认 `of=` 是文件不是设备）
- 所有修复 / 提取操作在 `.img` 副本上进行
- 每步操作前向用户**解释做什么 + 为什么不动原盘**
- **macOS 的 `msdosfs.kext` 比 BSD `fsck_msdos`、Android `vfat`、Linux `vfat` 都严格**——它拒绝 ≠ 卷坏了。这是 macOS 较真的保护机制，**不是 bug**。

## When NOT to use

- U 盘在 `diskutil list` 中**完全不见**（物理/线缆/接口问题，不在 skill 范围）
- 数据不重要 / 用户愿意格式化
- 卷是 APFS / exFAT / HFS+（非 FAT，本 skill 范围外）
- 用户能接受 macOS 第三方 GUI 工具（Disk Drill / TestDisk / R-Studio）

## 决策树（看用户说什么 → 走哪条路径）

| 用户表述 / 信号 | 路径 |
|----------|------|
| "Mac 完全看不到 U 盘"（连 `diskutil list` 都没有） | 阶段 1 诊断 → 物理/接口问题，**本 skill 范围外**，建议换线缆/口/电脑 |
| "Mac 看到盘但不识别/不挂载/灰盘" | **本 skill 主场景** → 阶段 1 → 2 → 3 |
| "提示 Invalid argument" / "not mounted" / "卷大小 0 B" | 阶段 1 → 2 → 3（BPB 元数据问题，常见） |
| "Mac 读不出，但电视/Windows/Linux 能读" | **阶段 3 跨设备验证优先**（关键拐点） |
| "U 盘没数据 / 可格式化" | 提醒：先 `dd` 备份（万一），再格式化 |
| 卷标含 `IMG` / `USB` / `RECOVERY` / `DISK` 等关键词 | 提示"可能是镜像写盘"——阶段 1 看 `diskutil info` 的 `Volume Name` 字段 |

## 5 阶段流程

### 阶段 1：诊断（只读，绝不动盘）

```bash
diskutil list                              # 找 /dev/diskX
diskutil info /dev/diskXs1                 # 看 Mounted / File System / Volume Total Space
mount | grep diskX                         # 确认是否已挂载
system_profiler SPUSBDataType | head -80   # 看 USB 协议层（沙盒里可能为空）
```

**判断**：

| 现象 | 结论 | 下一步 |
|------|------|--------|
| `Mounted: No` + `File System: None` | 真没文件系统 | 跳"建议重新格式化"分支（不在本 skill） |
| `Mounted: No` + `File System: MS-DOS (FAT16/FAT32)` + `Volume Total Space: 0 B` | **BPB 元数据问题，本 skill 主场景** | 阶段 2 |
| 设备在 `diskutil list` 但 `info` 报 I/O 错误 | 物理层坏 | 跳物理恢复 |
| 设备完全不在 `diskutil list` | 接口/线缆/供电问题 | 跳物理层 |

**绝对不要在阶段 1 跑任何 `mount`/`fsck`/`repairDisk`**——只读就行。

### 阶段 2：安全备份原盘（用户终端 sudo）

在 trae 沙盒里 `sudo dd /dev/diskX` 会被 `Permission denied`（沙盒没 raw 设备权限）。让用户在**自己的终端**跑：

```bash
sudo dd if=/dev/disk8 of=/tmp/disk.img bs=1m conv=noerror,sync status=progress
ls -lh /tmp/disk.img
shasum -a 256 /tmp/disk.img
```

**易错点**（踩过）：
- `~` 解析问题：用**绝对路径** `/tmp/disk.img` 或 `cd ~/Desktop && dd ... of=./disk.img`
- 命令断行：zsh 行尾空格 + 换行 = 命令分隔符。一行写下整条命令
- 跑时**别拔盘**

跑完继续。

### 阶段 3：跨设备验证（关键拐点）

> **这一步决定后续走 fsck 修复还是软件自救**。

让用户把 U 盘插到**任一非 Mac 设备**（Android 手机 + OTG、电视盒子、Windows、Linux live U 盘）：

- **能读** → 数据完整，卷结构合法，**问题在 macOS 驱动**。直接跳阶段 5 软件提取
- **不能读** → 卷结构可能真坏了，尝试阶段 4 在 `.img` 上修复后再进阶段 5

**跳过这步而直接 fsck 修复，容易在损坏的卷上做无效操作浪费时间**。

### 阶段 4：在 `.img` 副本上尝试修复

```bash
# 把镜像当 raw 设备 attach
hdiutil attach -nomount /tmp/disk.img    # 返回 /dev/diskN
diskutil info diskNs1                    # 看 metadata
diskutil repairVolume diskNs1            # 调 fsck_msdos -y
mount -t msdos -o rdonly /dev/diskNs1 /tmp/mnt_usb
ls /tmp/mnt_usb
```

**如果仍报 `Invalid argument` (errno 71)** → BPB 字段被 macOS msdosfs 拒绝，转阶段 5。

**如果 `fsck_msdos` 报 `(NO WRITE)`** → hdiutil 默认只读 attach，转阶段 5（最稳）。

### 阶段 5：软件层自救（pyfatfs 或手写 FAT 解析器）

不走 macOS 内核 msdosfs 驱动，直接用 Python 解析 FAT 表、提取文件。

#### 5a. pyfatfs（新版 API）

```bash
pip3 install --user pyfatfs
```

```python
# 新版有 open_fs（走 PyFilesystem2）
from pyfatfs import open_fs
fs = open_fs('fat:///tmp/disk.img?offset=32768')
for entry in fs.listdir('/'):
    print(entry)
```

#### 5b. pyfatfs 老 API（1.1.0）

无 `open_fs`、无 `read_data_from_cluster`，用底层方法：
```python
from pyfatfs.PyFat import PyFat
fs = PyFat(offset=32768)
fs.open('/tmp/disk.img', read_only=True)
fs.parse_header()
entries = fs.parse_root_dir()
```

#### 5c. 备选：手写 FAT32 解析器

适用 pyfatfs 装不上 / 解析失败场景。完整代码在 `references/playbook.md` 末尾**附录 A**。

关键点（详见 `references/playbook.md` **附录 B**）：
- 簇号 → 物理字节偏移：`part_offset + (reserved + num_fats × spf + (cluster-2) × spc) × bytes_per_sector`
- LFN 拼接：seq=1 对应 chars 1-13，seq=2 对应 chars 14-26，**升序拼接**
- FAT 表读链：簇号 × 4 偏移读 4 字节 LE，`& 0x0FFFFFFF`，≥ 0x0FFFFFF8 为 EOC

## 收尾

1. **验证提取文件**：`file *.mp4`、`file *.jpg`，确认是合法 ISO Media / JPEG
2. 告知：原盘 `/dev/diskX` **一字节没动**
3. 告知：U 盘以后**插 Mac 仍会拒读**（驱动问题，卷本身没坏）。要么换设备读，要么备份后重新格式化
4. 清理：`rm /tmp/disk.img`、`rm ~/Desktop/disk_work.img`（如果不再需要）

## 已知失败模式速查

| 现象 | 原因 | 解法 |
|------|------|------|
| `dd: /dev/diskX: Permission denied` | 沙盒无 raw 设备权限 | 让用户在**自己终端**跑 `sudo dd` |
| `dd: ~/Desktop/xxx.img: No such file or directory` | 命令断行 / `~` 没展开 | 用绝对路径 `/tmp/...`，或 `cd ~/Desktop && dd ... of=./xxx.img` |
| `diskutil mountDisk readOnly` 报"成功"但 `/Volumes/` 没出现 | 退出码 0 不代表真成功 | 用 `mount` / `ls /Volumes/` 验证 |
| `mount -t msdos` 报 `Invalid argument` (errno 71) | BPB 字段被 macOS msdosfs 拒绝 | 阶段 5 |
| `fsck_msdos -y` 报 `(NO WRITE)` | hdiutil 默认只读 attach | 备份后改 `fsck_msdos -y -f`，或转阶段 5 |
| `pyfatfs` `listdir` 不存在 | 老 API | 用 `parse_root_dir()` / `parse_dir_entries_in_cluster_chain()` |
| LFN 拼接反了 | seq 排序错 | 升序拼接（seq=1 先） |
| `fsck_msdos -n` 报"无错误"但 `mount` 失败 | fsck 比 mount 宽松 | 阶段 5（不要相信 fsck 报 0） |
| SIP 全开 + recovery 模式下 `/dev/diskX` 访问受限 | macOS 系统完整性保护 | 进 normal 模式再操作 |
| TCC 弹窗（首次插入） | macOS 隐私保护要求 Finder 授权 | 在「系统设置 → 隐私与安全性 → 文件与文件夹」批准 |
| `diskutil info` 字段名变化 | macOS 13→14→15 字段重命名（如 Sequoia 把 `File System Personality` 改名 `Type (Bundle)`） | 字段含义不变，按输出值判断 |

## 速查视图

```
用户说"Mac 不读 U 盘"
    ↓
阶段 1：diskutil 诊断（只读）
    ↓
设备出现但 not mounted？
    ↓ yes
阶段 2：sudo dd 备份（用户终端）
    ↓
阶段 3：跨设备验证（Android/电视/Windows）
    ↓
    ├── 能读 ──→ 阶段 5 软件提取（绕过 macOS 驱动）
    │
    └── 不能读 → 阶段 4：fsck 修复 .img 副本
                 ↓
              仍不行 → 阶段 5
```

## 参考

- `references/playbook.md` — 实战长文：完整命令、踩坑、Python 解析器代码（**附录 A**）、BPB 字段速查表（**附录 B**）
