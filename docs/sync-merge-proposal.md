# 設定（opts）同步合併修法提案

> 狀態：**只提案，這次不實作**。設定的合併方式是資料結構層的改動，需另外審。
> 行號以分支 `claude/pulipuli-fix-1`（commit `78a46e4`）為準；之後分支的行號會位移，請以函式名稱為主。

## 一、問題是什麼

「設定」（`opts`）裡裝了很多店家每天在用、而且只存在這裡的資料：

| 欄位 | 內容 |
|---|---|
| `custNotes` | 客人備註（甲床狀況、喜好…） |
| `custCommission` | 每位客人的預設抽成 |
| `sched.days` | 公休日、單日自訂時段 |
| `base` / `addon` / `removal` / `bookSvc` / `expCats` | 服務項目、價目表、支出分類 |
| `commission` | 工作室抽成設定 |
| `look` | 配色（含自訂配色） |
| `store` | 店名、LOGO |

同步時，設定是**整包比較 `updatedAt`（最後修改時間），誰新就整包蓋掉另一邊**：

- `applyRemotePayload()`（目前品牌，第 4107 行）：`if(d.opts&&(d.opts.updatedAt||0)>(opts.updatedAt||0)){opts=d.opts;...}`
- `applyRemotePayload()`（其他品牌，第 4114 行）：同樣的整包比較
- `saveOpts()`（第 1000–1001 行）：**任何**設定變動都會把整包的 `updatedAt` 改成現在時間
- `saveTheme()`（第 1139 行起）：換配色也會走 `saveOpts()`
- 對照：`ensureSched()` 的遷移只寫本機、不推進 `updatedAt`（第 776 行），這部分是對的

所以只要某台裝置「最後動過任何一個設定」，它整包設定就會勝出，另一邊在其他欄位的資料全部被丟掉。

### 最嚴重的情境：新手機第一次同步

1. 舊手機有客人備註，已同步到雲端。
2. 新手機剛打開 App，設定是預設值（沒有客人備註）。
3. 店家在貼權杖之前，先改了任何一個設定（店名、公休日、配色都算）→ 新手機設定的 `updatedAt` 變成「現在」，比雲端新。
4. 新手機第一次同步：雲端設定比較舊 → 被丟掉；新手機把**沒有客人備註的設定**傳上雲端。
5. 舊手機再同步：雲端設定比較新 → 整包蓋掉舊手機 → **舊手機的客人備註、客人抽成、公休日也一起消失**。

紀錄（收入、支出、預約）不受影響，因為紀錄是逐筆用 id 合併的（`mergeRecords()`）。

### 第二個情境：兩台都在用、各改不同設定

舊手機新增小美的備註，同一段時間新手機設了一天公休。誰比較晚存，誰就整包勝出，另一邊的改動不見。這個情境比較少見，但也一樣會掉資料。

## 二、重現步驟

### 手動重現（兩台裝置，或兩個不同的瀏覽器設定檔）

> 請用測試用的 GitHub 帳號和測試權杖，**不要用店裡正式的雲端資料**。

1. 裝置 A：打開 App → 設定 → 雲端同步，貼上測試權杖 → 立即同步。
2. 裝置 A：報表 → 常客排行點「小美」→ 寫備註「甲床薄」→ 儲存；月曆隨便挑一天設為公休 → 回設定按「立即同步」。
3. 裝置 B（全新、從沒打開過 App 的瀏覽器）：打開 App → 設定 → 基本資料，把店名改成「新手機」（**還沒貼權杖**）。
4. 裝置 B：設定 → 雲端同步，貼上同一個測試權杖 → 立即同步。
5. 裝置 A：設定 → 立即同步。
6. 裝置 A：再點開「小美」→ **備註不見了**；剛才設的公休日也恢復營業了。

### 自動重現（Playwright＋假的 Gist 伺服器）

不連真的 GitHub，在測試裡攔截 `api.github.com`，用記憶體模擬一個 Gist。手機尺寸 390×844。結果：

| 步驟 | 結果 |
|---|---|
| A 同步後的雲端 `custNotes` | `{"小美":"甲床薄，不要磨太用力","布丁狗":"喜歡貓眼"}` |
| B 改店名後，本機 `updatedAt` 是否比雲端新 | 是 |
| B 同步後的雲端 `custNotes` / `sched.days` | `{}` / `{}`（被洗掉） |
| A 再同步後的本機 `custNotes` / `custCommission` / `sched.days` | `{}` / `{}` / `{}`（被洗掉） |
| A 的紀錄筆數 | 6（不變，紀錄沒事） |
| console 錯誤 | 無 |

腳本重點（完整版在附錄）：
```js
// 裝置 A：寫入客人備註並同步
opts.custNotes={'小美':'甲床薄，不要磨太用力'}; saveOpts(); await syncNow(true);
// 裝置 B：全新安裝，還沒同步就改店名
opts.store.name='PuliPuli 新手機'; saveOpts(); await syncNow(true);
// 裝置 A 再同步 → opts.custNotes 變成 {}
await syncNow(true);
```

## 三、修法方案

### 方案甲：第一次同步以雲端為準

**改法**
- `syncNow()` 裡，如果本機沒有 `gistId`（這台裝置從沒同步過），而且在雲端找到既有的 Gist，就標記「第一次同步」。
- 第一次同步時呼叫 `applyRemotePayload(remote,{preferRemoteOpts:true})`：雲端有設定的品牌，一律用雲端設定，不比較 `updatedAt`。
- 用雲端設定取代本機時，跳一次說明：「這台手機的設定已改成雲端版本（在同步前做的設定改動沒有保留）」。
- 雲端完全沒有 Gist 時（真正的第一台裝置），照舊建立新的 Gist。

**要動的函式**：`syncNow()`、`applyRemotePayload()`（加一個參數）。

**舊資料要不要搬**：不用。

**風險**
- 只修「新手機第一次同步」，不修「兩台都在用、各改不同設定」。
- 新手機在同步前做的設定改動會被丟掉（通常只是試按，影響很小，而且會明講）。
- 換權杖、清掉瀏覽器資料後重新同步，也算第一次同步，會以雲端為準——這正是我們想要的。
- 如果雲端 Gist 被刪掉（讀到 404），程式會清空 `gistId`、建立新的 Gist，這時候沒有雲端資料可以優先，行為跟現在一樣。

**工時**：約 2～3 小時（含假 Gist 測試）。

### 方案乙：設定拆成子區塊，各自帶修改時間

**改法**
- 設定裡新增一個時間表 `opts.meta`（記錄每個子區塊最後修改時間），逐區塊比較：
  - 逐客人：`custNotes.<客人名>`、`custCommission.<客人名>`
  - 逐日：`sched.days.<日期>`
  - 清單類各自一塊：`base`、`addon`、`removal`、`bookSvc`、`expCats`
  - 其他各自一塊：`commission`、`look`、`store`、`sched.slots`、`sched.footer`、`sched` 其餘外觀欄位
- 刪除要留「墓碑」（刪除記號）：刪掉備註或取消公休時，在 `meta` 記下刪除時間，合併時才知道「是刪掉了」而不是「還沒有」。
- `saveOpts()` 自動比對：保留上次存檔的快照，存檔時逐區塊比對有沒有變，只蓋有變的區塊的時間。這樣**不用改 19 個 `saveOpts()` 和 11 個 `saveSched()` 呼叫點**。
- 新增 `mergeOpts(local,remote)`：逐區塊取時間較新的一邊；`applyRemotePayload()` 改用它，不再整包比較。

**要動的函式**：`saveOpts()`、`applyRemotePayload()`（目前品牌和其他品牌兩處）、新增 `mergeOpts()`、`ensureSched()`（補 `meta`）、`sanitizeOpts()`（認得 `meta`）、`addBrand()`（複製設定時重建 `meta`）。

**舊資料要不要搬**：要，但可以自動搬。舊資料沒有 `meta` 時，把每個區塊的時間都當成舊的整包 `updatedAt`。新手機的預設設定 `updatedAt` 是 0，所以雲端的客人備註會勝出；只有新手機真的改過的區塊（例如店名）才會蓋過雲端。

**風險**
- 改動最大，所有設定畫面都要回歸測試。
- **混用版本**：上線期間如果有一台還在跑舊版，舊版會整包比較，可能把新版的 `meta` 蓋掉。第一批的匯入白名單會丟掉不認得的欄位，`meta` 也會被丟掉；第二批 G 改成保留不認得的欄位後會好一些，但仍建議**所有裝置都更新後再開始用**（GitHub Pages 重新整理就會更新）。
- 同一個區塊兩邊同時改，還是較晚的勝出（例如兩台同時改同一位客人的備註）——這種情況很少，可以接受。
- 兩台裝置時鐘差很多時，時間比較可能不準（現在整包比較也有同樣的問題）。

**工時**：約 1.5～2 天（含遷移、墓碑、假 Gist 雙裝置測試）。

### 方案丙：只對客人備註、客人抽成、公休與單日時段做聯集

**改法**：`applyRemotePayload()` 決定好整包勝出的一方之後，把輸的一方的 `custNotes`、`custCommission`、`sched.days` 裡、勝方沒有的項目補進勝方。同一個 key 兩邊都有時，以勝方為準。

**要動的函式**：`applyRemotePayload()`（兩處）。

**舊資料要不要搬**：不用。

**風險**
- **刪不掉**：在一台刪掉備註、或把公休「恢復營業」，另一台同步時又會補回來。公休日恢復不了營業，會直接影響 IG 預約表，這個問題很明顯。要解決就得加墓碑，那等於做了一半的方案乙。
- 服務項目、抽成設定、配色仍是整包蓋掉，新手機情境下抽成設定一樣會被預設值洗掉。

**工時**：約半天；加上墓碑約 1 天。

### 比較表

| | 甲：第一次以雲端為準 | 乙：子區塊各自比較 | 丙：三個欄位聯集 |
|---|---|---|---|
| 修好新手機情境 | ✅ | ✅ | 部分（備註、抽成、公休補回來；服務項目、抽成設定、配色仍被洗掉） |
| 修好兩台各改不同設定 | ❌ | ✅ | 部分（只限三個欄位） |
| 刪除能正確同步 | 不變 | ✅（有墓碑） | ❌（會復活） |
| 舊資料搬移 | 不用 | 自動搬 | 不用 |
| 風險 | 低 | 中（改動大、混用版本） | 中（刪不掉） |
| 工時 | 2～3 小時 | 1.5～2 天 | 半天～1 天 |

## 四、建議

**建議：先做甲，馬上止血；接著做乙，根治。不做丙。**

理由：
1. 這次查到最嚴重、也最可能發生的就是「新手機第一次同步」（換手機、多一台平板都會遇到）。甲只改兩個函式、不用搬資料、風險低，幾個小時內就能上線，正好擋住這個情境。
2. 乙才能真正解決「兩台都在用」的問題，刪除也能正確同步。但改動大，需要完整回歸測試，也要確保所有裝置一起更新。先上甲，乙可以慢慢做、慢慢審。甲上線後也不會跟乙衝突：做完乙之後，甲的「第一次以雲端為準」可以留著當額外保險。
3. 丙看起來簡單，但「恢復營業又被改回公休」這類刪不掉的問題會直接影響店家每天用的預約表，而且服務項目和抽成設定還是會被洗掉，不划算。
4. 程式改好之前，先請店家照這個順序設定新手機：**先貼權杖、按立即同步，同步完成之後再改任何設定**；換手機前先「匯出 JSON 備份」。

**如果已經被洗掉**：GitHub Gist 會保留每次修改的歷史版本（revisions）。到 Gist 頁面的 Revisions 可以找到被洗掉之前的版本，把裡面的 `custNotes` 等內容找回來（這一步要由店家本人登入 GitHub 操作）。

## 附錄：自動重現腳本（Playwright）

需要一個本機 HTTP 伺服器提供 `index.html`；`open()` 是測試輔助函式，負責開 390×844 手機視窗、固定時鐘、寫入測試資料。

```js
const F='pulipuli-data.json';
const gist={exists:false,content:'',stamp:0};
async function mockGitHub(page){
  await page.route('https://api.github.com/**',async route=>{
    const req=route.request(),u=new URL(req.url()),m=req.method();
    const body=()=>({id:'g1',updated_at:'v'+gist.stamp,files:{[F]:{content:gist.content,truncated:false}}});
    if(m==='GET'&&u.pathname==='/gists')return route.fulfill({json:gist.exists?[{id:'g1',files:{[F]:{}}}]:[]});
    if(m==='GET'&&u.pathname==='/gists/g1')return gist.exists?route.fulfill({json:body()}):route.fulfill({status:404,json:{}});
    if(m==='POST'||m==='PATCH'){gist.exists=true;gist.content=JSON.parse(req.postData()).files[F].content;gist.stamp++;return route.fulfill({json:body()});}
    return route.fulfill({status:400,json:{}});
  });
  await page.evaluate(()=>{syncCfg.token='fake-test-token';saveSync();});   // 假權杖，不連真的 GitHub
}
// 裝置 A（有測試資料）
const A=await open('index.html');
await A.page.evaluate(()=>{opts.custNotes={'小美':'甲床薄，不要磨太用力'};opts.sched.days['2026-11-20']={off:true};saveOpts();});
await mockGitHub(A.page); await A.page.evaluate(()=>syncNow(true));
// 裝置 B（全新），同步前先改店名
const B=await open('index.html',{seed:false});
await B.page.clock.runFor(60000);
await B.page.evaluate(()=>{opts.store.name='PuliPuli 新手機';saveOpts();});
await mockGitHub(B.page); await B.page.evaluate(()=>syncNow(true));
// 裝置 A 再同步
await A.page.evaluate(()=>syncNow(true));
console.log(await A.page.evaluate(()=>opts.custNotes));   // → {}
```
