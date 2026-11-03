import QtQuick
import qs.Commons

// The typing core. Owns the passage, the cursor, per-character marks and the
// statistics. It knows nothing about lessons, drills or games — those supply
// text and interpret `completed`.
Item {
  id: engine

  property string text: ""
  property bool strict: false
  property int timeLimit: 0

  property int cursor: 0
  property bool started: false
  property bool finished: false

  property double elapsed: 0
  property int keystrokes: 0
  property int errors: 0

  // 0 = untouched, 1 = correct, 2 = wrong
  property var states: []

  property var keyLog: ({})
  property var bigramLog: ({})

  // Every wrong key this run, as { want, got }. Kept separate from keyLog
  // because keyLog answers "how often is this key wrong" and this answers
  // "which key did you press instead", which is what a coach needs.
  property var typoLog: []

  property var samples: []
  property double consistency: 0

  property double liveWpm: 0
  property double liveRaw: 0
  property double liveAcc: 100

  readonly property int length: text.length
  readonly property real progress: length > 0 ? Math.min(1, cursor / length) : 0
  readonly property bool atEnd: length > 0 && cursor >= length
  readonly property string nextChar: (cursor < length) ? text.charAt(cursor) : ""

  signal completed(var result)
  signal pressed(bool ok, string expected)
  signal advanced()

  Timer {
    id: ticker
    interval: 100
    repeat: true
    running: false
    onTriggered: engine.tick()
  }

  // Internal clock state. Not exposed because nothing outside needs it, and a
  // binding that reads the wall clock would never re-evaluate on its own.
  property double startedAt: 0
  property double lastKeyAt: 0
  property int sampledUpTo: 0
  property string lastExpected: ""

  onTextChanged: prepare()

  function prepare() {
    ticker.stop()
    cursor = 0
    started = false
    finished = false
    elapsed = 0
    startedAt = 0
    lastKeyAt = 0
    sampledUpTo = 0
    lastExpected = ""
    keystrokes = 0
    errors = 0
    samples = []
    consistency = 0
    liveWpm = 0
    liveRaw = 0
    liveAcc = 100
    keyLog = ({})
    bigramLog = ({})
    typoLog = []

    var n = text.length
    var fresh = new Array(n)
    for (var i = 0; i < n; i++) fresh[i] = 0
    states = fresh
  }

  function load(value) {
    text = value
    prepare()
  }

  function restart() {
    var keep = text
    prepare()
    text = keep
  }

  function setState(index, value) {
    if (index < 0 || index >= states.length) return
    var next = states.slice()
    next[index] = value
    states = next
  }

  function logKey(ch, ok, delta) {
    var key = (ch === " ") ? "space" : String(ch).toLowerCase()
    if (key.length === 0) return
    if (!keyLog[key]) keyLog[key] = { hits: 0, misses: 0, msSum: 0, msN: 0 }
    var entry = keyLog[key]
    if (ok) entry.hits += 1
    else entry.misses += 1
    if (delta > 0 && delta < 3000) {
      entry.msSum += delta
      entry.msN += 1
    }
  }

  function logBigram(prev, ch, ok) {
    if (!prev || prev === " ") return
    if (!ch || ch === " ") return
    var pair = prev.toLowerCase() + ch.toLowerCase()
    if (!bigramLog[pair]) bigramLog[pair] = { hits: 0, misses: 0 }
    if (ok) bigramLog[pair].hits += 1
    else bigramLog[pair].misses += 1
  }

  function press(ch) {
    if (finished || text.length === 0) return
    if (!started) {
      started = true
      startedAt = Date.now()
      lastKeyAt = startedAt
      ticker.start()
    }

    var expected = text.charAt(cursor)
    var now = Date.now()
    var delta = lastKeyAt > 0 ? (now - lastKeyAt) : 0
    lastKeyAt = now

    var ok = (ch === expected)
    keystrokes += 1

    logKey(expected, ok, delta)
    logBigram(lastExpected, expected, ok)
    lastExpected = expected

    if (ok) {
      setState(cursor, 1)
      cursor += 1
      pressed(true, expected)
      advanced()
      refreshLive()
      if (cursor >= text.length) finish("text")
      return
    }

    errors += 1
    var next = typoLog.slice()
    next.push({ want: expected, got: ch })
    typoLog = next
    pressed(false, expected)

    if (strict) {
      setState(cursor, 2)
    } else {
      setState(cursor, 2)
      cursor += 1
      advanced()
      refreshLive()
      if (cursor >= text.length) finish("text")
    }
  }

  function backspace() {
    if (finished || cursor <= 0) return
    cursor -= 1
    setState(cursor, 0)
    advanced()
  }

  function tick() {
    if (!started || finished) return
    elapsed = (Date.now() - startedAt) / 1000
    refreshLive()
    if (timeLimit > 0 && elapsed >= timeLimit) finish("time")
  }

  function refreshLive() {
    var seconds = elapsed
    if (started && !finished) seconds = (Date.now() - startedAt) / 1000
    if (seconds < 0.05) seconds = 0.05

    liveRaw = keystrokes * 12 / seconds
    liveWpm = cursor * 12 / seconds
    liveAcc = keystrokes > 0 ? ((keystrokes - errors) / keystrokes) * 100 : 100

    var bucket = Math.floor(seconds)
    if (bucket > sampledUpTo && started) {
      sampledUpTo = bucket
      var next = samples.slice()
      next.push(Math.max(0, liveWpm))
      samples = next
      consistency = measureConsistency()
    }
  }

  // Keeps a list's shape when it is too long to persist: first, last and an even
  // sample of the middle. A long test would otherwise save one point per second.
  function downsample(list, limit) {
    var n = list.length
    if (n <= limit || limit < 3) return list.slice()
    var out = []
    for (var i = 0; i < limit; i++) {
      out.push(list[Math.round(i * (n - 1) / (limit - 1))])
    }
    return out
  }

  function rounded(list) {
    var out = []
    for (var i = 0; i < list.length; i++) out.push(Math.round(Number(list[i]) * 10) / 10)
    return out
  }

  function measureConsistency() {
    var list = samples
    if (list.length < 3) return 0
    var sum = 0
    for (var i = 0; i < list.length; i++) sum += list[i]
    var mean = sum / list.length
    if (mean <= 0) return 0
    var variance = 0
    for (var j = 0; j < list.length; j++) {
      var d = list[j] - mean
      variance += d * d
    }
    var sd = Math.sqrt(variance / list.length)
    return Util.clamp(100 * (1 - sd / mean), 0, 100)
  }

  function finish(reason) {
    if (finished) return
    finished = true
    ticker.stop()
    if (started) elapsed = (Date.now() - startedAt) / 1000
    refreshLive()

    var seconds = Math.max(1, elapsed)
    var finalWpm = cursor * 12 / seconds

    // The timer only samples whole seconds, so a short drill has an empty
    // series. Always end the curve on the number the card is about to show.
    var curve = samples.slice()
    if (curve.length === 0 || Math.abs(curve[curve.length - 1] - finalWpm) > 0.5) {
      curve.push(Math.max(0, finalWpm))
    }

    var result = {
      reason: reason || "text",
      wpm: finalWpm,
      raw: keystrokes * 12 / seconds,
      acc: keystrokes > 0 ? ((keystrokes - errors) / keystrokes) * 100 : 0,
      consistency: consistency,
      seconds: seconds,
      keystrokes: keystrokes,
      errors: errors,
      typed: cursor,
      total: text.length,
      keyLog: JSON.parse(JSON.stringify(keyLog)),
      bigramLog: JSON.parse(JSON.stringify(bigramLog)),
      typoLog: JSON.parse(JSON.stringify(downsample(typoLog, 24))),
      curve: rounded(downsample(curve, 40))
    }

    completed(result)
  }
}
