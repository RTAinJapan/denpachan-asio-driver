# denpachan-asio-driver

[denpachan](https://github.com/RTAinJapan/denpachan) の音声を **ASIO のドライバ** (Dante Virtual Soundcard の ASIO モードなど) に出すための DLL (`denpachan-asio-driver.dll`)。

denpachan 本体は MIT License だが、ASIO には Steinberg の ASIO SDK (GPL-3.0) が要る。本体を GPL にしないため、SDK に触れる部分だけをこのリポジトリに分け、**GPL-3.0** で配っている。本体の配布物にはこの DLL は入っていない。

## 使い方

1. [Releases](https://github.com/RTAinJapan/denpachan-asio-driver/releases) から `denpachan-asio-driver-<版>-win64.zip` を取る。
2. 展開した中の `denpachan-asio-driver.dll` を、**denpachan の `denpachan-engine.exe` と同じフォルダ**に置く。
3. denpachan を起動し直す (engine は起動時にこの DLL を読み込む)。チャンネルの「音声」の出力先に `ASIO: ドライバ名` が出る。

- engine は自分と同じフォルダの DLL だけを読み込む (PATH は探さない)。
- ASIO のドライバは同時に 1 つだけ使える (複数のチャンネルで同じドライバを使うのはよい)。
- DLL を消せば、ASIO の出力先が出なくなるだけで、denpachan は他はそのまま動く。
- 対応する denpachan の版: 下記「版の対応」。

## 版の対応

engine と DLL は、`include/denpachan_asio.h` の `DENPACHAN_ASIO_ABI_VERSION` が同じときだけ組み合わせられる (違えば engine が読み込まずログに出す)。

| denpachan-asio-driver | ABI | denpachan |
|---|---|---|
| 0.1.x | 1 | 0.1.x |

## 仕組み

- engine (MIT) は ASIO SDK のヘッダを一切使わず、この DLL の C の関数 (`include/denpachan_asio.h`、MIT) で受け渡す。同じヘッダを denpachan の `src/engine/denpachan_asio.h` にも置いてある。変えるときは ABI の版を上げ、両方を合わせる。
- DLL が行うこと: ドライバの列挙 (`HKLM\SOFTWARE\ASIO`) と COM での読み込み、専用のスレッド (STA) でのメッセージ処理、ドライバのコールバック (bufferSwitch) とその時刻の均し、サンプル形式の変換 (int16 / int24 / int32 / float32 / float64 など)、リセット要求での開き直し、診断のログ (実時間で呼ばれていない、コールバックが止まった)。
- engine が行うこと: 各チャンネルの音を作る (遅延を一定に保つ・クロックずれの補正・フェード・ミュート)、状態の表示。
- 設計の詳細は denpachan の `docs/design.md` §6.4。

## ビルド

Visual Studio 2026 (C++ によるデスクトップ開発) と CMake 3.25 以上 (VS 付属のもの)。vcpkg は使わない。

```powershell
./build.ps1
```

- `cmake/FetchAsioSdk.cmake` が Steinberg の ASIO SDK 2.3.4 を固定の URL と SHA256 で取り、`out/deps/` に展開する (ヘッダだけ使う)。展開済みのものを使うなら `-DDENPACHAN_ASIOSDK_DIR=<ASIOSDK フォルダ>`。
- 出力: `out/build/bin/Release/denpachan-asio-driver.dll` と `licenses/`。
- 配布の zip: `./tools/package.ps1` → `out/dist/`。

## リリース

版は `CMakeLists.txt` の `project(denpachan-asio-driver ... VERSION X.Y.Z)` の 1 か所だけに書く。

1. 版を上げて main にコミットする。
2. そのコミットにタグ `vX.Y.Z` (プレリリースなら `vX.Y.Z-rc.1` など) を付けて push する。
3. GitHub Actions がビルドし、Release「denpachan-asio-driver X.Y.Z」を作って zip と PDB の zip を付ける。

タグの版が `CMakeLists.txt` と合わないときはビルドの最初で失敗し、リリースは作られない。

## ライセンス

- このリポジトリ: [GNU General Public License v3.0](LICENSE)。Copyright (c) 2026 RTA in Japan。
- `include/denpachan_asio.h` (engine との受け渡しの定義) だけは MIT (denpachan 本体にも同じものがある)。
- ASIO SDK (Steinberg Media Technologies GmbH) 2.3.4: GPL-3.0 で使用。ライセンス文は配布物の `licenses/asiosdk.txt`。
- ASIO is a trademark and software of Steinberg Media Technologies GmbH.
