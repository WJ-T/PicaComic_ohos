# Pica Comic (OHOS Fork)

[![flutter](https://img.shields.io/badge/flutter-3.35.1-blue)](https://flutter.dev/)
[![License](https://img.shields.io/github/license/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/releases)
[![stars](https://img.shields.io/github/stars/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/stargazers)

A comic app with multiple sources built with flutter.

> **About this fork**  
> This repository (`WJ-T/PicaComic_ohos`) is a HarmonyOS / OHOS adaptation of the upstream project [Pacalini/PicaComic](https://github.com/Pacalini/PicaComic).  
> The original project retains Android / desktop support; this fork focuses on keeping the OHOS host project and build scripts up to date.

**Forked from [nyne](https://github.com/wgh136), provide extended support & fix, no guaranteed roadmap.**

## Download

<a href="https://github.com/Pacalini/PicaComic/releases">
<img src="https://user-images.githubusercontent.com/69304392/148696068-0cfea65d-b18f-4685-82b5-329a330b1c0d.png"
alt="Get it on GitHub" align="center" height="80" /></a>

<a href="https://github.com/Pacalini/PicaComic/blob/master/INSTALL.md#obtainium">
<img src="https://github.com/ImranR98/Obtainium/blob/main/assets/graphics/badge_obtainium.png"
alt="Get it on Obtainium" align="center" height="54" />
</a>

> 🛈 This fork does not publish official OHOS `.hap` releases yet — please follow the **HarmonyOS / OHOS** section below to build locally.

An [AUR package](https://aur.archlinux.org/packages/pica-comic-bin) is packed by [Lilinzta](https://github.com/Lilinzta):
```shell
paru -S pica-comic-bin
```

## Build

1. Clone the repository
```shell
git clone https://github.com/WJ-T/PicaComic_ohos
```
2. Install flutter: https://docs.flutter.dev/get-started/install
3. Build Application: https://docs.flutter.dev/deployment

## HarmonyOS / OHOS (experimental)

An OpenHarmony host project now lives under `ohos/`. To produce a `.hap` package:

1. Install the OpenHarmony or HarmonyOS SDK and set `OHOS_SDK_HOME` (or run `flutter config --ohos-sdk <path>`).
2. Enable the Flutter OHOS feature and fetch artifacts（可选参数传递 `ohos-x64` 等架构给脚本）：
   ```shell
   flutter config --enable-ohos
   flutter precache --ohos
   ./tool/prepare_ohos_har.sh        # 将 Flutter SDK 中的 flutter.har 拷贝到 ohos/har/
   ```
   `prepare_ohos_har.sh` 默认复制 `ohos-arm64` 版本，传入其它架构（例如 `./tool/prepare_ohos_har.sh ohos-x64`）可切换目标。
3. Build the Hap from the repo root (arm64 by default):
   ```shell
   flutter build hap --target-platform=ohos-arm64
   ```
   The output appears under `build/ohos/outputs/`.
4. 如果你希望直接通过 DevEco Studio/hvigor 调试（而不是执行 `flutter build hap`），在每次构建前运行：
   ```shell
   ./tool/sync_ohos_flutter_assets.sh [debug|profile|release]
   ```
   该脚本会执行 `flutter build bundle` 并把 `build/flutter_assets` 复制到 `ohos/entry/src/main/resources/rawfile`，否则 OHOS 进程会因为找不到 `flutter_assets/kernel_blob.bin` 在调试版上崩溃。
5. Optionally open the `ohos` folder in DevEco Studio 5.0+ to fine-tune signing or launch on a device/emulator.

The `ohos/har` directory is ignored by git—`flutter build hap` copies the required `flutter.har` there automatically. Most pure-Dart plugins work out of the box; native functionality still requires individual OHOS implementations.

## Introduction

### Built-in Comic Source

Currently, Pica Comic has 5 built-in comic sources:
- picacg
- e-hentai/exhentai
- jmcomic
- hitomi
- htcomic
- nhentai

### Features

- Browse manga
- Online reading
- Download manga
- Manage local favorites and network favorites
- Data sync(using webdav)
- Reading history

### History

This project initially started as an unofficial app for picacg
and later evolved into an app that supports multiple comic sources.

## Thanks

### Projects
[![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=tonquer&repo=JMComic-qt)](https://github.com/tonquer/JMComic-qt)

The image restructuring algorithm used to display jm images is from this project.

### Tags Translation
[![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=EhTagTranslation&repo=Database)](https://github.com/EhTagTranslation/Database)

The Chinese translation of the manga tags is from this project.
