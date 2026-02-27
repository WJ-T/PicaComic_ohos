#!/usr/bin/env bash
# Builds the QuickJS shared libraries for HarmonyOS using the OpenHarmony NDK.
# The script reads the DevEco Studio SDK path from ohos/local.properties
# (property name: hwsdk.dir). You can also override it by exporting OHOS_SDK.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_PROPERTIES="$PROJECT_ROOT/ohos/local.properties"

if [[ "${OHOS_SDK:-}" == "" ]]; then
  if [[ -f "$LOCAL_PROPERTIES" ]]; then
    SDK_LINE="$(grep -E '^hwsdk\.dir=' "$LOCAL_PROPERTIES" | head -n1 || true)"
    if [[ "$SDK_LINE" != "" ]]; then
      OHOS_SDK="${SDK_LINE#hwsdk.dir=}"
    fi
  fi
fi

if [[ "${OHOS_SDK:-}" == "" ]]; then
  echo "Unable to determine DevEco Studio SDK path."
  echo "Set OHOS_SDK or add hwsdk.dir to ohos/local.properties."
  exit 1
fi

# Support both SDK layouts:
# 1) <sdk>/openharmony/native/...
# 2) <sdk>/native/... (e.g. some manual extractions / DevEco variants / exFAT where symlinks are blocked)
if [[ -d "$OHOS_SDK/default" ]]; then
  OHOS_SDK="$OHOS_SDK/default"
fi

if [[ -d "$OHOS_SDK/openharmony/native" ]]; then
  OHOS_NDK="$OHOS_SDK/openharmony/native"
elif [[ -d "$OHOS_SDK/native" ]]; then
  OHOS_NDK="$OHOS_SDK/native"
else
  echo "Cannot find OpenHarmony NDK under $OHOS_SDK (expected openharmony/native or native)" >&2
  exit 1
fi

LLVM_BIN="$OHOS_NDK/llvm/bin"
SYSROOT="$OHOS_NDK/sysroot"
SRC_DIR="$PROJECT_ROOT/flutter_qjs/cxx"
LIB_NAME="libflutter_qjs_plugin.so"

if [[ ! -x "$LLVM_BIN/aarch64-unknown-linux-ohos-clang" ]]; then
  echo "Cannot find OpenHarmony clang toolchain in $LLVM_BIN"
  exit 1
fi

build_arch() {
  local abi="$1"
  local triple="$2"
  local cc="$LLVM_BIN/${triple}-clang"
  local cxx="$LLVM_BIN/${triple}-clang++"
  local out_dir="$PROJECT_ROOT/flutter_qjs/build_ohos/$abi"
  mkdir -p "$out_dir"

  echo "Building QuickJS for $abi ($triple)..."
  rm -f "$out_dir"/*.o "$out_dir/$LIB_NAME"
  local cflags=(-fPIC -O2 -I"$SRC_DIR" -D_GNU_SOURCE --sysroot="$SYSROOT")
  for src in cutils.c libregexp.c libunicode.c quickjs.c libbf.c; do
    "$cc" "${cflags[@]}" -c "$SRC_DIR/quickjs-ng/$src" -o "$out_dir/${src%.c}.o"
  done

  "$cxx" -std=c++17 -fPIC -O2 --sysroot="$SYSROOT" \
    -I"$SRC_DIR" "$SRC_DIR/ffi.cpp" "$out_dir"/*.o -shared -static-libstdc++ \
    -o "$out_dir/$LIB_NAME" -lm -ldl

  local target_dir="$PROJECT_ROOT/ohos/entry/libs/$abi"
  mkdir -p "$target_dir"
  cp "$out_dir/$LIB_NAME" "$target_dir/$LIB_NAME"
  echo "Wrote $target_dir/$LIB_NAME"
}

build_arch arm64-v8a aarch64-unknown-linux-ohos
build_arch x86_64 x86_64-unknown-linux-ohos

echo "QuickJS HarmonyOS libraries updated."
