# 阶段 1: 隐私审计与清理

> **在一切美化之前,先确认没有把密钥 / 个人信息扫进仓库。**
> 这一步是技术活,但**最关键**——一旦推送了密钥,即使删文件、force-push,GitHub 仍可能缓存。

## 目标

- [ ] 仓库 HEAD(当前 working tree)**零命中**
- [ ] 仓库 git 历史(全部分支 + tag)**零命中**
- [ ] 常见误提交(`.env` / `node_modules` / `*.key` / `*.pem`)**全部 .gitignore**
- [ ] 个人邮箱(尤其公司邮箱)要么公开要么换

## 1.1 工具链

| 工具 | 用途 | 安装 |
|---|---|---|
| **gitleaks** | 扫历史和当前,核心工具 | `brew install gitleaks` / `apt install gitleaks` / 二进制 |
| **trufflehog** | 备份 gitleaks,扫高熵字符串 | `brew install trufflehog` |
| **detect-secrets** | Yelp 出品,可 baseline | `pip install detect-secrets` |
| **git-filter-repo** | 真正从历史删除敏感文件 | `brew install git-filter-repo` / `pip install git-filter-repo` |
| **ripgrep** | 通用 grep,扫路径 | `brew install ripgrep` |

## 1.2 工作流(按顺序)

### Step 1: 静态扫(快,先做)

```bash
# 在仓库根目录
gitleaks detect --source . --no-banner -v
```

可能命中的典型误提交:

- AWS Access Key: `AKIA[0-9A-Z]{16}`
- GitHub PAT: `ghp_[0-9a-zA-Z]{36}`
- OpenAI Key: `sk-[0-9a-zA-Z]{48}`
- 私钥: `-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----`
- 邮箱 + 密码 组合

### Step 2: 扫历史(慢但关键)

```bash
# 全历史扫
gitleaks detect --source . --log-opts="--all" --no-banner -v
```

如果命中,先**轮换密钥**(即使你打算删,密钥已经泄露过,必须假设被爬了),再清理历史。

### Step 3: 扫特定路径

```bash
# 扫常见误提交
gitleaks detect --source . \
  --no-banner \
  --additional-config <(cat <<'EOF'
[[rules]]
id = "private-key"
description = "Private Key"
regex = '''-----BEGIN [A-Z ]*PRIVATE KEY-----'''
[[rules]]
id = "generic-api-key"
description = "Generic API Key"
regex = '''(?i)(api[_-]?key|apikey|secret[_-]?key|access[_-]?token)\s*[:=]\s*['"][0-9a-zA-Z\-_]{16,}['"]'''
EOF
)
```

### Step 4: 手动 grep 兜底

```bash
# 即使 gitleaks 报 0,人工再扫一遍
rg -i "password|secret|api[_-]?key|token" --type-add 'config:*.{env,yml,yaml,json,toml,ini,conf}' -t config
rg "BEGIN.*PRIVATE KEY" -g '!*.md'
rg -e "[a-zA-Z0-9+/]{40,}" --type-add 'creds:*.{key,pem}' -t creds
```

## 1.3 命中后:清理历史(慎之又慎)

⚠️ **重写历史会改 commit hash,所有协作者必须重新 clone。**

### 方案 A: 整个文件删除(用 git-filter-repo)

```bash
# 1. 备份(必须)
cp -R /path/to/repo /path/to/repo.backup

# 2. 重新 clone(避免 filter-repo 报 "not a fresh clone")
cd /tmp
git clone /path/to/repo cleanup
cd cleanup

# 3. 删除敏感文件
git filter-repo --path config/secrets.yaml --invert-paths

# 4. 推送(强制,警告协作者)
git remote add origin /path/to/repo  # 必须重新加 remote
git push origin --force --all
git push origin --force --tags
```

### 方案 B: 内容替换(用 git-filter-repo)

```bash
# 如果密钥只是字符串,不是整个文件
git filter-repo --replace-text expressions.txt
# expressions.txt 内容: 原字符串==>新字符串
```

### 方案 C: 极端情况 - 删除整个仓库重建

如果历史混乱到无法清理(比如 5 年 commit 里散落 30+ 个密钥):
1. 把当前 working tree 拷出来
2. `git init` 新仓库
3. 写一个干净的首 commit
4. 重新推送(所有 stars / forks 都会断,但比起密钥泄露,这是最小代价)

## 1.4 个人信息处理

| 信息 | 处理 |
|---|---|
| 真实姓名 | OK,GitHub profile 默认显示 |
| 公司邮箱(比如 xxx@bytedance.com) | **必须换**,用 Gmail / 个人域名邮箱 |
| 公司内部 URL(`https://internal.company.com`) | 全局搜,删 |
| 同事真名 | 用 @ 提及时小心(可以加 `<!-- TODO: ask XXX -->`) |
| 地理位置 | 看你,不强求 |

```bash
# 找公司邮箱
rg "@[a-z]+\.(com|cn|io|net|org)" --type-add 'config:*.{env,yml,yaml,json,ts,js,py,go,rs}' -t config
# 看是不是有公司域名
```

## 1.5 未来防护:在仓库加这些文件

- **`.gitignore`** —— 阶段 2 会展开
- **`.gitleaks.toml`** —— 自定义规则
- **`.github/workflows/gitleaks.yml`** —— PR 触发自动扫描
- **`SECURITY.md`** —— 告诉发现漏洞的人怎么私下报告(不要在 public issue 写)
- **`pre-commit` hook** —— 提交前自动扫

```yaml
# .github/workflows/gitleaks.yml 示例
name: gitleaks
on: [pull_request, push]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 1.6 阶段 1 退出标准

- [ ] gitleaks detect 0 命中
- [ ] gitleaks detect --log-opts="--all" 0 命中
- [ ] 公司邮箱 / 内部 URL 0 命中
- [ ] `.gitleaks.toml` 提交到仓库
- [ ] `.github/workflows/gitleaks.yml` 提交到仓库
- [ ] `SECURITY.md` 提交到仓库

如果以上都通过 → 进入**阶段 2:仓库骨架**。

如果有命中 → 先轮换密钥(假设已被爬),再清理历史,**别心存侥幸**。

---

## 关联脚本

`scipts/privacy-scan.sh` 帮你自动跑这 6 步检查。

## 下一个:阶段 2 仓库骨架
