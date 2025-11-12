#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HERE}/.." && pwd)"
HAR_DIR="${REPO_ROOT}/ohos/har"
FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || true)}"

if [[ -z "${FLUTTER_BIN}" ]]; then
  echo "❌ 无法找到 flutter 命令，请先安装并将其加入 PATH。" >&2
  exit 1
fi

FLUTTER_BIN_DIR="$(cd "$(dirname "${FLUTTER_BIN}")" && pwd)"
ENGINE_DIR="$(cd "${FLUTTER_BIN_DIR}/cache/artifacts/engine" && pwd)"
PREFERRED_ARCH="${1:-ohos-arm64}"
HAR_SOURCE="${ENGINE_DIR}/${PREFERRED_ARCH}/flutter.har"

if [[ ! -f "${HAR_SOURCE}" ]]; then
  echo "⚠️  未找到 ${HAR_SOURCE}。请先运行 'flutter precache --ohos' 下载 OHOS 引擎。" >&2
  exit 1
fi

mkdir -p "${HAR_DIR}"
cp "${HAR_SOURCE}" "${HAR_DIR}/flutter.har"
echo "✅ 已复制 ${HAR_SOURCE} -> ${HAR_DIR}/flutter.har"
