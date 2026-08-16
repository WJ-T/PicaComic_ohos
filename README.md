# Pica Comic (OHOS Fork)

[![flutter](https://img.shields.io/badge/flutter-3.35.8--ohos-blue)](https://flutter.dev/)
[![License](https://img.shields.io/github/license/nimmi114514/PicaComic_ohos)](https://github.com/nimmi114514/PicaComic_ohos/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/nimmi114514/PicaComic_ohos)](https://github.com/nimmi114514/PicaComic_ohos/releases)
[![stars](https://img.shields.io/github/stars/nimmi114514/PicaComic_ohos)](https://github.com/nimmi114514/PicaComic_ohos/stargazers)

A comic app with multiple sources built with flutter.

> **About this fork**
> This repository (`WJ-T/PicaComic_ohos`) is a HarmonyOS / OHOS adaptation of the upstream project [Pacalini/PicaComic](https://github.com/Pacalini/PicaComic).
> The original project retains Android / desktop support; this fork focuses on keeping the OHOS host project and build scripts up to date.

**Forked from [nyne](https://github.com/wgh136), provide extended support & fix, no guaranteed roadmap.**

## Download

<a href="https://github.com/nimmi114514/PicaComic_ohos/releases">
<img src="https://user-images.githubusercontent.com/69304392/148696068-0cfea65d-b18f-4685-82b5-329a330b1c0d.png"
alt="Get it on GitHub" align="center" height="80" /></a>

<a href="https://github.com/nimmi114514/PicaComic_ohos/blob/master/INSTALL.md#obtainium">
<img src="https://github.com/ImranR98/Obtainium/blob/main/assets/graphics/badge_obtainium.png"
alt="Get it on Obtainium" align="center" height="54" />
</a>

> 🛈 This fork does not publish official OHOS `.hap` releases yet — please follow the **HarmonyOS / OHOS** section below to build locally.

An [AUR package](https://aur.archlinux.org/packages/pica-comic-bin) is packed by [Lilinzta](https://github.com/Lilinzta):

```shell
paru -S pica-comic-bin
```

## Build (OHOS)

This fork is maintained for **OHOS/HarmonyOS development first**.
If you are onboarding a new device/environment, use this section instead of old cached notes.

### Verified toolchain (2026-07-19)

- Flutter: `3.35.8-ohos-0.0.2`
- Dart: `3.9.2`
- HarmonyOS SDK: `6.1.0.31` (API 23)
- Node: `18.20.1`
- ohpm: `6.0.1`

> API 23 is required for the current OHOS host project. The free-window title bar immersive mode is compiled against the API 23 window APIs and the OHOS ability declares `supportWindowMode` for `fullscreen`, `split`, and `floating`.

### 1. One-time environment setup

Windows CMD:

```bat
set "JAVA_HOME=C:\Program Files\Huawei\DevEco Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
flutter config --enable-ohos
flutter config --ohos-sdk D:\command-line-tools\sdk
flutter precache --ohos
```

macOS (zsh/bash):

```bash
export JAVA_HOME="/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
flutter config --enable-ohos
flutter config --ohos-sdk "$HOME/Library/OpenHarmony/Sdk"
flutter precache --ohos
```

Make sure the configured SDK contains API 23. If you keep multiple SDK roots, point Flutter and DevEco/Hvigor at the root that contains the `23` platform before running the release build script.

If `ohos/har/flutter.har` is missing (both platforms):

```bash
bash tool/prepare_ohos_har.sh
```

`tool/patch_ohos_flutter_har.dart` is required for the current Flutter OHOS
embedding. It keeps `windowStageEvent` listener failures from blocking
`windowStage.loadContent`, which is needed for service-card cold starts.
It also disables the OHOS embedding's runtime `updateDpiScale` path. That path
changes Flutter's root `devicePixelRatio` while the app is running and can
scale the entire page, including overlays, during scrolling. Real window-size
and display-density changes remain handled by the embedding.

### 2. Bootstrap project on a new machine

Windows CMD:

```bat
git clone https://github.com/WJ-T/PicaComic_ohos
cd /d D:\path\to\PicaComic_ohos
flutter pub get
dart run tool\patch_ohos_flutter_har.dart
cd /d ohos
where ohpm
ohpm.bat install --all
cd /d ..
```

macOS (zsh/bash):

```bash
git clone https://github.com/WJ-T/PicaComic_ohos
cd /path/to/PicaComic_ohos
flutter pub get
dart run tool/patch_ohos_flutter_har.dart
cd ohos
which ohpm
ohpm install --all
cd ..
```

### 3. Build and install release HAP (required path)

macOS/Linux/Git Bash/WSL:

```bash
cd /path/to/PicaComic_ohos
flutter clean
flutter pub get
dart run tool/patch_ohos_flutter_har.dart
cd ohos
ohpm install --all
cd ..
tool/build_ohos_hap.sh
hdc install -r ohos/entry/build/default/outputs/default/entry-default-signed.hap
```

`tool/build_ohos_hap.sh` must be used for the final release build. Do not use
`flutter build hap` as the HAP to install: Flutter's OHOS builder normalizes
`4.8.3-beta2` to `4.8.32` while generating its intermediate HAP. The script
uses Flutter to generate the runtime files, then runs the final Hvigor package
step with the exact version from `ohos/AppScope/app.json5`.

On Windows, run the same commands from Git Bash or WSL. The script also
supports a custom Hvigor executable path when needed:

```bash
HVIGORW=/path/to/hvigorw tool/build_ohos_hap.sh
```

Output:

- `ohos/entry/build/default/outputs/default/entry-default-signed.hap`

### 4. DevEco Studio workflow (optional)

1. Open the `ohos` folder in DevEco Studio.
2. Run `Sync and Refresh Project`.
3. Run `Build > Clean Project`.
4. Run or build Hap from DevEco.

Before the first DevEco build on a new machine (or after dependency changes), execute:

Windows CMD:

```bat
cd /d D:\path\to\PicaComic_ohos\ohos
ohpm.bat install --all
```

macOS (zsh/bash):

```bash
cd /path/to/PicaComic_ohos/ohos
ohpm install --all
```

### 5. Tool scripts in this repo

- `tool/prepare_ohos_har.sh`: copies `flutter.har` from Flutter engine cache into `ohos/har/`.
- `tool/patch_ohos_flutter_har.dart`: patches Flutter OHOS engine HARs so a window-stage event listener error cannot prevent Flutter content from loading during service-card launches. Run it after `flutter precache --ohos` and before release builds.
- `tool/build_quickjs_ohos.sh`: rebuilds `libflutter_qjs_plugin.so`; run when `flutter_qjs/cxx` changes.
- `tool/build_ohos_hap.sh`: builds the final signed HAP with the exact OHOS version from `ohos/AppScope/app.json5`. Use it instead of `flutter build hap` when installing a release build; Flutter otherwise normalizes `4.8.3-beta2` to `4.8.32` during its intermediate build.
- `tool/sync_ohos_flutter_assets.sh`: only needed for specific DevEco/hvigor asset-sync workflows; **not required** for normal `flutter build hap`.

### 6. Common issues

- `Error: spawn java ENOENT`

  - Cause: Java is not in `PATH` for hvigor signing.
  - Fix: set `JAVA_HOME` to DevEco JBR and prepend `JAVA_HOME/bin` to `PATH` (Windows/macOS).
- `Cannot find module '@ohos/flutter_ohos'` / `file_picker_ohos`

  - Cause: ohpm dependencies not installed or stale cache.
  - Fix: run `where ohpm` (Windows) or `which ohpm` (macOS) to verify ohpm is in PATH, then run `ohpm(.bat) install --all` in `ohos/`, then Sync/Clean/Rebuild in DevEco.
- Free-window title bar is not immersive on tablet/2in1

  - Cause: stale hap, old SDK target, or the app was not cold-started after reinstall.
  - Fix: build with API 23, reinstall the release hap, then force-stop and start the app again so `EntryAbility.onWindowStageCreate` reapplies `setWindowDecorVisible(false)`.
- `MissingPluginException(...file_selector...)` on OHOS

  - Cause: old package still running or stale build artifacts.
  - Fix: rebuild and reinstall latest hap from this branch.
- System settings version updated but app About page still old

  - Cause: stale `libapp.so`/old installed package.
  - Fix: `flutter clean` + rebuild hap + reinstall app.

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
