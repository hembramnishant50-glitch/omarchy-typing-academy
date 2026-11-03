.pragma library

// ANSI QWERTY (US) geometry. Every key carries the finger that should press
// it in the home position; `alt` is the shifted glyph printed on the keycap.
//
// Finger ids are stable strings so they can key into a color table and into
// profile statistics without any translation step.

var FINGERS = [
  { id: "lp", name: "Left pinky",  color: "#6f86b8" },
  { id: "lr", name: "Left ring",   color: "#5fa3ad" },
  { id: "lm", name: "Left middle", color: "#6fa87a" },
  { id: "li", name: "Left index",  color: "#b9b564" },
  { id: "th", name: "Thumbs",      color: "#9095a0" },
  { id: "ri", name: "Right index", color: "#c7a25f" },
  { id: "rm", name: "Right middle", color: "#c47f75" },
  { id: "rr", name: "Right ring",  color: "#b178b4" },
  { id: "rp", name: "Right pinky", color: "#8d7fc4" }
]

// Shifted characters for the number and punctuation rows.
var SHIFTED = {
  "`": "~", "1": "!", "2": "@", "3": "#", "4": "$", "5": "%",
  "6": "^", "7": "&", "8": "*", "9": "(", "0": ")", "-": "_",
  "=": "+", "[": "{", "]": "}", "\\": "|", ";": ":", "'": "\"",
  ",": "<", ".": ">", "/": "?"
}

// Unshifted character for a shifted glyph, so a drill on "!" becomes "1".
function baseKey(ch) {
  if (!ch) return ch
  if (ch.length !== 1) return ch
  var k = String(ch)
  for (var plain in SHIFTED) {
    if (SHIFTED[plain] === k) return plain
  }
  return k.toLowerCase()
}

function needsShift(ch) {
  if (!ch || ch.length !== 1) return false
  if (ch >= "A" && ch <= "Z") return true
  for (var plain in SHIFTED) {
    if (SHIFTED[plain] === ch) return true
  }
  return false
}

function fingerFor(ch) {
  var k = baseKey(ch)
  var found = _fingerMap[k]
  return found ? found : ""
}

var ROWS = [
  {
    offset: 0,
    keys: [
      { ch: "`", finger: "lp" }, { ch: "1", finger: "lp" }, { ch: "2", finger: "lr" },
      { ch: "3", finger: "lm" }, { ch: "4", finger: "li" }, { ch: "5", finger: "li" },
      { ch: "6", finger: "ri" }, { ch: "7", finger: "ri" }, { ch: "8", finger: "rm" },
      { ch: "9", finger: "rr" }, { ch: "0", finger: "rp" }, { ch: "-", finger: "rp" },
      { ch: "=", finger: "rp" }
    ]
  },
  {
    offset: 0.35,
    keys: [
      { ch: "q", finger: "lp" }, { ch: "w", finger: "lr" }, { ch: "e", finger: "lm" },
      { ch: "r", finger: "li" }, { ch: "t", finger: "li" }, { ch: "y", finger: "ri" },
      { ch: "u", finger: "ri" }, { ch: "i", finger: "rm" }, { ch: "o", finger: "rr" },
      { ch: "p", finger: "rp" }, { ch: "[", finger: "rp" }, { ch: "]", finger: "rp" },
      { ch: "\\", finger: "rp" }
    ]
  },
  {
    offset: 0.55,
    keys: [
      { ch: "a", finger: "lp" }, { ch: "s", finger: "lr" }, { ch: "d", finger: "lm" },
      { ch: "f", finger: "li" }, { ch: "g", finger: "li" }, { ch: "h", finger: "ri" },
      { ch: "j", finger: "ri" }, { ch: "k", finger: "rm" }, { ch: "l", finger: "rr" },
      { ch: ";", finger: "rp" }, { ch: "'", finger: "rp" }
    ]
  },
  {
    offset: 0.85,
    keys: [
      { ch: "z", finger: "lp" }, { ch: "x", finger: "lr" }, { ch: "c", finger: "lm" },
      { ch: "v", finger: "li" }, { ch: "b", finger: "li" }, { ch: "n", finger: "ri" },
      { ch: "m", finger: "ri" }, { ch: ",", finger: "rm" }, { ch: ".", finger: "rr" },
      { ch: "/", finger: "rp" }
    ]
  }
]

// Space bar is rendered on its own so it can be one wide, centered cap.
var SPACE = { ch: " ", finger: "th" }

var _fingerMap = {}
for (var r = 0; r < ROWS.length; r++) {
  var row = ROWS[r]
  for (var i = 0; i < row.keys.length; i++) {
    _fingerMap[row.keys[i].ch] = row.keys[i].finger
  }
}
_fingerMap[" "] = "th"

function fingerColor(id) {
  for (var i = 0; i < FINGERS.length; i++) {
    if (FINGERS[i].id === id) return FINGERS[i].color
  }
  return "#9095a0"
}

function fingerName(id) {
  for (var i = 0; i < FINGERS.length; i++) {
    if (FINGERS[i].id === id) return FINGERS[i].name
  }
  return ""
}

function capLabel(ch) {
  if (ch === " ") return "space"
  return String(ch)
}

function altLabel(ch) {
  return SHIFTED[ch] ? SHIFTED[ch] : ""
}

// Home-position keys get a small tactile marker, the way real keycaps do.
function isHomeAnchor(ch) {
  return ch === "f" || ch === "j"
}
