#!/usr/bin/env bash
# picgo-upload.sh — 上传图片到 GitHub 图床（pptfz/picgo-images）
# 用法: ./picgo-upload.sh <本地图片路径> [远程文件名]
# 依赖: curl + python3（仅用于解析 PicList 配置）；token 不落日志
#
# token 来源（按优先级）:
#   1. 环境变量 PICGO_GITHUB_TOKEN
#   2. 本机 PicList 配置: ~/Library/Application Support/piclist/data.json（macOS）
set -euo pipefail

REPO="pptfz/picgo-images"
BRANCH="master"
DIR="img"

FILE="${1:?用法: $0 <本地图片路径> [远程文件名]}"
[ -f "$FILE" ] || { echo "文件不存在: $FILE"; exit 1; }
NAME="${2:-$(basename "$FILE")}"

# ---- 取 token ----
if [ -n "${PICGO_GITHUB_TOKEN:-}" ]; then
  TOKEN="$PICGO_GITHUB_TOKEN"
else
  PICLIST_CONF="$HOME/Library/Application Support/piclist/data.json"
  [ -f "$PICLIST_CONF" ] || { echo "未找到 token：请设置环境变量 PICGO_GITHUB_TOKEN"; exit 1; }
  TOKEN=$(python3 -c "import json;print(json.load(open('$PICLIST_CONF'))['picBed']['github']['token'])")
fi

# ---- 上传 ----
python3 - "$FILE" <<'PYEOF'
import base64, json, sys
data = base64.b64encode(open(sys.argv[1], 'rb').read()).decode()
json.dump({"message": "upload via picgo-upload.sh", "branch": "master", "content": data},
          open('/tmp/.picgo_upload_payload.json', 'w'))
PYEOF

RESP=$(mktemp)
HTTP=$(curl -sL -o "$RESP" -w '%{http_code}' -X PUT \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$DIR/$NAME" \
  --data-binary @/tmp/.picgo_upload_payload.json)
rm -f /tmp/.picgo_upload_payload.json

if [ "$HTTP" = "201" ] || [ "$HTTP" = "200" ]; then
  echo "上传成功 (HTTP $HTTP)"
  echo "引用地址: https://raw.githubusercontent.com/$REPO/$BRANCH/$DIR/$NAME"
else
  echo "上传失败 (HTTP $HTTP)"
  python3 -c "import json;r=json.load(open('$RESP'));print(r.get('message'))" 2>/dev/null || cat "$RESP"
  exit 1
fi
