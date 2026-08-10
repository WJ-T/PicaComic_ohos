#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
TARGET_PLATFORM="${TARGET_PLATFORM:-ohos-arm64}"
BUILD_MODE="${BUILD_MODE:-release}"
APP_JSON="${PROJECT_ROOT}/ohos/AppScope/app.json5"
LOCAL_PROPERTIES="${PROJECT_ROOT}/ohos/local.properties"
HAP_PATH="${PROJECT_ROOT}/ohos/entry/build/default/outputs/default/entry-default-signed.hap"

if [[ ! -f "${APP_JSON}" ]]; then
  echo "Missing ${APP_JSON}" >&2
  exit 1
fi

# Keep the repository version as the source of truth. Flutter's OHOS builder
# normalizes beta suffixes, so the final Hvigor invocation must receive the
# exact version explicitly through local.properties.
VERSION_NAME="$(sed -nE 's/^[[:space:]]*"versionName"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "${APP_JSON}" | head -n 1)"
VERSION_CODE="$(sed -nE 's/^[[:space:]]*"versionCode"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "${APP_JSON}" | head -n 1)"

if [[ -z "${VERSION_NAME}" || -z "${VERSION_CODE}" ]]; then
  echo "Could not read version from ${APP_JSON}" >&2
  exit 1
fi

APP_BACKUP="$(mktemp)"
PROPERTIES_BACKUP="$(mktemp)"
cp "${APP_JSON}" "${APP_BACKUP}"
if [[ -f "${LOCAL_PROPERTIES}" ]]; then
  cp "${LOCAL_PROPERTIES}" "${PROPERTIES_BACKUP}"
else
  : > "${PROPERTIES_BACKUP}"
fi

HVIGORW="${HVIGORW:-}"
if [[ -z "${HVIGORW}" && -f "${LOCAL_PROPERTIES}" ]]; then
  HSDK_DIR="$(sed -nE 's/^hwsdk\.dir=(.*)$/\1/p' "${LOCAL_PROPERTIES}" | head -n 1)"
  if [[ -n "${HSDK_DIR}" ]]; then
    HVIGORW="$(dirname "${HSDK_DIR}")/tools/hvigor/bin/hvigorw"
  fi
fi
if [[ -z "${HVIGORW}" ]]; then
  HVIGORW="$(command -v hvigorw || true)"
fi
if [[ -z "${HVIGORW}" || ! -x "${HVIGORW}" ]]; then
  echo "Could not locate hvigorw. Set HVIGORW to the DevEco hvigorw executable." >&2
  exit 1
fi

restore_project_files() {
  cp "${APP_BACKUP}" "${APP_JSON}"
  if [[ -s "${PROPERTIES_BACKUP}" ]]; then
    cp "${PROPERTIES_BACKUP}" "${LOCAL_PROPERTIES}"
  else
    rm -f "${LOCAL_PROPERTIES}"
  fi
  rm -f "${APP_BACKUP}" "${PROPERTIES_BACKUP}"
}
trap restore_project_files EXIT

cd "${PROJECT_ROOT}"

# This step generates Flutter's OHOS app.so, assets, plugin HARs and native
# overrides. Its intermediate HAP is intentionally discarded because Flutter
# writes the normalized versionName during this step.
"${FLUTTER_BIN}" build hap --"${BUILD_MODE}" --target-platform="${TARGET_PLATFORM}"

export VERSION_NAME VERSION_CODE
perl -0pi -e 's/("versionName"\s*:\s*")[^"]*(")/$1$ENV{VERSION_NAME}$2/' "${APP_JSON}"

if [[ -f "${LOCAL_PROPERTIES}" ]]; then
  perl -0pi -e 's/^flutter\.versionName=.*\n//mg; s/^flutter\.versionCode=.*\n//mg' "${LOCAL_PROPERTIES}"
else
  : > "${LOCAL_PROPERTIES}"
fi
printf 'flutter.versionName=%s\nflutter.versionCode=%s\n' "${VERSION_NAME}" "${VERSION_CODE}" >> "${LOCAL_PROPERTIES}"

cd "${PROJECT_ROOT}/ohos"
"${HVIGORW}" assembleHap \
  -p product=default \
  -p buildMode="${BUILD_MODE}" \
  -p TARGET_PLATFORM="${TARGET_PLATFORM}" \
  --no-daemon

if [[ ! -f "${HAP_PATH}" ]]; then
  echo "Hvigor did not produce ${HAP_PATH}" >&2
  exit 1
fi

echo "Built ${HAP_PATH}"
echo "Installed version: ${VERSION_NAME} (${VERSION_CODE})"
