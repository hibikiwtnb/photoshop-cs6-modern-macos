# photoshop-cs6-modern-macos

Scripts that keep an existing Photoshop CS6 (13.0.6) install running on modern macOS: Sequoia 15 and macOS 26, on Intel and on Apple Silicon (through Rosetta).

讓已安裝的 Photoshop CS6（13.0.6）在新版 macOS（Sequoia 15、macOS 26，Intel 與 Apple Silicon／Rosetta）上繼續使用的腳本集。

> This repository contains no Adobe software, serial numbers or license files. You need your own legally obtained, fully installed CS6.
> 本倉庫不含任何 Adobe 程式、序號或授權檔案，請自備合法取得並已完整安裝的 CS6。

## 修了什麼

| 問題 | 原因 | 腳本 |
| --- | --- | --- |
| Finder 拒絕啟動 | 原 bundle ID `com.adobe.Photoshop` 被系統阻擋 | `Apply-Compatibility.command` |
| 3D 功能導致崩潰 | 3D 引擎外掛不相容；改名為 `~Photoshop3DEngine.plugin` 後 PS 會略過它 | `Apply-Compatibility.command` |
| 背景更新／遙測常駐 | AUM 更新器（AdobeUpdater）與 LogTransport 每次啟動都會被叫起，甚至會上傳遙測與崩潰回報 | `Disable-AutoUpdate.command` |
| 從別台機器搬來後提示「元件遺失或損壞」 | 缺少原安裝機器上 `/Library/Application Support/Adobe` 底下的 `Adobe PCD`、`caps`、`PCF`、`SLCache`、`SLStore`、`ssc`、`OOBE`、`Adobe Photoshop CS6` | `Migrate-Support-Files.command` |
| 缺少 Adobe Unit Types | 新系統上沒有這個 scripting addition | `Install-Unit-Types-Osax.command` |
| **現代 macOS：掃描字型時崩潰，例如存 JPG** | CoolType 呼叫舊版 `ATSFontIteratorReset` 時可能崩潰。已在 Intel Sequoia 15.7.7 與 M2 macOS 26.5 觀察到 | `Install-macOS26-Fix.command` |
| **現代 macOS：每次啟動後首次存檔偏慢** | CoolType 使用 APFS 不支援的 `exchangedata()` 儲存字型快取，導致字型清單需要重建 | `Install-macOS26-Fix.command` |

字型崩潰與快取問題的技術細節見 [docs/macos26-font-fix.md](docs/macos26-font-fix.md)。

## 第一步：在 Mojave 虛擬機裡安裝

CS6 的安裝程式在新版 macOS 上跑不動，所以我們的做法是：

1. 建立一台 macOS Mojave 10.14 虛擬機（我們用 VMware Fusion），**安裝前先斷開虛擬網卡**。CS6 連網啟動時會要求登入帳號。
2. 在虛擬機裡安裝 CS6（試用模式即可），開啟一次確認能用，再套用 Adobe 官方的 13.0.6 更新。
3. 把下列項目從虛擬機複製到新 Mac 的同一個位置：
   - `/Applications/Adobe Photoshop CS6/`（整個資料夾）
   - `/Library/Application Support/Adobe/`，之後交給 `Migrate-Support-Files.command` 處理
   - `/Library/ScriptingAdditions/Adobe Unit Types.osax`
   - （選用）`~/Library/Preferences/Adobe Photoshop CS6 Settings/`

Mojave 虛擬機需要 Intel Mac 當主機。Apple Silicon 無法用硬體虛擬化跑 Intel 版 macOS，可以借一台 Intel Mac 完成這一步，再把成品複製到 Apple Silicon 機器上。

## 第二步：在新 Mac 上執行腳本

先退出 Photoshop，依序雙擊：

1. `Apply-Compatibility.command`：更改 bundle ID，並停用 3D 引擎外掛。
2. `Disable-AutoUpdate.command`：停止 AUM 更新檢查、遙測與崩潰回報（可逆，`Restore-AutoUpdate.command` 還原）。
3. `Migrate-Support-Files.command`：把從虛擬機複製出來的 `Library/Application Support/Adobe` 資料夾拖進終端機，腳本會複製上表列出的目錄。已經存在的目錄會略過不動。需要管理員密碼。這些都是你自己安裝的登錄資料，本倉庫不提供。
4. `Install-Unit-Types-Osax.command`：把從虛擬機複製出來的 `Adobe Unit Types.osax` 放到本資料夾，再執行。需要管理員密碼。
5. `Install-macOS26-Fix.command`：在本專案支援的現代 macOS 上一律套用，包括 Sequoia 15 與 macOS 26、Intel 與 Apple Silicon。腳本保留原檔名，需要 Xcode Command Line Tools（`xcode-select --install`），會在本機編譯 `fix/atsfix.c`。

`Launch-CS6-Offline.command` 用 `sandbox-exec` 在斷網狀態下啟動 PS，避免 CS6 連網時要求登入。

所有腳本預設處理 `/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app`；要指定其他路徑時，設定環境變數 `CS6_APP`。

## 還原

- `Restore-Metadata.command`：還原 `Info.plist`，並重新啟用 3D 引擎外掛。
- `Restore-AutoUpdate.command`：把更新器、遙測與崩潰回報元件重新啟用。
- `Uninstall-macOS26-Fix.command`：還原原版主程式，並移除補丁庫。

原檔備份在本資料夾的 `backups/`（不會被提交到 git）。

## 已知限制

- 相容性實測環境包括 Intel Sequoia 15.4.1 與 Apple Silicon（M2）macOS 26.5。Intel Sequoia 15.7.7 已確認會觸發同一處 ATS 字型崩潰，因此安裝步驟也包含字型補丁。列印、影片、Bridge 整合未完整測試。
- 3D 功能已被停用。
- 重裝或覆蓋 CS6 會把 `Disable-AutoUpdate.command` 停用的更新器與遙測元件裝回來，需再執行一次。
- 本倉庫不處理授權或啟用問題。

更早的相容性研究紀錄見 [docs/cs6-macos-compatibility.md](docs/cs6-macos-compatibility.md)。

## License

MIT
