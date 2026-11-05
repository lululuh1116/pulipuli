# PuliPuli 美甲記帳

給美甲工作室用的記帳網頁 App。手機瀏覽器打開就能用，不用安裝、不用註冊帳號。

這份說明分兩部分：

- [第一部分：給店家看](#第一部分給店家看)
- [第二部分：給接手的工程師看](#第二部分給接手的工程師看)

> 本文每一點都對照過 `index.html` 的程式（以分支 `claude/pulipuli-fix-2` 為準）。標「待確認」的是程式裡看不出來、或需要 LULU 補充的地方。

---

## 第一部分：給店家看

### 這是什麼

一個記錄美甲工作室收入、支出、預約的小工具。資料存在手機瀏覽器裡，另外可以備份到你自己的 GitHub 帳號（Gist），換手機時接回來。

### 怎麼打開

- 網址：**待 LULU 補**（這個程式庫裡沒有 GitHub Pages 的設定檔可以查。如果有開 GitHub Pages，網址通常長得像 `https://lululuh1116.github.io/pulipuli/`，**待確認**）
- 建議用手機瀏覽器打開後「加入主畫面」，之後就像 App 一樣點開。

### 主要功能

畫面下方有四個分頁：**月曆、預約表、總紀錄、報表**。

| 功能 | 說明 |
|---|---|
| 月曆 | 每天的收入、支出、預約一覽，點日期就能記帳。 |
| 預約表（IG 預約表產圖） | 設定每天可預約的時段、公休日，按「產生本月 IG 預約表預覽圖」會做出一張 1080×1920 直式圖片，預覽後下載，直接發 IG 限動。可以換背景圖、字體、配色。 |
| 總紀錄 | 所有收入、支出、預約的清單。 |
| 報表 | 月報表等統計（收支圓餅圖、客流量長條等），可以匯出成報表圖片。 |
| 多品牌 | 同一個人可以開好幾個品牌，每個品牌的紀錄和設定分開；雲端備份共用一份。刪除品牌前會問兩次，**刪了之後其他手機同步後也會一起刪掉**。 |
| 抽成 | 每個品牌可以開「工作室抽成」：設定預設抽成比例和每月上限。每位客人可以有自己的預設比例，每次結帳也能單筆改。原本記的收入金額不會被改掉，結帳當下的比例會跟著那筆存起來，之後改預設值不會重算舊帳。 |
| 客人備註 | 每位客人可以寫備註（例如甲床狀況、喜好），也可以設這位客人的預設抽成。 |
| 記帳日期可改 | 記帳畫面上方的日期可以點開改成別天（補記、記錯日期時用）。 |

### 資料存在哪裡

1. **這台手機的瀏覽器裡**（主要的那份）。不同手機、不同瀏覽器各有各的，互相看不到。
2. **你自己的 GitHub Gist**（雲端備份，要自己設定才有）。
   - 設定方法：到 GitHub → Settings → Developer settings → Personal access tokens 建立 classic token，**只勾 gist 權限**，貼到 App 的「設定 → 雲端同步」。
   - 設好之後，每次改資料約 2 秒後會自動同步；每次打開 App 也會同步一次；也可以手動按同步。
   - 權杖只存在這台手機的瀏覽器裡，不會傳給別人。**權杖等於鑰匙，不要給別人看。**
3. **自己手動匯出的 JSON 備份檔**（設定 → 雲端同步 → 「匯出 JSON 備份」）。包含所有品牌。

### 換手機怎麼搬資料

**方法一：用雲端同步（建議）**

1. 舊手機先確認同步過（設定裡會顯示「上次同步：某某時間」）。
2. 新手機打開 App，**先不要改任何設定**，直接到「設定 → 雲端同步」貼上權杖（可以是同一把，或在 GitHub 再建一把新的）。
3. 按同步。App 會自己找到你 GitHub 裡的那份備份並接回來。
4. 新手機第一次同步時，**設定（服務項目、價目、客人備註、公休日、抽成設定、配色、店名等）會以雲端為準**；如果新手機在同步前改過設定，那些修改不會保留，畫面上會跳一則通知告訴你。收入、支出、預約紀錄則是一筆一筆合併，兩邊都會留著。

**方法二：用 JSON 備份檔**

1. 舊手機「匯出 JSON 備份」，把檔案傳到新手機。
2. 新手機「匯入 JSON」，選「合併（預設）」即可。
   - 另一個選項「以備份為準（還原已刪除）」：備份裡還在、但這台已刪除的紀錄和品牌會被救回來，同步後其他手機也會跟著恢復。不確定就用「合併」。

**注意：這些不會跟著搬過去**（只存在原本那台手機）：

- 主題背景圖片、IG 預約表的背景圖片 → 新手機要重新上傳一次。
- 權杖 → 新手機要重新貼。

### 哪些事會讓資料不見

| 情況 | 會怎樣 | 怎麼避免 |
|---|---|---|
| 清除瀏覽器資料／網站資料、清快取時勾到「網站資料」 | 這台手機上的資料全部消失 | 先設好雲端同步，清掉後重新貼權杖就能接回來 |
| **沒設同步就換手機**、手機壞掉或遺失 | 資料救不回來 | 一定要設雲端同步，或定期匯出 JSON 備份 |
| 用無痕模式 | 關掉視窗資料就沒了 | 不要用無痕模式記帳 |
| 新手機第一次同步前先改了設定 | 那些設定修改會被雲端蓋掉（紀錄不受影響） | 新手機先同步，再改設定 |
| 兩台手機同時在改**設定** | 比較晚改的那台，整包設定會蓋掉另一台（例如 A 改客人備註、B 改公休日，最後只會留一台的） | 盡量只在一台改設定；紀錄不受影響 |
| 在一台刪除品牌 | 所有手機同步後都會刪掉。如果別台有還沒同步的紀錄，App 會自動下載一個救援檔（`pulipuli-rescue-…json`），之後可用「匯入 JSON」救回 | 刪品牌前三思 |
| 手動去 GitHub 改 Gist 內容 | 可能壞掉 | 不要手動改 |
| 長時間沒打開（iPhone Safari 可能會清掉網站資料） | **待確認**（程式裡無法確認，這是瀏覽器本身的規則） | 有設雲端同步就能接回 |

---

## 第二部分：給接手的工程師看

### 檔案結構

```
index.html                    整個 App（HTML + CSS + JS 都在這一個檔，約 4,500 行，沒有建置步驟）
docs/sync-merge-proposal.md   設定（opts）同步合併的修法提案（方案甲已實作、方案乙待審）
README.md                     本文件
```

- 沒有後端、沒有套件、沒有 build。直接用瀏覽器開 `index.html` 就能跑。
- 雲端同步直接從瀏覽器呼叫 GitHub REST API（`gh()` 函式，`https://api.github.com`）。
- 歷史上另一個分支有 `v2/`（React/TS 改寫）的檔案，不在這個分支，跟目前的 `index.html` 無關（**待確認**是否還在進行）。

### 資料怎麼存（localStorage）

規則寫在 `index.html` 的「資料」區（`LS_REC`、`K_REC()` 等常數）：**每個品牌各一份，key 一律是「基底名__品牌id」**。

| key | 內容 | 會不會同步到 Gist |
|---|---|---|
| `pp_brands` | 品牌清單 `[{id, name, updatedAt, deleted?}]` | 會 |
| `pp_curBrand` | 目前選的品牌 id | 不會 |
| `pp_records__<品牌id>` | 這個品牌的所有紀錄（收入 `income`、支出 `expense`、預約 `booking`） | 會 |
| `pp_options__<品牌id>` | 這個品牌的設定 `opts`（服務項目、價目、支出分類、預約時段 `sched`、配色 `look`、店名 `store`、抽成 `commission`、客人備註 `custNotes`、客人抽成 `custCommission` 等） | 會 |
| `pp_theme__<品牌id>` | 主題背景圖片與字體 `{image, font}` | **不會**（只在本機） |
| `pp_schedbg__<品牌id>` | IG 預約表背景圖片（dataURL） | **不會**（只在本機） |
| `pp_sync` | 同步設定 `{token, gistId, last, syncedGist}`，**含權杖，除錯時不要印出來** | 不會 |

- 舊版單一品牌的 key（`pp_records`、`pp_options`、`pp_theme`、`pp_schedbg`）啟動時會自動搬到 `…__b_main`（`b_main` 是預設品牌 id）。
- 每筆紀錄有 `id`、`updatedAt`；刪除不是真的刪，而是標 `deleted:true`（墓碑），讓刪除能同步到別台。墓碑保留 1 年（`TOMB_KEEP_MS = 365 天`）後才真正清掉（`purgeDeleted()`、`purgeBrands()`）。品牌也一樣。
- `saveOpts()` 只要設定有任何變動，就把**整包** `opts.updatedAt` 改成現在。這是下面「設定整包比較」問題的根源。
- 多個分頁同時開：靠 `storage` 事件，另一個分頁改了紀錄會逐筆合併進來；改了設定或品牌則整份換成新的。

### 雲端同步怎麼運作（照 `syncNow()` 實際寫法）

- Gist 檔名：`pulipuli-data.json`（`GIST_FILE`），私人 Gist（`public:false`）。
- 內容格式：`{brands, data: {<品牌id>: {records, opts}}, syncedAt}`。舊格式 `{records, opts}` 會被 `normalizePayload()` 自動包成 `b_main`。
- 觸發時機：資料變動後 `scheduleSync()` 等 2 秒；App 啟動時若有權杖會同步一次；手動按「同步」。同步中又有變動會排隊，結束後 0.5 秒再跑一次。

**`syncNow()` 的流程：**

1. **下載**：有 `gistId` 就抓那份；抓到 404 就清掉 `gistId`。沒有 `gistId` 時列出使用者的 Gist（最多 100 個），找有 `pulipuli-data.json` 的那份接回來（換手機自動接回就是靠這個）。
2. **合併**：`applyRemotePayload(remote, {preferRemoteOpts: first})`
   - 外部資料先經過 `sanitizePayload()` 清洗（金額轉數字、色碼驗證、時間格式驗證等）。不認得的欄位原樣保留但不畫進畫面；不認得的紀錄類型也原樣保留、不顯示（給新版欄位向下相容用）。
   - **品牌**（`mergeBrands()`）：用 id 對，`updatedAt` 較新者勝。被別台刪掉的品牌，本機資料一併清掉；清之前如果本機有「上次同步之後」新增或修改的紀錄，先自動下載救援 JSON（`rescueDeletedBrand()`）。
   - **紀錄**（`mergeRecords()`）：用 id 逐筆對，`updatedAt` 較新者勝（含刪除墓碑）。兩邊各自新增的紀錄都會留著。
   - **設定 opts**：**整包比較**。雲端那份的 `updatedAt` 比本機新，就整包換成雲端的；否則保留本機的。
   - **方案甲（已實作）：第一次同步以雲端為準。** `first = (prevGist !== syncCfg.gistId)`，`prevGist` 是 `syncCfg.syncedGist`（這台上次成功對到的 Gist；舊版沒有這欄的，同步過就當作已對到目前 `gistId`）。`first` 為真時，雲端有的設定**不比時間，一律以雲端為準**；若本機設定內容不同（`stableStr()` 比較，忽略 `updatedAt`），會跳一則常駐通知告訴店家哪些品牌的設定被換掉。紀錄仍照常逐筆合併。
3. **上傳前二次確認**：再抓一次 Gist，若 `updated_at` 跟剛下載時不同（別台搶先上傳了），把新的內容再合併一次（這次用一般規則，不是方案甲）。
4. **上傳**：整包打包所有品牌（`collectAll()`），沒有 Gist 就新建，有就 PATCH 覆蓋。
5. 記錄 `syncCfg.last = 打包當下的時間`、`syncCfg.syncedGist = gistId`。

**匯入 JSON** 也走 `applyRemotePayload()`：預設「合併」；「以備份為準」(`restoreDeleted`) 會把備份裡還在、本機已刪除的紀錄和品牌時間改成現在，讓它蓋過刪除標記。

### 已知問題

1. **兩台都在用時，設定仍是整包比較。** 方案甲只處理「新手機第一次同步」。之後兩台各改不同設定（例如 A 改客人備註、B 改公休日），最後改的那台整包勝出，另一台在其他欄位的修改會不見。紀錄不受影響。
2. **方案乙**（設定改成分欄位／分項合併）的提案寫在 [`docs/sync-merge-proposal.md`](docs/sync-merge-proposal.md)，**待審、尚未實作**。
3. 背景圖片（`pp_theme__*` 的 image、`pp_schedbg__*`）不同步，換手機要重新上傳。
4. 同步是「下載 → 合併 → 上傳整包」，上傳前雖有二次確認，但二次確認和上傳之間仍有很短的空檔，兩台同時上傳理論上仍可能互相覆蓋（下次同步時紀錄會逐筆合併回來，設定則照整包規則）。**待確認**實際發生頻率。
5. 找既有 Gist 時只看前 100 個 Gist；使用者 Gist 很多時可能找不到（**待確認**是否需要分頁處理）。

### 怎麼在本機測（Playwright）

這個程式庫**目前沒有放測試腳本**，以下是手動跑的方法：

1. 在程式庫資料夾開一個本機伺服器：

   ```bash
   python3 -m http.server 8000
   ```

2. 用 Playwright 開 `http://localhost:8000/index.html`，例如（存成任意 `.js` 檔，用 `node` 跑）：

   ```js
   const { chromium } = require('playwright');
   (async () => {
     const browser = await chromium.launch();
     const page = await browser.newPage({ viewport: { width: 390, height: 844 } }); // 手機尺寸
     await page.goto('http://localhost:8000/index.html');
     // 讀 localStorage 檢查資料（不要印出 pp_sync，裡面有權杖）
     const brands = await page.evaluate(() => localStorage.getItem('pp_brands'));
     console.log(brands);
     await page.screenshot({ path: 'shot.png' });
     await browser.close();
   })();
   ```

3. 測試注意事項：
   - **不要在測試裡貼真的權杖、不要連真實的 Gist**，以免動到店家的正式資料。要測同步，請用 `page.route('https://api.github.com/**', …)` 攔截 API，回傳假的 Gist 內容。
   - 每次 `browser.newPage()`（新的 context）localStorage 都是空的，等於一台新手機；要模擬「兩台手機」就開兩個 context。
   - 可用 `page.evaluate(() => localStorage.setItem('pp_records__b_main', JSON.stringify([...])))` 預先塞假資料，再 `page.reload()`。
