# Playbook — USB-Mac Recovery 实战长文

SKILL.md 给了流程骨架，这篇是**实战细节**——把每个坑、每条命令的来龙去脉、为什么这么做写清楚。读 SKILL.md 之后如果哪里还模糊，看这里。

## 1. 案例背景

- 用户 U 盘：2 GB，FAT32 (MBR)，卷标 `DISK_IMG`（很可疑——典型 `dd` 写盘镜像或 Linux `mkfs.vfat -n` 产物）
- 现象：Mac 上 `diskutil list` 能看到 `/dev/disk8`，`diskutil info` 显示设备存在、卷元数据存在，但 `Mounted: No`
- 关键证据：Android 电视**能正常读取** U 盘
- 数据类型：小米电视/盒子 VolCine 投屏应用缓存的视频/图片（8 个 mp4 + 24 个 jpg 缩略图，共 20.6 MB）

## 2. 诊断阶段

### 关键命令

```bash
diskutil list
diskutil info /dev/disk8
diskutil info /dev/disk8s1
mount | grep disk
ls /Volumes/
```

### 关键判断

- `diskutil list` 看到 `/dev/disk8` → 硬件层 OK
- `diskutil info /dev/disk8s1`：
  - `Volume Name: DISK_IMG`
  - `Mounted: No`
  - `File System Personality: MS-DOS FAT16`（**注意**：BPB 写的是 FAT32，macOS 解析成 FAT16——这是个红旗）
  - **`Volume Total Space: 0 Bytes`、`Volume Free Space: 0 Bytes`** ← 关键：BPB 算出的卷大小是 0
- `mount | grep disk8` 无输出 → 没挂载
- `/Volumes/` 里没 `DISK_IMG` → Finder 看不到

### 错误尝试

**`diskutil mountDisk readOnly disk8`**：打印 "Volume(s) mounted successfully" 但**实际没挂**。
这是 macOS `mountDisk` 对 MBR 下卷的常见情况——`fsck_msdos`/内核 msdosfs 拒绝，命令退出码仍是 0。
**退出码 0 ≠ 成功**，必须用 `mount` 或 `ls /Volumes/` 验证。

**`mount -t msdos -o rdonly /dev/disk8s1 /tmp/mnt_usb`**：报
```
mount_msdos: /dev/disk8s1 on /private/tmp/mnt_usb: Invalid argument
mount: /private/tmp/mnt_usb failed with 71
```
errno 71 = EOPNOTSUPP / 参数无效。内核 msdosfs 驱动在 BPB 校验阶段直接拒。

**`fsck_msdos -n /dev/rdisk8s1`**：报**退出码 0**，73 个文件识别出来。
`fsck_msdos` 用 BSD libkvm/msdosfs 逻辑，对 BPB 校验比 mount 宽松。**不要因为 fsck 报 0 就以为卷 OK**——mount 不挂就是真不挂。

**`diskutil repairVolume`**：会调 `fsck_msdos -y`，但若 hdiutil 默认只读 attach，会出现 `(NO WRITE)` 警告，根本没真修。

## 3. 安全备份

### 沙盒里直接 dd 为什么失败

```
$ sudo dd if=/dev/disk8 of=~/Desktop/disk.img bs=1m conv=noerror,sync status=progress
dd: /dev/disk8: Permission denied
```

trae sandbox 没给 raw block device 读权限。`/dev/disk*` 在 macOS 上是 root 拥有 + TCC 保护。

### 正确做法：用户自己终端 sudo

打开 Mac 终端（不是 Trae 那个），跑：

```bash
sudo dd if=/dev/disk8 of=/tmp/disk.img bs=1m conv=noerror,sync status=progress
ls -lh /tmp/disk.img
shasum -a 256 /tmp/disk.img
```

#### 易错点 1：`~` 解析问题

如果用 `of=~/Desktop/disk.img`，在某些 shell 配置下会报 `No such file or directory`。
**最稳的写法**：用绝对路径 `/tmp/...`，或 `cd ~/Desktop && dd ... of=./disk.img`。

#### 易错点 2：命令断行

终端窗口窄时，长命令会视觉换行。如果复制时在行尾加了空格 + 换行，zsh 当作命令分隔符：
```bash
sudo dd if=/dev/disk8 of=/tmp/disk.i   # 末尾有空格
mg bs=1m ...                            # 这被当作第二条命令
```

**解决办法**：手动重新拼成一行，或者用反斜杠 `\` 续行（zsh 默认行为之一）。

#### 关键参数

- `bs=1m`：1 MB 块大小，速度快
- `conv=noerror,sync`：读到坏块不中断，用零补齐
- `status=progress`：macOS BSD dd 支持，实时显示进度

2 GB U 盘约 1-3 分钟。**跑时别拔盘**。

### 备份到桌面 vs /tmp

- `/tmp/`：macOS 不会清理，路径简单，绝对安全
- `~/Desktop/`：用户能看到，但默认是 iCloud 同步目录（如果开了 Desktop & Documents in iCloud）——可能慢

推荐 `/tmp/disk.img`。

## 4. 跨设备验证（最关键的拐点）

**为什么必须做这一步**：
- macOS 的 `msdosfs.kext` 比 BSD `fsck_msdos`、Android `vfat`、Linux `vfat` 都严格
- 它的拒绝**不等于**卷坏了
- 跨设备验证是最便宜的"假设检验"——能读 = 数据完整 = 直接走软件提取（跳过 fsck）；不能读 = 卷可能真坏了 = 走 fsck 修复

**做法**：把 U 盘拔到**任一非 Mac 设备**：
- Android 手机 + OTG 转接头
- 电视盒子
- Windows 电脑
- Linux live U 盘

只要有一个能读出来，就证明问题在 macOS 驱动。

## 5. 修复尝试（不一定需要）

如果跨设备验证失败，才走这一步。所有操作在 `/tmp/disk.img` 上，**原盘 `/dev/disk8` 完全不动**。

### hdiutil attach

```bash
hdiutil attach -nomount /tmp/disk.img
# 返回 /dev/diskN
```

`-nomount` = 不自动挂载（避免被 diskarbitration 干扰），但设备节点可用。

### 修卷

```bash
diskutil info diskNs1
diskutil repairVolume diskNs1
```

`diskutil repairVolume` 会调 `fsck_msdos -y`，可能修 BPB 等元数据。

**踩坑**：`fsck_msdos` 在 hdiutil 只读 attach 时会输出 `(NO WRITE)` 警告，根本没真修。解法：
- 不用 hdiutil attach，直接在镜像文件上跑 `fsck_msdos`——但这需要 `fsck_msdos` 能读 raw 文件
- 或者用 `hdiutil attach -nomount -readwrite`（不是所有 macOS 版本支持）
- 或者转阶段 5（最稳）

### 手动 mount

```bash
mount -t msdos -o rdonly /dev/diskNs1 /tmp/mnt_usb
ls /tmp/mnt_usb
```

绕过 diskarbitration，直接走 mount 系统调用。如果还报 `Invalid argument`，转阶段 5。

## 6. 软件层自救（核心：手写 FAT32 解析器）

macOS 内核 msdosfs 不读、diskutil 修不了、pyfatfs 装不上/不完整——自己写一个。

### 6a. 解析 BPB

从镜像偏移 `0x8000`（64 sectors × 512 = 32768，分区起点）读 512 字节引导扇区，提取关键字段：

```python
import struct

with open('/tmp/disk.img', 'rb') as f:
    f.seek(0x8000)
    bpb = f.read(512)

BPS      = struct.unpack('<H', bpb[0x0B:0x0D])[0]   # 512
SPC      = bpb[0x0D]                               # 64
RSD      = struct.unpack('<H', bpb[0x0E:0x10])[0]  # 32
NF       = bpb[0x10]                               # 2
SPF      = struct.unpack('<I', bpb[0x24:0x28])[0]  # 480 (FAT32)
TOTAL    = struct.unpack('<I', bpb[0x20:0x24])[0]
```

`ROOT_CL` 字段（0x2A-0x2D，4 字节 LE）**在坏卷里常是 0 或超大值**——macOS 看到这个值就直接拒。`fsck_msdos` 找不到根目录时会 fallback 到簇 2 自己找。

### 6b. 簇号 → 物理偏移

```python
CLUSTER_SIZE = SPC * BPS                              # 32 KB
DATA_REGION_OFFSET = (RSD + NF * SPF) * BPS           # FAT32 数据区起点

def cl_off(cluster):
    return 0x8000 + DATA_REGION_OFFSET + (cluster - 2) * CLUSTER_SIZE
```

### 6c. FAT 链读取

```python
def fat_entry(cluster):
    with open('/tmp/disk.img', 'rb') as f:
        f.seek(0x8000 + RSD * BPS + cluster * 4)
        return struct.unpack('<I', f.read(4))[0] & 0x0FFFFFFF
```

值 ≥ 0x0FFFFFF8 = EOC（链结束），值 = 0 = 空闲簇。

### 6d. 解析目录项

每个目录项 32 字节。短名 8.3 格式，长名用 LFN entry 链。

```python
ATTR_READ_ONLY = 0x01
ATTR_HIDDEN    = 0x02
ATTR_SYSTEM    = 0x04
ATTR_VOLUME_ID = 0x08
ATTR_DIRECTORY = 0x10
ATTR_ARCHIVE   = 0x20
ATTR_LFN       = 0x0F

def parse_short(e):
    name = e[0:8].decode('latin-1', errors='replace').rstrip()
    ext  = e[8:11].decode('latin-1', errors='replace').rstrip()
    attr = e[11]
    cluster_hi = struct.unpack('<H', e[20:22])[0]
    cluster_lo = struct.unpack('<H', e[26:28])[0]
    cluster = (cluster_hi << 16) | cluster_lo
    size = struct.unpack('<I', e[28:32])[0]
    return name, ext, attr, cluster, size
```

### 6e. LFN 解析（最容易出 bug 的地方）

LFN entry 32 字节，包含 13 个 UTF-16LE 字符：
- chars 1-5：偏移 1, 3, 5, 7, 9
- chars 6-11：偏移 14, 16, 18, 20, 22, 24
- chars 12-13：偏移 28, 30

```python
def parse_lfn_chars(e):
    offsets = [1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30]
    chars = []
    for off in offsets:
        c = struct.unpack('<H', e[off:off+2])[0]
        if c == 0:
            return ''.join(chars)        # 字符串结束
        if c == 0xFFFF:
            continue                     # 填充字符，跳过
        chars.append(chr(c))
    return ''.join(chars)
```

**关键**：FAT 规范下 `seq=1` 对应 chars 1-13，`seq=2` 对应 chars 14-26，**升序拼接**。搞反了名字就乱。

### 6f. 拼完整名

```python
lfn_parts = {}  # seq -> str

# 遍历目录 entry...
if attr == ATTR_LFN:
    seq = e[0] & 0x3F
    s = parse_lfn_chars(e)
    if s is not None:
        lfn_parts[seq] = s
    continue

# 遇到普通 entry，拼 LFN
if lfn_parts:
    seqs = sorted(lfn_parts.keys())  # 升序
    display = ''.join(lfn_parts[s] for s in seqs)
    lfn_parts.clear()
else:
    display = (name + ('.' + ext if ext else '')).strip()
```

### 6g. 读文件数据（按 FAT 链）

```python
def read_file_data(first_cluster, size):
    if first_cluster < 2:
        return b''
    out = bytearray()
    cluster = first_cluster
    seen = set()
    while 2 <= cluster < 0x0FFFFFF8 and len(out) < size and cluster not in seen:
        seen.add(cluster)
        with open('/tmp/disk.img', 'rb') as f:
            f.seek(cl_off(cluster))
            need = min(CLUSTER_SIZE, size - len(out))
            out += f.read(need)
        if len(out) >= size:
            break
        nxt = fat_entry(cluster)
        if nxt >= 0x0FFFFFF8:
            break
        cluster = nxt
    return bytes(out[:size])
```

### 6h. 完整脚本

见本文件末尾**附录 A**——整合 6a-6g 节的代码片段成可运行的单文件脚本。

## 7. 验证提取结果

```bash
for f in ~/Desktop/recovered/*.mp4; do
    echo "--- $(basename "$f") ---"
    file "$f"
done

file ~/Desktop/recovered/*.jpg | head -5
```

期望输出：
- `ISO Media, MP4 v2 [ISO 14496-14]` —— 合法 mp4
- `JPEG image data, JFIF standard 1.01, ..., 1136x852` —— 合法 jpg

如果 `file` 报 `data` 或 `ASCII text`，说明该文件提取出错（簇链走错或 size 字段错）。

## 8. 收尾清单

1. ✅ 提取文件能正常打开（mp4 用 QuickTime / VLC、jpg 用 Preview）
2. ✅ 告知用户：原盘 `/dev/disk8` 一字节没动
3. ✅ 告知：U 盘**插 Mac 仍会拒读**（驱动问题，卷本身没坏）。要么换设备读，要么备份后重新格式化
4. ✅ 清理：不需要的镜像副本删掉（`/tmp/disk.img` 留到用户确认无漏文件）

## 9. 这次没踩但可能踩的坑

- **卷标里有特殊字符**：BPB 0x47-0x51 是卷标字段，UTF-8 解析时可能乱码
- **目录循环引用**：子目录的 `..` 指向根目录的 `..`，递归时可能死循环。需要 `seen` set 去重
- **LFN checksum 不匹配**：FAT32 spec 规定 LFN 段的 checksum 必须匹配对应的短名 entry。如果不匹配，可能名字被搞乱
- **多语种 LFN**：UTF-16 LE 是标准，但实际遇到过 GBK 编码的 LFN（违规但 Windows 95 OSR2 早期版本写过）
- **删除文件恢复**：本 skill 假设文件是"活的"（FAT chain 完整）。删了的文件簇可能被覆盖，无法恢复

---

## 附录 A：完整 Python FAT32 解析器（可独立运行）

整合 6a-6g 节的所有代码片段。直接 `python3 fat32_extract.py /tmp/disk.img` 跑，把文件提取到 `~/Desktop/recovered/`。

```python
#!/usr/bin/env python3
"""FAT32 镜像解析器：从镜像里递归提取所有文件。"""
import os, struct, sys

# ---- 配置 ----
IMG   = sys.argv[1] if len(sys.argv) > 1 else '/tmp/disk.img'
OUT   = os.path.expanduser('~/Desktop/recovered')
PART_OFFSET = 0x8000  # 64 sectors × 512 = 32768

# ---- 解析 BPB ----
with open(IMG, 'rb') as f:
    f.seek(PART_OFFSET)
    bpb = f.read(512)

BPS   = struct.unpack('<H', bpb[0x0B:0x0D])[0]   # 512
SPC   = bpb[0x0D]                                # 64
RSD   = struct.unpack('<H', bpb[0x0E:0x10])[0]   # 32
NF    = bpb[0x10]                                # 2
SPF   = struct.unpack('<I', bpb[0x24:0x28])[0]   # 480 (FAT32)
TOTAL = struct.unpack('<I', bpb[0x20:0x24])[0]

CLUSTER_SIZE = SPC * BPS
FAT_OFFSET = RSD * BPS
DATA_REGION_OFFSET = (RSD + NF * SPF) * BPS

print(f'BPB: BPS={BPS} SPC={SPC} RSD={RSD} NF={NF} SPF={SPF} TOTAL={TOTAL}')

# ---- 簇号 ↔ 字节偏移 ----
def cl_off(cluster):
    return PART_OFFSET + DATA_REGION_OFFSET + (cluster - 2) * CLUSTER_SIZE

def fat_entry(cluster):
    with open(IMG, 'rb') as f:
        f.seek(PART_OFFSET + FAT_OFFSET + cluster * 4)
        return struct.unpack('<I', f.read(4))[0] & 0x0FFFFFFF

# ---- 解析目录项 ----
ATTR_READ_ONLY = 0x01
ATTR_HIDDEN    = 0x02
ATTR_SYSTEM    = 0x04
ATTR_VOLUME_ID = 0x08
ATTR_DIRECTORY = 0x10
ATTR_ARCHIVE   = 0x20
ATTR_LFN       = 0x0F

def parse_short(e):
    name = e[0:8].decode('latin-1', errors='replace').rstrip()
    ext  = e[8:11].decode('latin-1', errors='replace').rstrip()
    attr = e[11]
    cluster_hi = struct.unpack('<H', e[20:22])[0]
    cluster_lo = struct.unpack('<H', e[26:28])[0]
    cluster = (cluster_hi << 16) | cluster_lo
    size = struct.unpack('<I', e[28:32])[0]
    return name, ext, attr, cluster, size

def parse_lfn_chars(e):
    """LFN entry 13 个 UTF-16LE 字符，0=结束 0xFFFF=填充。"""
    offsets = [1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30]
    chars = []
    for off in offsets:
        c = struct.unpack('<H', e[off:off+2])[0]
        if c == 0:
            return ''.join(chars)
        if c == 0xFFFF:
            continue
        chars.append(chr(c))
    return ''.join(chars)

def read_clusters_chain(start):
    """按 FAT 链读连续簇数据。"""
    out = bytearray()
    cluster = start
    seen = set()
    while 2 <= cluster < 0x0FFFFFF8 and cluster not in seen:
        seen.add(cluster)
        with open(IMG, 'rb') as f:
            f.seek(cl_off(cluster))
            out += f.read(CLUSTER_SIZE)
        cluster = fat_entry(cluster)
    return bytes(out)

def list_dir(start_cluster):
    """返回 (display_name, attr, first_cluster, size) 列表。"""
    if start_cluster < 2:
        return []
    data = read_clusters_chain(start_cluster)
    entries = []
    lfn_parts = {}
    for i in range(0, len(data) - 31, 32):
        e = data[i:i+32]
        if e[0] == 0x00:
            break
        if e[0] == 0xE5:
            lfn_parts.clear()
            continue
        attr = e[11]
        if attr == ATTR_LFN:
            seq = e[0] & 0x3F
            s = parse_lfn_chars(e)
            if s is not None:
                lfn_parts[seq] = s
            continue
        name, ext, attr, cluster, size = parse_short(e)
        if attr & ATTR_VOLUME_ID:
            lfn_parts.clear()
            continue
        if lfn_parts:
            # FAT 规范：seq=1 对应 chars 1-13，seq=2 对应 chars 14-26，升序拼接
            seqs = sorted(lfn_parts.keys())
            display = ''.join(lfn_parts[s] for s in seqs)
            lfn_parts.clear()
        else:
            display = (name + ('.' + ext if ext else '')).strip()
        if not display:
            display = f'_unnamed_{cluster}'
        display = display.replace('/', '_').replace('\x00', '_').strip()
        entries.append((display, attr, cluster, size))
    return entries

def read_file_data(first_cluster, size):
    """按 FAT 链读 size 字节。"""
    if first_cluster < 2:
        return b''
    out = bytearray()
    cluster = first_cluster
    seen = set()
    while 2 <= cluster < 0x0FFFFFF8 and len(out) < size and cluster not in seen:
        seen.add(cluster)
        with open(IMG, 'rb') as f:
            f.seek(cl_off(cluster))
            need = min(CLUSTER_SIZE, size - len(out))
            out += f.read(need)
        if len(out) >= size:
            break
        nxt = fat_entry(cluster)
        if nxt >= 0x0FFFFFF8:
            break
        cluster = nxt
    return bytes(out[:size])

# ---- 递归提取 ----
import shutil
if os.path.exists(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT, exist_ok=True)

file_count = dir_count = total_bytes = 0
errors = []
all_files = []

def walk(start_cluster, rel):
    global file_count, dir_count, total_bytes
    if start_cluster < 2:
        return
    try:
        entries = list_dir(start_cluster)
    except Exception as ex:
        errors.append(f'LIST {rel}: {ex}')
        return
    for name, attr, cluster, size in entries:
        if name in ('.', '..'):
            continue
        full = (rel.rstrip('/') + '/' + name) if rel != '/' else '/' + name
        if attr & ATTR_DIRECTORY:
            dir_count += 1
            walk(cluster, full)
        elif attr & ATTR_VOLUME_ID:
            continue
        else:
            out_path = os.path.join(OUT, full.lstrip('/'))
            try:
                data = read_file_data(cluster, size)
                os.makedirs(os.path.dirname(out_path), exist_ok=True)
                with open(out_path, 'wb') as f:
                    f.write(data)
                file_count += 1
                total_bytes += len(data)
                all_files.append((full, size))
            except Exception as ex:
                errors.append(f'READ {full}: {ex}')

# 根目录起始簇：BPB 写的是 0/坏值时手动指定为 2（macOS 拒读但 FAT 表里根目录在簇 2）
walk(2, '/')

print(f'\n=== SUMMARY ===')
print(f'files:   {file_count}')
print(f'dirs:    {dir_count}')
print(f'bytes:   {total_bytes:,}')
print(f'errors:  {len(errors)}')
for e in errors[:10]:
    print(f'  - {e}')
```

### 用法

```bash
python3 fat32_extract.py /tmp/disk.img
# 输出到 ~/Desktop/recovered/
```

### 已知限制

- 假设根目录起始簇是 2（macOS 拒读但 FAT 表里标准位置）。其他卷需要改 `walk()` 的第一个参数
- 不处理删除文件（FAT chain 可能不完整）
- 不处理长名 checksum 校验
- 不处理循环目录引用

---

## 附录 B：FAT32 BPB 字段速查表

| 偏移 | 长度 | 字段 | 说明 | 典型值 |
|------|------|------|------|--------|
| 0x00 | 3 | 跳转指令 | JMP 短跳 | `EB 58 90` |
| 0x03 | 8 | OEM 名称 | "MSDOS5.0" 等 | "MSDOS5.0" |
| 0x0B | 2 | **每扇区字节数** (BPS) | 必须是 2 的幂 | 512 / 1024 / 2048 / 4096 |
| 0x0D | 1 | **每簇扇区数** (SPC) | 必须是 2 的幂，≤ 128 | 1, 2, 4, 8, 16, 32, 64, 128 |
| 0x0E | 2 | **保留扇区数** (RSD) | BPB 区，不含 FAT | 32 (FAT32 典型) |
| 0x10 | 1 | **FAT 表数** (NF) | 几乎总是 2 | 2 |
| 0x11 | 2 | 根目录条目数 | FAT32 必须是 0 | 0 |
| 0x13 | 2 | 总扇区（旧） | FAT32 必须是 0 | 0 |
| 0x15 | 1 | 媒体描述符 | 0xF8=硬盘 | 0xF8 |
| 0x16 | 2 | 每 FAT 扇区（旧） | FAT32 必须是 0 | 0 |
| 0x18 | 2 | 每磁道扇区 | CHS 几何 | 63 |
| 0x1A | 2 | 磁头数 | CHS 几何 | 255 |
| 0x1C | 4 | 隐藏扇区 | 分区起点偏移 | 0 或 64 |
| 0x20 | 4 | **总扇区** (FAT32) | 卷大小 / BPS | 3932096 (2GB) |
| 0x24 | 4 | **每 FAT 扇区** (SPF) | FAT32 关键 | 480 |
| 0x28 | 2 | 标志 | bit0=0/1 表示使用哪个 FAT | 0 |
| 0x2A | 4 | **根目录起始簇** | ⚠️ 坏卷常为 0/异常值 | 2 (标准) |
| 0x2E | 2 | **FSInfo 扇区号** | ⚠️ 坏卷常为 0 | 1 (标准) |
| 0x30 | 2 | 备份引导扇区号 | 通常是 6 | 6 (标准) |
| 0x32 | 2 | 保留 | 0 | 0 |
| 0x34 | 12 | 保留 | 0 | 0 |
| 0x40 | 1 | 物理驱动器号 | 0x80=硬盘 0x00=可移动 | 0x80 |
| 0x41 | 1 | 保留 | 0 | 0 |
| 0x42 | 1 | 扩展引导签名 | 必须是 0x29 | 0x29 |
| 0x43 | 4 | 卷序列号 | 随机 / 时间戳 | 0x012CC698 |
| 0x47 | 11 | 卷标 | "DISK_IMG" 等 | "DISK_IMG    " |
| 0x52 | 8 | 文件系统类型 | "FAT32   " | "FAT32   " |
| 0x1FE | 2 | **引导签名** | 必须是 0x55 0xAA | 55 AA |

### 关键字段与"macOS 拒读"的关系

| 字段 | 坏值症状 | macOS 行为 |
|------|----------|-----------|
| 0x2A 根目录起始簇 = 0 或超大值 | `Invalid argument` 拒挂载 | 内核 msdosfs 拒 |
| 0x2E FSInfo 扇区 = 0 | 视驱动实现，可能拒也可能容忍 | macOS 拒 |
| 0x0D 每簇扇区数 非 2 的幂 | 几乎肯定拒 | macOS 拒 |
| 0x1FE 引导签名 ≠ 55 AA | 视作非 FAT 卷 | macOS 拒 |
| 0x20 总扇区 算出的卷大小 = 0 | `Volume Total Space: 0 B` | macOS 拒 |
| 0x1C 隐藏扇区 ≠ 实际分区起点偏移 | 簇号 → 物理地址错 | mount 失败 |

### 推导公式速查

```
簇大小       = BPS × SPC
FAT 区大小    = NF × SPF × BPS
数据区起点    = (RSD + NF × SPF) × BPS (相对分区起点)
数据区大小    = (TOTAL - RSD - NF × SPF) × BPS
总簇数       = 数据区大小 / 簇大小
FAT 链读      = FAT 起始 + cluster × 4, 读 4 字节 LE, & 0x0FFFFFFF
簇 N 字节偏移  = 数据区起点 + (N - 2) × 簇大小 (相对分区起点)
```

