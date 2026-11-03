.pragma library

// Profile arithmetic. Everything here is pure: each function either returns a
// new profile object or a plain summary. QML replaces the whole profile on
// every mutation so bindings that read it re-evaluate.

var VERSION = 2

// Keep in sync with LANGUAGES in Code.js. The validator lives in this file and
// importing Code.js from here would create a load-order surprise, so the ids
// are duplicated on purpose — a mismatch only ever falls back to JavaScript.
var CODE_LANGS = ["javascript", "python", "typescript", "shell", "css", "sql"]

var DEFAULT_SETTINGS = {
  sound: true,
  volume: 0.32,
  liveWpm: true,
  liveAcc: true,
  caretBlink: true,
  caretStyle: "line",
  strict: false,
  fontSize: 1,
  showKeyboard: true,
  punctuation: false,
  numbers: false,
  testMode: "time",
  testAmount: 30,
  quoteLength: "medium",
  codeLang: "javascript",
  dailyGoalWpm: 20,
  dailyGoalAcc: 90
}

var ACHIEVEMENTS = [
  { id: "first-lesson", name: "First steps", desc: "Complete one lesson", hint: "Finish any lesson in Learn" },
  { id: "five-lessons", name: "Getting warm", desc: "Complete five lessons", hint: "Five lessons down" },
  { id: "all-lessons", name: "Graduate", desc: "Complete the whole curriculum", hint: "Finish every lesson" },
  { id: "perfect", name: "Flawless", desc: "Finish a lesson at 100% accuracy", hint: "No mistakes in a lesson" },
  { id: "speed-30", name: "Cruising", desc: "Reach 30 WPM", hint: "A 30 WPM run" },
  { id: "speed-50", name: "Fast hands", desc: "Reach 50 WPM", hint: "A 50 WPM run" },
  { id: "speed-80", name: "Blur", desc: "Reach 80 WPM", hint: "An 80 WPM run" },
  { id: "streak-3", name: "Three days", desc: "Practise three days in a row", hint: "Build a small streak" },
  { id: "streak-7", name: "A full week", desc: "Practise seven days in a row", hint: "Keep the streak alive" },
  { id: "streak-30", name: "Habit formed", desc: "Practise thirty days in a row", hint: "A month of practice" },
  { id: "keys-1k", name: "Thousand keys", desc: "Type 1,000 keys", hint: "Volume comes first" },
  { id: "keys-10k", name: "Ten thousand", desc: "Type 10,000 keys", hint: "Serious mileage" },
  { id: "time-1h", name: "One hour in", desc: "Spend an hour practising", hint: "An hour of typing" },
  { id: "time-5h", name: "Deep practice", desc: "Spend five hours practising", hint: "Five hours of typing" },
  { id: "games-10", name: "Playtime", desc: "Play ten games", hint: "Games keep it fun" },
  { id: "drills-20", name: "Targeted", desc: "Finish twenty drills", hint: "Work the weak keys" },
  { id: "week-5", name: "Regular", desc: "Practise on five different days", hint: "Show up five days" },
  { id: "no-hunt", name: "Eyes up", desc: "Reach 40 WPM without dropping below 97% accuracy", hint: "Speed with control" }
]

function pad2(n) {
  return (n < 10 ? "0" : "") + n
}

function dayKey(value) {
  var d = (value === undefined || value === null) ? new Date() : new Date(value)
  return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
}

function todayKey() {
  return dayKey(new Date())
}

function dayNumber(key) {
  var parts = String(key || "").split("-")
  if (parts.length !== 3) return 0
  return Math.floor(Date.UTC(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])) / 86400000)
}

function clone(value) {
  return JSON.parse(JSON.stringify(value === undefined ? null : value))
}

function num(value, fallback) {
  var n = Number(value)
  return isFinite(n) ? n : fallback
}

function bool(value, fallback) {
  return typeof value === "boolean" ? value : fallback
}

function obj(value) {
  return (value !== null && typeof value === "object" && !Array.isArray(value)) ? value : {}
}

// Lists cross the QML signal boundary as array-like wrappers, not real JS
// arrays, so Array.isArray alone silently drops curves and typo logs. Copy
// anything with a numeric length (but never a string) into a plain array.
function arr(value) {
  if (Array.isArray(value)) return value
  if (value && typeof value === "object" && typeof value.length === "number") {
    var out = []
    for (var i = 0; i < value.length; i++) out.push(value[i])
    return out
  }
  return []
}

function defaultSettings() {
  return clone(DEFAULT_SETTINGS)
}

function defaultProfile() {
  return {
    version: VERSION,
    created: Date.now(),
    xp: 0,
    streak: 0,
    bestStreak: 0,
    lastDay: "",
    days: {},
    counters: { lessons: 0, tests: 0, drills: 0, games: 0, keys: 0, seconds: 0, perfect: 0 },
    best: { wpm: 0, acc: 0, consistency: 0 },
    lessons: {},
    keys: {},
    bigrams: {},
    typos: {},
    tests: [],
    games: {},
    achievements: {},
    settings: defaultSettings(),
    lastGoalDay: ""
  }
}

function normalizeSettings(raw) {
  var s = obj(raw)
  var out = defaultSettings()
  for (var k in DEFAULT_SETTINGS) {
    if (s[k] === undefined || s[k] === null) continue
    var d = DEFAULT_SETTINGS[k]
    if (typeof d === "number") out[k] = Math.max(0, num(s[k], d))
    else if (typeof d === "boolean") out[k] = bool(s[k], d)
    else if (typeof d === "string") out[k] = (typeof s[k] === "string" && s[k].length > 0) ? s[k] : d
    else out[k] = s[k]
  }
  out.volume = Math.max(0, Math.min(1, out.volume))
  out.fontSize = Math.max(0.8, Math.min(1.8, out.fontSize))
  if (["off", "line", "block", "underline"].indexOf(out.caretStyle) === -1) out.caretStyle = "line"
  if (["time", "words", "quote", "code"].indexOf(out.testMode) === -1) out.testMode = "time"
  if (["short", "medium", "long"].indexOf(out.quoteLength) === -1) out.quoteLength = "medium"
  if (CODE_LANGS.indexOf(out.codeLang) === -1) out.codeLang = "javascript"
  return out
}

function normalize(raw) {
  var src = obj(raw)
  var out = defaultProfile()

  out.created = num(src.created, out.created)
  out.xp = Math.max(0, Math.round(num(src.xp, 0)))
  out.streak = Math.max(0, Math.round(num(src.streak, 0)))
  out.bestStreak = Math.max(out.streak, Math.round(num(src.bestStreak, 0)))
  out.lastDay = typeof src.lastDay === "string" ? src.lastDay : ""

  var srcCounters = obj(src.counters)
  for (var c in out.counters) out.counters[c] = Math.max(0, Math.round(num(srcCounters[c], 0)))

  var srcBest = obj(src.best)
  out.best.wpm = Math.max(0, num(srcBest.wpm, 0))
  out.best.acc = Math.max(0, num(srcBest.acc, 0))
  out.best.consistency = Math.max(0, num(srcBest.consistency, 0))

  var srcDays = obj(src.days)
  for (var day in srcDays) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) continue
    var d = obj(srcDays[day])
    out.days[day] = {
      sec: Math.max(0, num(d.sec, 0)),
      keys: Math.max(0, num(d.keys, 0))
    }
  }

  var srcLessons = obj(src.lessons)
  for (var lid in srcLessons) {
    var r = obj(srcLessons[lid])
    out.lessons[lid] = {
      lessonId: lid,
      attempts: Math.max(0, Math.round(num(r.attempts, 0))),
      bestWpm: Math.max(0, num(r.bestWpm, 0)),
      bestAcc: Math.max(0, num(r.bestAcc, 0)),
      stars: Math.max(0, Math.min(3, Math.round(num(r.stars, 0)))),
      done: r.done === true,
      last: num(r.last, 0)
    }
  }

  var srcKeys = obj(src.keys)
  for (var k in srcKeys) {
    var s = obj(srcKeys[k])
    out.keys[k] = {
      hits: Math.max(0, num(s.hits, 0)),
      misses: Math.max(0, num(s.misses, 0)),
      msSum: Math.max(0, num(s.msSum, 0)),
      msN: Math.max(0, num(s.msN, 0))
    }
  }

  var srcBigrams = obj(src.bigrams)
  for (var b in srcBigrams) {
    var sb = obj(srcBigrams[b])
    out.bigrams[b] = {
      hits: Math.max(0, num(sb.hits, 0)),
      misses: Math.max(0, num(sb.misses, 0))
    }
  }

  var srcTypos = obj(src.typos)
  for (var tkey in srcTypos) {
    var tcount = Math.max(0, Math.round(num(srcTypos[tkey], 0)))
    if (tcount > 0) out.typos[tkey] = tcount
  }

  var tests = arr(src.tests)
  var keep = tests.slice(-80)
  for (var i = 0; i < keep.length; i++) {
    var t = obj(keep[i])
    var entry = {
      ts: num(t.ts, 0),
      mode: typeof t.mode === "string" ? t.mode : "time",
      amount: num(t.amount, 30),
      wpm: Math.max(0, num(t.wpm, 0)),
      raw: Math.max(0, num(t.raw, 0)),
      acc: Math.max(0, Math.min(100, num(t.acc, 0))),
      consistency: Math.max(0, Math.min(100, num(t.consistency, 0))),
      seconds: Math.max(0, num(t.seconds, 0))
    }
    var curve = numericCurve(t.curve, 40)
    if (curve.length > 0) entry.curve = curve
    out.tests.push(entry)
  }

  var srcGames = obj(src.games)
  for (var g in srcGames) {
    var sg = obj(srcGames[g])
    out.games[g] = {
      plays: Math.max(0, Math.round(num(sg.plays, 0))),
      best: Math.max(0, num(sg.best, 0)),
      last: num(sg.last, 0)
    }
  }

  var srcAch = obj(src.achievements)
  for (var a in srcAch) {
    if (typeof srcAch[a] === "number") out.achievements[a] = srcAch[a]
  }

  out.lastGoalDay = typeof src.lastGoalDay === "string" ? src.lastGoalDay : ""
  out.settings = normalizeSettings(src.settings)

  // Rebuild counters that older files may not have carried.
  var keyTotal = 0
  for (var kk in out.keys) keyTotal += out.keys[kk].hits + out.keys[kk].misses
  if (out.counters.keys === 0 && keyTotal > 0) out.counters.keys = keyTotal

  return out
}

// Loading is always a migration: normalize fills in anything an older file
// lacks, then the version is stamped so a half-written file cannot stay old.
function migrate(raw) {
  var p = normalize(raw)
  p.version = VERSION
  return p
}

// A run's speed curve can be one point per second. Cap it so a long test does
// not bloat the profile, keeping first, last and an even spread of the middle.
function numericCurve(list, limit) {
  var items = arr(list)
  var cap = limit === undefined ? 40 : limit
  var n = Math.min(items.length, cap)
  var out = []
  if (n <= 0) return out
  for (var i = 0; i < n; i++) {
    var at = n === 1 ? 0 : Math.round(i * (items.length - 1) / (n - 1))
    out.push(Math.round(num(items[at], 0) * 10) / 10)
  }
  return out
}

// -------------------------------------------------------------- day & streak

function dayEntry(profile, key) {
  return profile.days[key] || { sec: 0, keys: 0 }
}

function recordActivity(profile, seconds, keys) {
  var p = profile
  var key = todayKey()
  var entry = dayEntry(p, key)
  p.days[key] = {
    sec: num(entry.sec, 0) + Math.max(0, num(seconds, 0)),
    keys: num(entry.keys, 0) + Math.max(0, num(keys, 0))
  }
  p.counters.seconds += Math.max(0, num(seconds, 0))
  p.counters.keys += Math.max(0, num(keys, 0))

  if (p.lastDay !== key) {
    var gap = p.lastDay ? dayNumber(key) - dayNumber(p.lastDay) : 0
    if (gap === 1) p.streak = Math.max(1, p.streak + 1)
    else p.streak = 1
    p.lastDay = key
    p.bestStreak = Math.max(p.bestStreak, p.streak)
  }
  return p
}

// The streak as the dashboard should show it: a streak that has not been fed
// since yesterday is still alive today, but one that has been dead for longer
// is not.
function liveStreak(profile) {
  var today = todayKey()
  if (!profile.lastDay) return 0
  var gap = dayNumber(today) - dayNumber(profile.lastDay)
  if (gap <= 1) return profile.streak
  return 0
}

function practicedToday(profile) {
  return (profile.days || {})[todayKey()] !== undefined
}

// A daily goal is cleared when a speed test reaches the configured WPM and
// holds the configured accuracy in the same run. Zero on either side means the
// goal is off.
function dailyGoalMet(profile, result) {
  var s = normalizeSettings(profile ? profile.settings : null)
  var goalWpm = num(s.dailyGoalWpm, 20)
  var goalAcc = num(s.dailyGoalAcc, 90)
  if (!result) return false
  if (goalWpm <= 0 && goalAcc <= 0) return false
  return num(result.wpm, 0) >= goalWpm && num(result.acc, 0) >= goalAcc
}

function activeDays(profile) {
  return Object.keys(profile.days || {}).length
}

// ---------------------------------------------------------------- xp & level

function xpFloor(level) {
  if (level <= 1) return 0
  return Math.round(110 * Math.pow(level - 1, 1.55))
}

function levelFor(xp) {
  var level = 1
  while (level < 200 && xp >= xpFloor(level + 1)) level++
  return level
}

function levelInfo(xp) {
  var level = levelFor(xp)
  var floor = xpFloor(level)
  var next = xpFloor(level + 1)
  var span = Math.max(1, next - floor)
  return {
    level: level,
    xp: xp,
    floor: floor,
    next: next,
    into: Math.max(0, xp - floor),
    span: span,
    progress: Math.max(0, Math.min(1, (xp - floor) / span))
  }
}

function addXp(profile, amount) {
  var gain = Math.max(0, Math.round(num(amount, 0)))
  if (gain <= 0) return profile
  profile.xp += gain
  return profile
}

// ------------------------------------------------------------------ records

// A twenty-character drill finished in one second divides out to seven hundred
// words per minute. The arithmetic is right; the number is noise. Speed records
// and speed-based XP therefore only accept runs long enough to be an average
// rather than a burst.
var RECORD_MIN_SECONDS = 5

function recordedSpeed(result) {
  if (num(result.seconds, 0) < RECORD_MIN_SECONDS) return 0
  return num(result.wpm, 0)
}

function mergeKeys(profile, keyLog, bigramLog) {
  var keys = obj(keyLog)
  for (var k in keys) {
    var s = obj(keys[k])
    if (!profile.keys[k]) profile.keys[k] = { hits: 0, misses: 0, msSum: 0, msN: 0 }
    var t = profile.keys[k]
    t.hits += Math.max(0, num(s.hits, 0))
    t.misses += Math.max(0, num(s.misses, 0))
    t.msSum += Math.max(0, num(s.msSum, 0))
    t.msN += Math.max(0, num(s.msN, 0))
  }
  var pairs = obj(bigramLog)
  for (var b in pairs) {
    var sb = obj(pairs[b])
    if (!profile.bigrams[b]) profile.bigrams[b] = { hits: 0, misses: 0 }
    var tb = profile.bigrams[b]
    tb.hits += Math.max(0, num(sb.hits, 0))
    tb.misses += Math.max(0, num(sb.misses, 0))
  }
  return profile
}

// A confusion pair, not a miss count: "you wanted t and pressed r". The
// aggregate `keys` map already counts misses per key, so this stores the
// direction of the error and stays answerable to a drill suggestion.
function typoKey(want, got) {
  var w = String(want === undefined || want === null ? "" : want).toLowerCase()
  var g = String(got === undefined || got === null ? "" : got).toLowerCase()
  if (!w) return ""
  return w + ">" + g
}

function mergeTypos(profile, list) {
  var items = arr(list)
  if (!profile.typos) profile.typos = {}
  for (var i = 0; i < items.length; i++) {
    var e = obj(items[i])
    var key = typoKey(e.want, e.got)
    if (!key) continue
    profile.typos[key] = Math.max(0, Math.round(num(profile.typos[key], 0))) + 1
  }
  return profile
}

function topTypos(profile, limit) {
  var map = obj(profile.typos)
  var out = []
  for (var key in map) {
    var at = key.indexOf(">")
    if (at <= 0) continue
    out.push({
      key: key,
      want: key.slice(0, at),
      got: key.slice(at + 1),
      count: Math.max(0, num(map[key], 0))
    })
  }
  out.sort(function (a, b) { return b.count - a.count })
  return out.slice(0, limit === undefined ? 6 : limit)
}

// Same ranking, but counted from one run's log instead of the stored profile.
function topTyposFromLog(list, limit) {
  var items = arr(list)
  var map = {}
  for (var i = 0; i < items.length; i++) {
    var e = obj(items[i])
    var key = typoKey(e.want, e.got)
    if (!key) continue
    map[key] = Math.max(0, num(map[key], 0)) + 1
  }
  return topTypos({ typos: map }, limit)
}

function recordLesson(profile, lessonId, result) {
  var id = String(lessonId)
  if (!profile.lessons[id]) {
    profile.lessons[id] = { lessonId: id, attempts: 0, bestWpm: 0, bestAcc: 0, stars: 0, done: false, last: 0 }
  }
  var r = profile.lessons[id]
  var speed = recordedSpeed(result)
  r.attempts += 1
  r.bestWpm = Math.max(r.bestWpm, speed)
  r.bestAcc = Math.max(r.bestAcc, num(result.acc, 0))
  r.last = Date.now()
  var firstTime = !r.done
  if (result.passed) r.done = true
  if (firstTime && r.done) profile.counters.lessons += 1
  if (num(result.acc, 0) >= 99.99) profile.counters.perfect += 1

  recordActivity(profile, num(result.seconds, 0), num(result.keystrokes, 0))
  mergeKeys(profile, result.keyLog, result.bigramLog)
  mergeTypos(profile, result.typoLog)
  profile.best.wpm = Math.max(profile.best.wpm, speed)
  profile.best.acc = Math.max(profile.best.acc, num(result.acc, 0))

  addXp(profile, 10 + speed * 0.6 + (r.done ? 15 : 0) + (num(result.acc, 0) >= 98 ? 10 : 0))
  return profile
}

function recordDrill(profile, result) {
  var speed = recordedSpeed(result)
  profile.counters.drills += 1
  recordActivity(profile, num(result.seconds, 0), num(result.keystrokes, 0))
  mergeKeys(profile, result.keyLog, result.bigramLog)
  mergeTypos(profile, result.typoLog)
  profile.best.wpm = Math.max(profile.best.wpm, speed)
  addXp(profile, 4 + speed * 0.35 + (num(result.acc, 0) >= 98 ? 8 : 0))
  return profile
}

function recordTest(profile, result) {
  var speed = recordedSpeed(result)
  profile.counters.tests += 1
  recordActivity(profile, num(result.seconds, 0), num(result.keystrokes, 0))
  mergeKeys(profile, result.keyLog, result.bigramLog)
  mergeTypos(profile, result.typoLog)

  profile.tests.push({
    ts: Date.now(),
    mode: String(result.mode || "time"),
    amount: num(result.amount, 30),
    wpm: num(result.wpm, 0),
    raw: num(result.raw, 0),
    acc: num(result.acc, 0),
    consistency: num(result.consistency, 0),
    seconds: num(result.seconds, 0),
    curve: numericCurve(result.curve, 40)
  })
  if (profile.tests.length > 80) profile.tests = profile.tests.slice(-80)

  profile.best.wpm = Math.max(profile.best.wpm, speed)
  profile.best.acc = Math.max(profile.best.acc, num(result.acc, 0))
  profile.best.consistency = Math.max(profile.best.consistency, num(result.consistency, 0))

  addXp(profile, 6 + speed * 0.5 + (num(result.acc, 0) >= 98 ? 12 : 0))
  return profile
}

function recordGame(profile, gameId, result) {
  var id = String(gameId)
  if (!profile.games[id]) profile.games[id] = { plays: 0, best: 0, last: 0 }
  var g = profile.games[id]
  g.plays += 1
  g.best = Math.max(g.best, num(result.score, 0))
  g.last = Date.now()
  profile.counters.games += 1
  recordActivity(profile, num(result.seconds, 0), num(result.keystrokes, 0))
  mergeKeys(profile, result.keyLog, result.bigramLog)
  mergeTypos(profile, result.typoLog)
  addXp(profile, 3 + num(result.score, 0) * 0.4)
  return profile
}

// -------------------------------------------------------------- diagnostics

function keyAccuracy(entry) {
  var e = entry || {}
  var total = num(e.hits, 0) + num(e.misses, 0)
  if (total <= 0) return 0
  return (num(e.hits, 0) / total) * 100
}

function weakKeys(profile, limit, minSamples) {
  var floor = minSamples === undefined ? 6 : minSamples
  var out = []
  var keys = obj(profile.keys)
  for (var k in keys) {
    var e = keys[k]
    var total = num(e.hits, 0) + num(e.misses, 0)
    if (total < floor) continue
    out.push({
      key: k,
      hits: num(e.hits, 0),
      misses: num(e.misses, 0),
      samples: total,
      acc: keyAccuracy(e),
      ms: num(e.msN, 0) > 0 ? num(e.msSum, 0) / num(e.msN, 0) : 0
    })
  }
  out.sort(function (a, b) {
    if (Math.abs(a.acc - b.acc) > 0.4) return a.acc - b.acc
    return b.samples - a.samples
  })
  return out.slice(0, limit === undefined ? 8 : limit)
}

function slowKeys(profile, limit, minSamples) {
  var floor = minSamples === undefined ? 6 : minSamples
  var out = []
  var keys = obj(profile.keys)
  for (var k in keys) {
    var e = keys[k]
    var n = num(e.msN, 0)
    if (n < floor) continue
    out.push({ key: k, ms: num(e.msSum, 0) / n, samples: n, acc: keyAccuracy(e) })
  }
  out.sort(function (a, b) { return b.ms - a.ms })
  return out.slice(0, limit === undefined ? 8 : limit)
}

function weakBigrams(profile, limit, minSamples) {
  var floor = minSamples === undefined ? 4 : minSamples
  var out = []
  var pairs = obj(profile.bigrams)
  for (var b in pairs) {
    var e = pairs[b]
    var total = num(e.hits, 0) + num(e.misses, 0)
    if (total < floor) continue
    out.push({
      pair: b,
      samples: total,
      misses: num(e.misses, 0),
      acc: (num(e.hits, 0) / total) * 100
    })
  }
  out.sort(function (a, b) {
    if (Math.abs(a.acc - b.acc) > 0.4) return a.acc - b.acc
    return b.samples - a.samples
  })
  return out.slice(0, limit === undefined ? 6 : limit)
}

function keysFromLog(keyLog, limit) {
  var log = obj(keyLog)
  var out = []
  for (var k in log) {
    // "space" and other named keys are not drillable as a single character.
    if (String(k).length !== 1) continue
    var e = obj(log[k])
    var misses = Math.max(0, num(e.misses, 0))
    if (misses <= 0) continue
    var hits = Math.max(0, num(e.hits, 0))
    var total = hits + misses
    out.push({
      key: k,
      misses: misses,
      acc: total > 0 ? (hits / total) * 100 : 0
    })
  }
  out.sort(function (a, b) {
    if (b.misses !== a.misses) return b.misses - a.misses
    return a.acc - b.acc
  })
  return out.slice(0, limit === undefined ? 5 : limit).map(function (e) { return e.key })
}

function totalKeys(profile) {
  return num((profile.counters || {}).keys, 0)
}

function totalSeconds(profile) {
  return num((profile.counters || {}).seconds, 0)
}

// ------------------------------------------------------------- achievements

function evaluate(profile, ctx) {
  var c = ctx || {}
  var lessonsDone = num(c.lessonsDone, 0)
  var lessonsTotal = num(c.lessonsTotal, 1)
  var unlocked = []
  var counters = profile.counters || {}
  var best = profile.best || {}

  function give(id, condition) {
    if (!condition) return
    if (profile.achievements[id]) return
    profile.achievements[id] = Date.now()
    unlocked.push(id)
  }

  give("first-lesson", lessonsDone >= 1)
  give("five-lessons", lessonsDone >= 5)
  give("all-lessons", lessonsTotal > 0 && lessonsDone >= lessonsTotal)
  give("perfect", num(counters.perfect, 0) >= 1)
  give("speed-30", num(best.wpm, 0) >= 30)
  give("speed-50", num(best.wpm, 0) >= 50)
  give("speed-80", num(best.wpm, 0) >= 80)
  give("streak-3", num(profile.bestStreak, 0) >= 3)
  give("streak-7", num(profile.bestStreak, 0) >= 7)
  give("streak-30", num(profile.bestStreak, 0) >= 30)
  give("keys-1k", totalKeys(profile) >= 1000)
  give("keys-10k", totalKeys(profile) >= 10000)
  give("time-1h", totalSeconds(profile) >= 3600)
  give("time-5h", totalSeconds(profile) >= 18000)
  give("games-10", num(counters.games, 0) >= 10)
  give("drills-20", num(counters.drills, 0) >= 20)
  give("week-5", activeDays(profile) >= 5)
  give("no-hunt", num(best.wpm, 0) >= 40 && num(best.acc, 0) >= 97)

  return unlocked
}

function achievementById(id) {
  for (var i = 0; i < ACHIEVEMENTS.length; i++) {
    if (ACHIEVEMENTS[i].id === id) return ACHIEVEMENTS[i]
  }
  return null
}

// ---------------------------------------------------------------- formatting

function pad(n) {
  return (n < 10 ? "0" : "") + n
}

function formatDuration(seconds) {
  var s = Math.max(0, Math.round(num(seconds, 0)))
  if (s < 60) return s + "s"
  var m = Math.floor(s / 60)
  if (m < 60) return m + "m " + pad(s % 60) + "s"
  var h = Math.floor(m / 60)
  return h + "h " + pad(m % 60) + "m"
}

function formatHours(seconds) {
  var h = num(seconds, 0) / 3600
  if (h < 1) return Math.round(num(seconds, 0) / 60) + " min"
  return (h < 10 ? h.toFixed(1) : Math.round(h)) + " h"
}

function formatCount(n) {
  var v = Math.round(num(n, 0))
  if (v >= 1000000) return (v / 1000000).toFixed(1) + "M"
  if (v >= 10000) return Math.round(v / 1000) + "k"
  if (v >= 1000) return (v / 1000).toFixed(1) + "k"
  return String(v)
}

function formatClock(seconds) {
  var s = Math.max(0, Math.ceil(num(seconds, 0)))
  var m = Math.floor(s / 60)
  return m + ":" + pad(s % 60)
}

function initialsDay(key) {
  var parts = String(key || "").split("-")
  if (parts.length !== 3) return ""
  return parts[2] + "/" + parts[1]
}

// Last `count` days, oldest first, with zero-filled gaps.
function daySeries(profile, count) {
  var out = []
  var now = new Date()
  var days = profile.days || {}
  for (var i = count - 1; i >= 0; i--) {
    var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i)
    var key = dayKey(d)
    var entry = days[key] || { sec: 0, keys: 0 }
    out.push({
      key: key,
      label: initialsDay(key),
      weekday: d.getDay(),
      sec: num(entry.sec, 0),
      keys: num(entry.keys, 0)
    })
  }
  return out
}

// Weighted activity level 0..4 for a calendar strip.
function activityLevel(seconds) {
  var s = num(seconds, 0)
  if (s <= 0) return 0
  if (s < 120) return 1
  if (s < 300) return 2
  if (s < 600) return 3
  return 4
}

function recentTests(profile, count) {
  var list = arr(profile.tests)
  return list.slice(-(count === undefined ? 12 : count))
}

function averageWpm(profile, count) {
  var list = recentTests(profile, count)
  if (list.length === 0) return 0
  var sum = 0
  for (var i = 0; i < list.length; i++) sum += num(list[i].wpm, 0)
  return sum / list.length
}

function trend(profile, count) {
  var list = recentTests(profile, count)
  if (list.length < 2) return 0
  var half = Math.floor(list.length / 2)
  var first = 0, second = 0
  for (var i = 0; i < half; i++) first += num(list[i].wpm, 0)
  for (var j = half; j < list.length; j++) second += num(list[j].wpm, 0)
  first /= Math.max(1, half)
  second /= Math.max(1, list.length - half)
  return second - first
}

function emptyProfile() {
  return defaultProfile()
}
