#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-debug}"
case "${MODE}" in
  debug|profile|release) ;;
  *)
    echo "用法: $0 [debug|profile|release]" >&2
    exit 1
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAWFILE_DIR="${ROOT}/ohos/entry/src/main/resources/rawfile"
DEST="${RAWFILE_DIR}/flutter_assets"
BUILD_INFO_SRC="${ROOT}/ohos/entry/src/main/resources/base/profile/buildinfo.json5"
BUILD_INFO_DEST="${RAWFILE_DIR}/buildinfo.json5"

FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter)}"
if [[ -z "${FLUTTER_BIN}" ]]; then
  echo "❌ 找不到 flutter 命令，请设置 FLUTTER_BIN 或将其加入 PATH。" >&2
  exit 1
fi

echo "==> ${FLUTTER_BIN} build bundle --${MODE}"
"${FLUTTER_BIN}" build bundle "--${MODE}"

if [[ ! -d "${ROOT}/build/flutter_assets" ]]; then
  echo "❌ 未找到 build/flutter_assets，请确认 Flutter 构建成功。" >&2
  exit 1
fi

echo "==> 同步 Flutter 产物到 ${DEST}"
rm -rf "${DEST}"
mkdir -p "${DEST}"
cp -R "${ROOT}/build/flutter_assets/." "${DEST}/"

if [[ -f "${BUILD_INFO_SRC}" ]]; then
  echo "==> 同步 buildinfo.json5"
  mkdir -p "${RAWFILE_DIR}"
  cp "${BUILD_INFO_SRC}" "${BUILD_INFO_DEST}"
fi

echo "✅ 资源同步完成，可继续在 DevEco Studio/hvigor 中构建。"
