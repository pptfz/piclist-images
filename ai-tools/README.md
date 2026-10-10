# AI 图片生成与图床上传指南（给任何 AI 助手看）

> 本文档是自我说明：任何 AI 工具（WorkBuddy / Claude / ChatGPT / 其他）拿到这份文件，
> 就能按同样方式为用户生成笔记配图并上传图床。请完整阅读后再操作。

## 一、图床信息

| 项 | 值 |
|----|-----|
| 图床仓库 | `pptfz/picgo-images`（曾用名，实际已改名 `pptfz/piclist-images`，旧名 API 自动重定向仍可用） |
| 分支 | `master` |
| 存放目录 | `img/` |
| 引用格式 | `![标题](https://raw.githubusercontent.com/pptfz/picgo-images/master/img/<文件名>.png)` |
| token 来源 | 不写进任何文档！两个途径：① 环境变量 `PICGO_GITHUB_TOKEN`；② 本机 PicList 配置 `~/Library/Application Support/piclist/data.json`（字段 `picBed.github.token`） |

## 二、上传方式

用本目录的 `picgo-upload.sh`（等效于用户 PicList 客户端的上传动作）：

```bash
chmod +x picgo-upload.sh
./picgo-upload.sh /path/to/diagram.png           # 保持原文件名
./picgo-upload.sh /path/to/diagram.png new-name.png  # 指定远程文件名
```

底层就是 GitHub Contents API 的 PUT，**不要用 git 命令推图床**（用户红线：禁止 AI 执行 git 网络操作）。

## 三、生成示意图的标准流程

用户的笔记（Docusaurus 博客）需要架构图/原理图时，按此流程：

1. **画 SVG**：手写矢量图（不要用 AI 文生图，文字会乱）。风格约定：
   - 白色背景、中文用 PingFang SC、等宽英文用 SF Mono/Menlo
   - 配色：标题 `#1e293b`，灰 `#f1f5f9/#64748b`，蓝 `#dbeafe/#2563eb`，绿 `#dcfce7/#16a34a`，紫 `#ede9fe/#7c3aed`，橙 `#ffedd5/#ea580c`，红 `#fee2e2/#dc2626`
   - viewBox 宽 900 左右，逻辑分层清晰，箭头标注对应命令
2. **渲染 PNG（2x = 1800px）**：用 node + sharp（libvips 自带 SVG 渲染）：

   ```bash
   npm install sharp   # 任一工作目录
   node -e "
   const sharp = require('sharp');
   sharp('diagram.svg', { density: 192 })
     .resize(1800)
     .png({ palette: true, quality: 90, effort: 4 })   // 量化压缩，纯色图体积约降到 38%
     .toFile('diagram.png');
   "
   ```

   注意：`effort: 10` 会 OOM（exit 137），用 4。
3. **上传**：`./picgo-upload.sh diagram.png`
4. **验证**：curl 直连 raw.githubusercontent.com 在国内网络可能不通（返回 000），验证入库改用 GitHub API：

   ```bash
   curl -sL -H "Authorization: token $PICGO_GITHUB_TOKEN" \
     "https://api.github.com/repos/pptfz/picgo-images/contents/img/diagram.png?ref=master"
   ```
5. **插入笔记**：Markdown 引用（用户博客是 Docusaurus，**MDX 不支持 `<https://url>` 自动链接**，必须写 `[文本](url)`；admonition 语法 `:::tip 说明` 关键字后必须有空格）

## 四、注意事项

- **token 绝不落文档/日志/截图**，只从环境变量或 PicList 配置读取
- 用户网络下 curl 访问 `raw.githubusercontent.com` 不通是正常现象，不影响浏览器访问（用户浏览器有代理）
- 覆盖已存在的图片：PUT 时带上原文件的 `sha` 字段
- 用户名：厚礼蟹（博客 pptfz）。图床仓库同时被 PicList 客户端使用（Typora 拖图自动上传），AI 上传与人工上传共存，互不影响
