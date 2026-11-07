# Photoshop CS6 on newer macOS

查核日期：2026-11-07。研究對象為 Mac 版 Photoshop CS6；安裝、主程式啟動、授權及檔案讀寫分開判定。下列跨版本資料為網路第一手回報；本機目前結果另列於下方。

最終目標是在本機 Intel Sequoia 原生運行 Photoshop CS6。Mojave 虛擬機僅用於完成原版安裝與 13.0.6 更新，確認程式能開啟即可；後續相容性修復與操作驗證都在本機進行。

安裝模式：使用者指定先以試用模式安裝，集中處理 Sequoia 相容性。

網路限制：Mojave 測試時先斷開虛擬網卡；本機提供 `sandbox-exec` 離線啟動器，限制 Photoshop 及其子程序連線，保留主機其他程式的網路。使用者說明：CS6 在連網啟動時會強制要求登入帳號。

執行路線：從 Mojave 取得完整安裝內容與必要相依檔案，遷移至本機 Sequoia，直接執行套件內的 64 位元主程式，依實際錯誤逐項修復。虛擬機內可啟動只代表安裝階段完成；本機 Sequoia 可啟動且完成基本操作，才是最終完成條件。

## Evidence by macOS version

| macOS | 第一手證據 | 可用於後續測試的線索 |
| --- | --- | --- |
| Catalina 10.15 | 2019 年多名使用者回報 13.0.6 可從套件內執行；也有人立即當機或在匯出時失敗。 | 先測直接執行主程式，再分別測 PSD 與 JPEG 儲存。 [MacRumors](https://forums.macrumors.com/threads/launching-photoshop-cs6-on-catalina-success.2204454/) |
| Big Sur 11 | 有 Intel 與 M1 的成功回報，但個別案例有檔案對話框及快取問題。 | 保留安裝完成的相依資料與偏好設定。 [Adobe Community](https://community.adobe.com/questions-712/photoshop-cs6-not-opening-in-big-sur-update-for-mac-1111753) |
| Monterey 12 | 作者聲稱可用同樣方式啟動，未提供完整功能驗證。 | 可作啟動線索，不能據此判定穩定。 [Bonyo Bonev](https://bonevphotography.com/blog/?post=working-photoshop-and-illustrator-cs6-under-macos-catalina-big-sur-monterey) |
| Ventura 13 | 一位使用者回報在 OCLP 的 2012 MacBook Pro 上運行 CS6，沒有修復步驟。 | 證據較弱，仍須本機驗證。 [Reddit 原作者](https://www.reddit.com/r/macbookpro/comments/16onwot/mid2012_macbook_pro_runs_ventura_amazingly/) |
| Sonoma 14.4 | 2024 年回報指出舊 AdobeCoolType.framework 不相容，換用 Acrobat 2020 的版本後恢復先前有限功能。 | 將字型框架列為候選修復點；替換前須核對架構、相依符號與版本。 [Adobe Community](https://community.adobe.com/questions-712/photoshop-cs6-not-opening-in-big-sur-update-for-mac-1111753/index1.html) |
| Sequoia 15.1 Intel | 2024 年實測：Finder 拒絕啟動，但直接執行 Mach-O 可到 Adobe 的缺少元件提示；作者未完整安裝。 | 證明有繼續檢查的價值；尚非可編輯、可儲存的成功案例。 [Hacker News 原留言](https://news.ycombinator.com/item?id=42148434) |

## Specific findings

直接啟動的候選位置為：

```sh
"/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app/Contents/MacOS/Adobe Photoshop CS6"
```

這個方式已有 Catalina 實測支持；是否足以在本機 Sequoia 使用，仍須檢驗。

Big Sur 個案建議先在舊系統開啟測試檔，保留最近使用清單，並備份 `/Library/Application Support/Adobe`。其限制包括開啟／另存對話框當機，以及退出後 `SLCache` 損壞；作者以原始備份恢復快取。這些均為個案，不能直接套用為本機必需的修改。APE、OOBE 也只應在錯誤明確指向它們時個別隔離，不應整包刪除。[原始步驟與限制](https://community.adobe.com/questions-712/photoshop-cs6-not-opening-in-big-sur-update-for-mac-1111753)

Mojave 的 2021-002 安全性更新後，也有人藉啟動輸出定位到外掛並移除，恢復啟動。這支持先讀當機記錄，再處理確切外掛的做法。[原作者修復回報](https://forums.macrumors.com/threads/macos-mojave-security-update-2021-002-and-photoshop-cs6-crashes.2291376/)

Adobe 官方說明舊版本含 32 位元安裝及授權元件，未為 Big Sur 設計或測試；這與上述非官方的局部成功案例需分開理解。[Adobe 官方說明](https://helpx.adobe.com/photoshop/kb/photoshop-and-macos-big-sur.html)

## Current local result

- Mojave 已完成 CS6 試用安裝、一次開啟確認及官方 13.0.6 更新；程式與必要支援資料已移至本機。
- 本機主程式為 x86_64，已將 Bundle Identifier 改為 `local.PhotoshopCS6` 並登錄 Launch Services；版本號未改。
- 曾出現 Application Manager 遺失／損壞提示，之後使用者自行處理並回報「已經可以用了」。未把完整成功歸因於單一調整，也未由代理完成所有功能驗證。
- 未替換 CoolType。保留所有預設集、濾鏡與語系；精簡 34 個通用二進位檔的非 x86_64 切片，節省約 41.2 MiB；每一保留切片皆以 SHA-256 比對一致。
- 另將約 44.4 MiB 的重複預設材質改成 APFS 共享區塊副本，保留兩個檔案與完整內容；移除四個 `.DS_Store`。
- `cs6-sequoia-repair` 為可另行發布的設定／腳本資源包；`cs6-sequoia-installed-backup` 為私人完整還原包，包含 Adobe 程式與本機授權／設定資料，不應公開發布。
- 完整還原包包含檔案、校驗值與無參數還原腳本，下次可直接還原，無需 Mojave。尚未在乾淨系統實測還原，跨機授權與其他系統版本不作保證。

## Local donor candidate

本機只讀檢查發現已安裝 Acrobat DC 25.001.20476，以下框架包含 x86_64 與 arm64：

`/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Frameworks/AdobeCoolType.framework`

目前僅確認架構，不代表已驗證可供 CS6 使用。網路案例採用 Acrobat 2020；本機版本較新，仍需比對匯出符號、動態相依及實際錯誤後才決定是否測試替換。

靜態檢查補充：本機 CoolType 版本為 10.0.3.56752，Intel 切片的最低系統為 macOS 10.15；動態依賴列出的均為 Apple 系統框架／函式庫。因此它只列入較新 macOS 的候選測試，Mojave 基準環境保留 CS6 原框架。這仍不能證明 ABI 與 CS6 相容。
