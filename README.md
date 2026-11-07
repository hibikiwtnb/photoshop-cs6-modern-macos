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
| 缺少 Adobe Unit Types | 新系統上沒有這個 scripting addition | `Install-Unit-Types-Osax.command` |
| **macOS 26：存檔（如 JPG）時崩潰** | `ATSFontIteratorReset` 在 macOS 26 上一呼叫就崩潰，CoolType 建字型清單時必定觸發 | `Install-macOS26-Fix.command` |
| **macOS 26：每次啟動後首次存檔慢約 20 秒** | CoolType 用 `exchangedata()` 儲存字型快取，APFS 不支援，快取永遠是 0 位元組 | `Install-macOS26-Fix.command` |

macOS 26 的兩個問題的技術細節見 [docs/macos26-font-fix.md](docs/macos26-font-fix.md)。

## 使用方式

先退出 Photoshop，依序雙擊：

1. `Apply-Compatibility.command`：更改 bundle ID，並停用 3D 引擎外掛。
2. `Install-Unit-Types-Osax.command`：先從原本安裝 CS6 的電腦（或虛擬機）的 `/Library/ScriptingAdditions/` 複製 `Adobe Unit Types.osax`，放到本資料夾，再執行。執行時需要輸入管理員密碼。
3. `Install-macOS26-Fix.command`（macOS 26 才需要）：需要 Xcode Command Line Tools（`xcode-select --install`），會在本機編譯 `fix/atsfix.c`。

`Launch-CS6-Offline.command` 用 `sandbox-exec` 在斷網狀態下啟動 PS，避免 CS6 連網時要求登入。

所有腳本預設處理 `/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app`；要指定其他路徑時，設定環境變數 `CS6_APP`。

## 還原

- `Restore-Metadata.command`：還原 `Info.plist`，並重新啟用 3D 引擎外掛。
- `Uninstall-macOS26-Fix.command`：還原原版主程式，並移除補丁庫。

原檔備份在本資料夾的 `backups/`（不會被提交到 git）。

## 已知限制

- 實測環境：Intel Sequoia 15.4.1，以及 Apple Silicon（M2）macOS 26.5。開檔、裁切、存 JPG 與文字工具可用；列印、影片、Bridge 整合未完整測試。
- 3D 功能已被停用。
- 本倉庫不處理授權或啟用問題。

更早的相容性研究紀錄見 [docs/cs6-macos-compatibility.md](docs/cs6-macos-compatibility.md)。

## License

MIT
