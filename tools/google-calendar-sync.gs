/**
 * PuliPuli 預約 → Google 日曆（單向同步）
 *
 * 做什麼：每 15 分鐘讀一次 PuliPuli 的雲端備份，把兩家店的預約
 *         寫進一個專用的 Google 日曆（只新增、修改、刪除這個日曆裡由本程式建立的活動）。
 * 放哪裡：andyluh831116 的 Google Apps Script（script.google.com）。
 * 第一次：把 BACKUP_URL 換成雲端備份的網址，選 setup 按「執行」，照畫面按同意。
 * 注意：只會從 App 同步到日曆。在日曆上改的內容，下次同步會被蓋回 App 的樣子。
 */
const CONFIG = {
  BACKUP_URL: '在這裡貼上雲端備份網址',     // https://gist.githubusercontent.com/帳號/備份ID/raw/pulipuli-data.json
  CALENDAR_NAME: '恩恩預約（PuliPuli／OUO FISH+）',
  DURATION_MIN: 120,   // 有時間的預約，在日曆上佔多久（分鐘）
  PAST_DAYS: 30,       // 同步範圍：過去幾天
  FUTURE_DAYS: 180,    // 同步範圍：未來幾天
  EVERY_MIN: 15,       // 多久同步一次，只能填 1、5、10、15、30
  PREFIX: {'ouo_fish.nail': 'OUO', 'Pulipuli.studio': 'PULI'}  // 標題前面的店名縮寫（照 App 裡的店名）；沒列到的店用完整店名
};
const TZ_OFFSET = '+08:00';
const TAG = 'ppKey';
const TAG_HASH = 'ppHash';

/* 第一次執行：建立專用日曆、設定每 15 分鐘自動同步，並馬上同步一次 */
function setup() {
  const cal = getCalendar_();
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'sync')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('sync').timeBased().everyMinutes(CONFIG.EVERY_MIN).create();
  sync();
  Logger.log('設定完成：日曆「' + cal.getName() + '」，每 ' + CONFIG.EVERY_MIN + ' 分鐘同步一次。');
}

/* 停用自動同步（日曆和裡面的活動都保留） */
function stopSync() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'sync')
    .forEach(t => ScriptApp.deleteTrigger(t));
  Logger.log('已停用自動同步。');
}

function sync() {
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(30000)) return;
  try {
    const payload = fetchBackup_();
    const now = new Date();
    const from = new Date(now.getTime() - CONFIG.PAST_DAYS * 864e5);
    const to = new Date(now.getTime() + CONFIG.FUTURE_DAYS * 864e5);
    const wanted = buildWanted(payload, ymd_(from), ymd_(to));
    const cal = getCalendar_();
    const res = applyToCalendar(cal, wanted, from, to);
    Logger.log('同步完成：新增 ' + res.created + '、更新 ' + res.updated + '、刪除 ' + res.deleted + '、沒變 ' + res.same);
  } finally {
    lock.releaseLock();
  }
}

function fetchBackup_() {
  if (!/^https:\/\//.test(CONFIG.BACKUP_URL)) throw new Error('還沒填 BACKUP_URL');
  const resp = UrlFetchApp.fetch(CONFIG.BACKUP_URL, { muteHttpExceptions: true, headers: { 'Cache-Control': 'no-cache' } });
  if (resp.getResponseCode() !== 200) throw new Error('讀不到雲端備份，HTTP ' + resp.getResponseCode());
  const payload = JSON.parse(resp.getContentText('UTF-8'));
  if (!payload || !Array.isArray(payload.brands) || !payload.data) throw new Error('雲端備份格式不對，這次不同步');
  return payload;
}

function getCalendar_() {
  const props = PropertiesService.getScriptProperties();
  const id = props.getProperty('calendarId');
  let cal = id ? CalendarApp.getCalendarById(id) : null;
  if (!cal) {
    cal = CalendarApp.createCalendar(CONFIG.CALENDAR_NAME, { timeZone: 'Asia/Taipei' });
    props.setProperty('calendarId', cal.getId());
  }
  return cal;
}

/* 從雲端備份算出「日曆上應該有哪些活動」。純計算，不碰日曆，方便測試 */
function buildWanted(payload, fromYmd, toYmd) {
  const out = {};
  (payload.brands || []).forEach(b => {
    if (!b || b.deleted) return;
    const d = payload.data[b.id];
    if (!d || !Array.isArray(d.records)) throw new Error('雲端備份缺少「' + (b.name || b.id) + '」的資料，這次不同步');
    const store = (d.opts && d.opts.store && d.opts.store.name) || b.name || '店';
    const pre = CONFIG.PREFIX[store] || store;
    d.records.forEach(r => {
      if (!r || r.deleted || !r.date || r.date < fromYmd || r.date > toYmd) return;
      let name, time, paid = false;
      if (r.type === 'booking') { name = r.name; time = r.time; }
      else if (r.type === 'income' && r.bkTime) { name = r.customer || r.bkName; time = r.bkTime; paid = true; }
      else return;
      const ev = {
        key: b.id + ':' + r.id,
        title: '[' + pre + '] ' + (name || '客人') + (paid ? '（已結帳）' : ''),
        date: r.date,
        time: /^\d{1,2}:\d{2}$/.test(time || '') ? (time.length === 4 ? '0' + time : time) : '',
        desc: descOf_(r, store, paid)
      };
      ev.hash = JSON.stringify([ev.title, ev.date, ev.time, ev.desc, CONFIG.DURATION_MIN]);
      out[ev.key] = ev;
    });
  });
  return out;
}

function descOf_(r, store, paid) {
  const lines = ['店家：' + store];
  if (paid) {
    const bd = r.breakdown || {};
    const items = [];
    if (bd.base && bd.base.name) items.push(bd.base.name);
    if (bd.removal && bd.removal.name) items.push(bd.removal.name);
    (bd.addons || []).forEach(a => a && a.name && items.push(a.name));
    if (items.length) lines.push('項目：' + items.join('＋'));
    if (r.note) lines.push('備註：' + r.note);
  } else {
    if (r.channel) lines.push('管道：' + r.channel);
    const pl = r.plans || (r.plan ? [r.plan] : []);
    if (pl.length) lines.push('項目：' + pl.map(p => p && p.name).filter(Boolean).join('＋'));
    if (r.planNote) lines.push('備註：' + r.planNote);
    if (r.deposit > 0) lines.push('訂金：$' + r.deposit);
  }
  lines.push('（由 PuliPuli 自動同步，在這裡修改會被蓋掉）');
  return lines.join('\n');
}

/* 照「應該有的活動」去改日曆；只動帶有本程式標記的活動 */
function applyToCalendar(cal, wanted, from, to) {
  const res = { created: 0, updated: 0, deleted: 0, same: 0 };
  const existing = cal.getEvents(from, to);
  const seen = {};
  const ops = [];
  existing.forEach(e => {
    const key = e.getTag(TAG);
    if (!key) return;                     // 不是本程式建的，不動
    const w = wanted[key];
    if (!w || seen[key]) { ops.push(() => { e.deleteEvent(); res.deleted++; }); return; }
    seen[key] = true;
    if (e.getTag(TAG_HASH) === w.hash) { res.same++; return; }
    ops.push(() => { e.deleteEvent(); createEvent_(cal, w); res.updated++; });
  });
  /* 保險：備份讀到的預約是 0 筆、日曆上卻有，多半是讀錯，這次不刪 */
  const wantedCount = Object.keys(wanted).length;
  const managed = existing.filter(e => e.getTag(TAG)).length;
  if (wantedCount === 0 && managed > 0) throw new Error('備份裡沒有任何預約，但日曆上有 ' + managed + ' 筆，先不動');
  Object.keys(wanted).forEach(k => { if (!seen[k]) ops.push(() => { createEvent_(cal, wanted[k]); res.created++; }); });
  ops.forEach((op, i) => { op(); if (i % 10 === 9) Utilities.sleep(500); });
  return res;
}

function createEvent_(cal, w) {
  let e;
  if (w.time) {
    const start = new Date(w.date + 'T' + w.time + ':00' + TZ_OFFSET);
    const end = new Date(start.getTime() + CONFIG.DURATION_MIN * 60000);
    e = cal.createEvent(w.title, start, end, { description: w.desc });
  } else {
    e = cal.createAllDayEvent(w.title, new Date(w.date + 'T00:00:00' + TZ_OFFSET), { description: w.desc });
  }
  e.setTag(TAG, w.key);
  e.setTag(TAG_HASH, w.hash);
  return e;
}

function ymd_(d) {
  return Utilities.formatDate(d, 'Asia/Taipei', 'yyyy-MM-dd');
}
