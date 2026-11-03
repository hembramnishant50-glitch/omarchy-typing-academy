import QtQuick
import qs.Commons
import "../Words.js" as Words

// Three small games sharing one key loop. The Academy root forwards raw key
// events here through `keySink` while this board is on screen, so nothing is
// fighting the tab shortcuts or the practice engine.
//
// The only rule that matters: every mode teaches the same thing — find the key
// without looking — so every mode counts accuracy per key and reports it back
// like any other run.
Item {
  id: board

  // Words spawn above the arena and fall in. Without clipping they paint over
  // the cards above the board while they are still off-stage.
  clip: true

  property string mode: "falling"
  property var app: null
  property int gameFontSize: Math.round(Style.font.subtitle * 1.6)
  property bool running: false
  property bool finished: false

  property int score: 0
  property int lives: 3
  property real timeLeft: 45
  property real elapsed: 0

  property string buffer: ""
  property var words: []
  property var queue: []
  property int queueIndex: 0
  property string typed: ""
  property string target: ""

  property int hits: 0
  property int misses: 0
  property var keyLog: ({})
  property var bigramLog: ({})
  property string lastKey: ""

  // Speed burst — single letter, fifteen second clock.
  property int burstTimeLeft: 15
  property string burstChar: ""

  // Accuracy gauntlet — endless words, one miss ends the run.
  property string gauntletWord: ""
  property string gauntletTyped: ""

  // Pattern mirror — sequence memory, one more letter each round.
  property var mirrorSequence: []
  property int mirrorIndex: 0
  property int mirrorRound: 0

  signal gameOver(var result)

  property int duration: 45
  readonly property var sprintWords: queue
  readonly property string currentWord: queueIndex < queue.length ? queue[queueIndex] : ""

  function reset() {
    running = false
    finished = false
    score = 0
    lives = 3
    timeLeft = duration
    elapsed = 0
    buffer = ""
    words = []
    queue = []
    queueIndex = 0
    typed = ""
    target = ""
    hits = 0
    misses = 0
    keyLog = ({})
    bigramLog = ({})
    lastKey = ""
  }

  function start() {
    if (app && !app.fullScreen) Qt.callLater(function () { app.toggleFullScreen() })
    if (mode === "burst") duration = 15
    else if (mode !== "falling") duration = 45
    reset()
    if (mode === "sprint") {
      queue = Words.makeWords(60).split(" ")
      queueIndex = 0
      typed = ""
    } else if (mode === "hunt") {
      newTarget()
    } else if (mode === "burst") {
      burstTimeLeft = 15
      nextBurstChar()
    } else if (mode === "gauntlet") {
      nextGauntletWord()
      gauntletTyped = ""
    } else if (mode === "mirror") {
      mirrorRound = 0
      mirrorIndex = 0
      mirrorSequence = []
      nextMirrorRound()
    } else {
      for (var i = 0; i < 3; i++) spawnWord(true)
    }
    elapsed = 0
    running = true
  }

  function stop() {
    running = false
  }

  function startKey(event) {
    return event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter
  }

  // --------------------------------------------------------------- key input

  function handleKey(event) {
    // Esc ends a run in progress and leaves the score on the board. Closing
    // the whole academy mid-run would throw the game away with no result.
    if (event.key === Qt.Key_Escape) {
      if (!running) return false
      finish()
      return true
    }

    if (event.key === Qt.Key_Backspace) {
      if (running && buffer.length > 0) buffer = buffer.slice(0, buffer.length - 1)
      return true
    }

    if (!running) {
      if (startKey(event) || (finished && event.text && event.text.length === 1)) {
        start()
        return true
      }
      return false
    }

    var ch = event.text
    if (!ch || ch.length !== 1) return false

    if (mode === "falling") typeFalling(ch)
    else if (mode === "sprint") typeSprint(ch)
    else if (mode === "hunt") typeHunt(ch)
    else if (mode === "burst") typeBurst(ch)
    else if (mode === "gauntlet") typeGauntlet(ch)
    else typeMirror(ch)
    return true
  }

  function record(ch, ok) {
    var key = ch === " " ? "space" : String(ch).toLowerCase()
    if (key.length === 0) return
    if (!keyLog[key]) keyLog[key] = { hits: 0, misses: 0, msSum: 0, msN: 0 }
    if (ok) keyLog[key].hits += 1
    else keyLog[key].misses += 1

    if (lastKey && lastKey !== " " && ch !== " ") {
      var pair = lastKey + String(ch).toLowerCase()
      if (!bigramLog[pair]) bigramLog[pair] = { hits: 0, misses: 0 }
      if (ok) bigramLog[pair].hits += 1
      else bigramLog[pair].misses += 1
    }
    lastKey = String(ch).toLowerCase()

    if (ok) hits += 1
    else misses += 1
  }

  // ----------------------------------------------------------------- falling

  function spawnWord(initial) {
    var text = Words.pick(Words.COMMON)
    if (text.length < 3) text = Words.pick(Words.EVERYDAY)
    var widthGuess = text.length * Math.max(12, Style.font.subtitle * 0.62)
    var span = Math.max(1, board.width - widthGuess - 24)
    var next = words.slice()
    next.push({
      key: "w" + Math.random().toString(36).slice(2, 9),
      text: text,
      x: 12 + Math.random() * span,
      y: initial ? -60 - Math.random() * 140 : -26,
      speed: 20 + Math.random() * 16 + Math.min(22, score * 0.25)
    })
    words = next
  }

  function stepWords(dt) {
    var list = words
    if (list.length === 0) return
    var floorY = board.height - Style.space(46)
    var kept = []
    var lost = 0
    for (var i = 0; i < list.length; i++) {
      var w = list[i]
      var y = w.y + w.speed * dt
      if (y > floorY) { lost += 1; continue }
      kept.push({ key: w.key, text: w.text, x: w.x, y: y, speed: w.speed })
    }
    if (lost > 0) {
      lives = Math.max(0, lives - lost)
      if (lives <= 0) {
        words = kept
        finish()
        return
      }
    }
    words = kept
  }

  function typeFalling(ch) {
    var next = buffer + ch
    var best = null
    for (var i = 0; i < words.length; i++) {
      var w = words[i]
      if (w.text.indexOf(next) === 0) {
        if (!best || w.y > best.y) best = w
      }
    }
    if (!best) {
      record(ch, false)
      buffer = ""
      return
    }
    record(ch, true)
    buffer = next
    if (next === best.text) {
      score += Math.round(best.text.length * 2 + Math.max(0, 20 - best.y / 8))
      buffer = ""
      var kept = []
      for (var j = 0; j < words.length; j++) {
        if (words[j].key !== best.key) kept.push(words[j])
      }
      words = kept
    }
  }

  // ------------------------------------------------------------------ sprint

  function typeSprint(ch) {
    var word = currentWord
    if (!word) return
    var expected = word.charAt(typed.length)
    if (ch === expected) {
      record(ch, true)
      typed += ch
      if (typed === word) {
        score += 1
        queueIndex += 1
        typed = ""
      }
    } else {
      record(ch, false)
    }
  }

  // -------------------------------------------------------------------- hunt

  function newTarget() {
    var pool = "asdfghjkl"
    if (score > 4) pool = "asdfghjklqeiruoty"
    if (score > 10) pool = "asdfghjklqwertyuiopzxcvbnm"
    target = pool.charAt(Math.floor(Math.random() * pool.length))
  }

  function typeHunt(ch) {
    if (ch.toLowerCase() === target) {
      record(target, true)
      score += 1
      newTarget()
    } else {
      record(ch, false)
    }
  }

  // --------------------------------------------------------------- speed burst

  function nextBurstChar() {
    var pool = "asdfghjklqwertyuiopzxcvbnm"
    burstChar = pool.charAt(Math.floor(Math.random() * pool.length))
  }

  function typeBurst(ch) {
    if (!burstChar) return
    if (ch.toLowerCase() === burstChar) {
      record(ch, true)
      score += 1
      nextBurstChar()
    } else {
      record(ch, false)
    }
  }

  // ---------------------------------------------------------- accuracy gauntlet

  function nextGauntletWord() {
    var text = Words.pick(Words.COMMON)
    if (text.length < 3) text = Words.pick(Words.EVERYDAY)
    gauntletWord = text
  }

  function typeGauntlet(ch) {
    var word = gauntletWord
    if (!word) return
    var expected = word.charAt(gauntletTyped.length)
    if (ch === expected) {
      record(ch, true)
      gauntletTyped += ch
      if (gauntletTyped === word) {
        score += 1
        nextGauntletWord()
        gauntletTyped = ""
      }
    } else {
      record(ch, false)
      finish()
    }
  }

  // ------------------------------------------------------------ pattern mirror

  function nextMirrorRound() {
    var pool = "asdfghjkl"
    if (mirrorRound > 3) pool = "asdfghjklqwertyuiop"
    if (mirrorRound > 6) pool = "asdfghjklqwertyuiopzxcvbnm"
    var len = Math.min(8, 3 + mirrorRound)
    mirrorSequence = []
    for (var i = 0; i < len; i++) {
      mirrorSequence.push(pool.charAt(Math.floor(Math.random() * pool.length)))
    }
    mirrorIndex = 0
  }

  function typeMirror(ch) {
    var expected = mirrorSequence[mirrorIndex]
    if (!expected) return
    if (ch.toLowerCase() === expected) {
      record(ch, true)
      mirrorIndex += 1
      score += 1
      if (mirrorIndex >= mirrorSequence.length) {
        mirrorRound += 1
        nextMirrorRound()
      }
    } else {
      record(ch, false)
      finish()
    }
  }

  // ------------------------------------------------------------------- clock

  function tickClock(dt) {
    elapsed += dt
    timeLeft = Math.max(0, duration - elapsed)
    if (timeLeft <= 0) finish()
  }

  function finish() {
    if (finished) return
    running = false
    finished = true
    spawnTimer.stop()
    frameTimer.stop()
    clockTimer.stop()

    gameOver({
      score: score,
      seconds: Math.max(1, elapsed),
      keystrokes: hits + misses,
      hits: hits,
      misses: misses,
      keyLog: JSON.parse(JSON.stringify(keyLog)),
      bigramLog: JSON.parse(JSON.stringify(bigramLog))
    })
  }

  Timer {
    id: frameTimer
    interval: 50
    repeat: true
    running: board.running && board.mode === "falling"
    onTriggered: {
      var dt = interval / 1000

      // tickClock already advances elapsed; doing it here too made falling
      // words fall through a clock running at double speed.
      board.tickClock(dt)
      if (board.running) board.stepWords(dt)
    }
  }

  Timer {
    id: spawnTimer
    interval: 1150
    repeat: true
    running: board.running && board.mode === "falling"
    onTriggered: if (board.words.length < 7) board.spawnWord(false)
  }

  Timer {
    id: clockTimer
    interval: 100
    repeat: true
    running: board.running && board.mode !== "falling" && board.mode !== "gauntlet" && board.mode !== "mirror"
    onTriggered: board.tickClock(interval / 1000)
  }

  // ------------------------------------------------------------------- paint

  // Falling words.
  Repeater {
    model: board.mode === "falling" ? board.words : []

    delegate: Item {
      id: fallingWord
      required property var modelData
      x: fallingWord.modelData.x
      y: fallingWord.modelData.y
      width: wordText.implicitWidth
      height: wordText.implicitHeight
      visible: board.running || board.finished

      readonly property string matched: {
        if (!board.buffer) return ""
        return fallingWord.modelData.text.indexOf(board.buffer) === 0 ? board.buffer : ""
      }

      Text {
        id: wordText
        text: fallingWord.modelData.text
        font.family: Style.font.family
        font.pixelSize: board.gameFontSize
        color: Util.alpha(Color.foreground, 0.72)
        visible: false
      }

      Row {
        spacing: 0

        Text {
          text: fallingWord.matched
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: board.gameFontSize
        }

        Text {
          text: fallingWord.modelData.text.slice(fallingWord.matched.length)
          color: fallingWord.matched.length > 0 ? Color.foreground : Util.alpha(Color.foreground, 0.72)
          font.family: Style.font.family
          font.pixelSize: board.gameFontSize
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom
        anchors.topMargin: Style.space(2)
        height: 1
        color: Util.alpha(Color.foreground, 0.10)
      }
    }
  }

  // Sprint word strip.
  Flow {
    visible: board.mode === "sprint"
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.space(12)

    Repeater {
      model: board.mode === "sprint" ? board.sprintWords.slice(board.queueIndex, board.queueIndex + 24) : []

      delegate: Item {
        id: sprintCell
        required property var modelData
        required property int index

        readonly property bool current: sprintCell.index === 0

        width: sprintRow.implicitWidth
        height: sprintRow.implicitHeight + Style.space(6)

        Row {
          id: sprintRow
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Text {
            text: sprintCell.current ? sprintCell.modelData.slice(0, board.typed.length) : ""
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: board.gameFontSize
          }

          Text {
            text: sprintCell.current ? sprintCell.modelData.slice(board.typed.length) : sprintCell.modelData
            color: sprintCell.current
              ? Color.foreground
              : Util.alpha(Color.foreground, 0.30)
            font.family: Style.font.family
            font.pixelSize: board.gameFontSize
          }
        }

        Rectangle {
          visible: sprintCell.current
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 2
          radius: 0
          color: Util.alpha(Color.accent, 0.70)
        }
      }
    }
  }

  // Hunt target.
  Item {
    visible: board.mode === "hunt"
    anchors.fill: parent

    Rectangle {
      anchors.centerIn: parent
      width: Style.space(150)
      height: width
      radius: 0
      color: Util.alpha(Color.accent, 0.06)
      border.width: 1
      border.color: Util.alpha(Color.accent, 0.30)
    }

    Text {
      anchors.centerIn: parent
      text: board.target.toUpperCase()
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.display * 2.6)
      font.letterSpacing: 2
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.verticalCenter
      anchors.topMargin: Style.space(96)
      text: "find it without looking down"
      color: Util.alpha(Color.foreground, 0.54)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Speed burst — one letter at a time, fifteen seconds.
  Item {
    visible: board.mode === "burst"
    anchors.fill: parent

    Text {
      anchors.centerIn: parent
      text: board.burstChar.toUpperCase()
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.display * 2.8)
      font.letterSpacing: 4
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.verticalCenter
      anchors.topMargin: Style.space(120)
      text: Math.ceil(board.timeLeft) + " s left"
      color: board.timeLeft <= 5 ? Color.urgent : Util.alpha(Color.foreground, 0.54)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Accuracy gauntlet — endless words, one miss ends the run.
  Row {
    visible: board.mode === "gauntlet"
    anchors.centerIn: parent
    spacing: 0

    Text {
      text: board.gauntletWord.slice(0, board.gauntletTyped.length)
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Math.round(board.gameFontSize * 1.25)
    }

    Text {
      text: board.gauntletWord.slice(board.gauntletTyped.length)
      color: Util.alpha(Color.foreground, 0.72)
      font.family: Style.font.family
      font.pixelSize: Math.round(board.gameFontSize * 1.25)
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(8)
      text: board.score + " words"
      color: Util.alpha(Color.foreground, 0.54)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Pattern mirror — sequence memory, one more letter each round.
  Item {
    visible: board.mode === "mirror"
    anchors.fill: parent

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Style.space(40)
      text: board.mirrorSequence.join(" ").toUpperCase()
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Math.round(board.gameFontSize * 1.4)
      font.letterSpacing: 2
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Style.space(80)
      text: "round " + (board.mirrorRound + 1) + " · type it back"
      color: Util.alpha(Color.foreground, 0.54)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(40)
      text: board.score + " letters"
      color: Util.alpha(Color.foreground, 0.54)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Live HUD. A run with no visible score, lives or clock gives the player
  // nothing to steer by between the start prompt and the game-over card.
  Item {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Style.space(20)
    visible: board.running

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: board.score + (board.score === 1 ? " point" : " points")
      color: Util.alpha(Color.foreground, 0.66)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(5)
      visible: board.mode === "falling"

      Repeater {
        model: 3

        delegate: Rectangle {
          width: Style.space(6)
          height: width
          radius: 0
          color: index < board.lives
            ? Util.alpha(Color.accent, 0.85)
            : Util.alpha(Color.foreground, 0.16)
        }
      }
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: board.mode !== "falling" && board.mode !== "gauntlet" && board.mode !== "mirror"
      text: Math.max(0, Math.ceil(board.timeLeft)) + " s left"
      color: board.timeLeft <= 10 ? Color.urgent : Util.alpha(Color.foreground, 0.66)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Idle and finished overlays.
  Rectangle {
    anchors.fill: parent
    visible: !board.running
    color: Util.alpha(Color.background, 0.82)

    Column {
      anchors.centerIn: parent
      width: parent.width - Style.space(40)
      spacing: Style.space(10)

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: board.finished ? "Game over" : (board.mode === "falling" ? "Falling words" : board.mode === "sprint" ? "Word sprint" : board.mode === "hunt" ? "Key hunt" : board.mode === "burst" ? "Speed burst" : board.mode === "gauntlet" ? "Accuracy gauntlet" : "Pattern mirror")
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        // Accuracy of a run with no keystrokes is undefined, not zero. A
        // falling game lost to the clock alone should not read "0%".
        text: {
          if (!board.finished) {
            if (board.mode === "falling") return "Type the words before they reach the floor. Three misses and the run ends."
            if (board.mode === "sprint") return "Type each word in order. Forty-five seconds, as many words as you can."
            if (board.mode === "hunt") return "A letter appears. Press it without looking. Forty-five seconds."
            if (board.mode === "burst") return "Type each letter as fast as you can. Fifteen seconds on the clock."
            if (board.mode === "gauntlet") return "Type each word. One wrong key ends the run. No clock."
            return "Type the sequence back. Each round adds one more letter."
          }
          var parts = [board.score + (board.score === 1 ? " point" : " points")]
          var taps = board.hits + board.misses
          if (taps > 0) parts.push(Math.round(board.hits / taps * 100) + "% accuracy")
          else parts.push("no keystrokes")
          return parts.join(" · ")
        }
        color: Util.alpha(Color.foreground, 0.70)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "press space to " + (board.finished ? "play again" : "start")
        color: Util.alpha(Color.accent, 0.85)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  Text {
    visible: board.mode === "falling" && board.running && board.buffer.length > 0
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(6)
    text: "typing: " + board.buffer
    color: Util.alpha(Color.accent, 0.85)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
