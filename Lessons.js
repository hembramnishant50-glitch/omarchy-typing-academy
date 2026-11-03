.pragma library

// The curriculum. One flat lesson list plus stage metadata; the Learn tab
// groups them, and the Progress tab counts stars per stage.
//
// A lesson's `text` is the passage the learner types. Keeping it inline (and
// short) makes the difficulty of each step obvious when reading this file.

var STAGES = [
  { id: "home", title: "Home row", blurb: "Where the hands live. Find the two anchor keys first." },
  { id: "top", title: "Top row", blurb: "Reach up without leaving the home position." },
  { id: "bottom", title: "Bottom row", blurb: "The row that feels furthest away, one key at a time." },
  { id: "shift", title: "Capital letters", blurb: "Opposite-hand shift, so the reach never fights itself." },
  { id: "punct", title: "Punctuation", blurb: "Commas, quotes and the keys wearing two labels." },
  { id: "numbers", title: "Numbers", blurb: "The number row, pressed from the home row." },
  { id: "symbols", title: "Symbols", blurb: "Brackets, operators and the code keyboard." },
  { id: "speed", title: "Speed", blurb: "Real words and real sentences at a rising tempo." }
]

var LESSONS = [
  // ---------------------------------------------------------------- home row
  {
    id: "home-fj", stage: "home", title: "F and J",
    blurb: "The two keys with raised marks. Everything is measured from here.",
    keys: ["f", "j"],
    text: "ff jj fj jf ff jj fj jf fj jf ff jj f j fj jf ff jj fj jf",
    targetWpm: 14, targetAcc: 94
  },
  {
    id: "home-dk", stage: "home", title: "D and K",
    blurb: "Middle fingers, straight down from the anchors.",
    keys: ["d", "k"],
    text: "dd kk dk kd dd kk dk kd fj jf dk kd dd kk kd dk jf fj dd kk",
    targetWpm: 15, targetAcc: 94
  },
  {
    id: "home-sl", stage: "home", title: "S and L",
    blurb: "Ring fingers. Small movements, no lifting the hand.",
    keys: ["s", "l"],
    text: "ss ll sl ls ss ll sl ls fj jf dk kd sl ls ss ll ls sl dd kk",
    targetWpm: 16, targetAcc: 94
  },
  {
    id: "home-a", stage: "home", title: "A and semicolon",
    blurb: "Pinky keys, the weakest fingers. Keep the other fingers planted.",
    keys: ["a", ";"],
    text: "aa ;; a; ;a aa ;; a; ;a fj jf dk kd sl ls a; ;a ss ll aa ;;",
    targetWpm: 16, targetAcc: 93
  },
  {
    id: "home-gh", stage: "home", title: "G and H",
    blurb: "Index fingers stretch inward for the last two home keys.",
    keys: ["g", "h"],
    text: "gg hh gh hg gg hh gh hg fj jf dk kd sl ls a; ;a gh hg gg hh",
    targetWpm: 17, targetAcc: 93
  },
  {
    id: "home-all", stage: "home", title: "Home row words",
    blurb: "Everything you know so far, shaped into real words.",
    keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
    text: "as ask all fall had hall lag gas sad glad flag flash dash hash lash glad flask salad glass shall alaska half solid skill",
    targetWpm: 20, targetAcc: 94
  },

  // ----------------------------------------------------------------- top row
  {
    id: "top-ei", stage: "top", title: "E and I",
    blurb: "Middle fingers up one row and back down.",
    keys: ["e", "i"],
    text: "ee ii ei ie ee ii ei ie ded kik ded kik ei ie ee ii de ki de ki",
    targetWpm: 18, targetAcc: 94
  },
  {
    id: "top-ru", stage: "top", title: "R and U",
    blurb: "Index fingers, a diagonal reach from F and J.",
    keys: ["r", "u"],
    text: "rr uu ru ur rr uu ru ur frf juj frf juj ru ur rr uu fr ju fr ju",
    targetWpm: 18, targetAcc: 94
  },
  {
    id: "top-ty", stage: "top", title: "T and Y",
    blurb: "The longest stretch on the top row. Move the finger, not the wrist.",
    keys: ["t", "y"],
    text: "tt yy ty yt tt yy ty yt ftf jyj ftf jyj ty yt tt yy ft jy ft jy",
    targetWpm: 18, targetAcc: 93
  },
  {
    id: "top-wo", stage: "top", title: "W and O",
    blurb: "Ring fingers reach up.",
    keys: ["w", "o"],
    text: "ww oo wo ow ww oo wo ow sws lol sws lol wo ow ww oo sw lo sw lo",
    targetWpm: 19, targetAcc: 93
  },
  {
    id: "top-qp", stage: "top", title: "Q and P",
    blurb: "Pinkies again, the furthest keys on this row.",
    keys: ["q", "p"],
    text: "qq pp qp pq qq pp qp pq aqa ;p; aqa ;p; qp pq qq pp aq p; aq p;",
    targetWpm: 19, targetAcc: 92
  },
  {
    id: "top-words", stage: "top", title: "Top row words",
    blurb: "Two rows working together.",
    keys: ["e", "r", "t", "y", "u", "i", "o", "p", "q", "w"],
    text: "we you try toy out our put top quiet type route power write upset proper quietly report reply equip store effort order piece",
    targetWpm: 24, targetAcc: 94
  },

  // -------------------------------------------------------------- bottom row
  {
    id: "bot-vn", stage: "bottom", title: "V and N",
    blurb: "Index fingers reach down.",
    keys: ["v", "n"],
    text: "vv nn vn nv vv nn vn nv fvf jnj fvf jnj vn nv vv nn fv jn fv jn",
    targetWpm: 18, targetAcc: 93
  },
  {
    id: "bot-cm", stage: "bottom", title: "C and M",
    blurb: "Middle fingers, straight down.",
    keys: ["c", "m"],
    text: "cc mm cm mc cc mm cm mc dcd kmk dcd kmk cm mc cc mm dc km dc km",
    targetWpm: 18, targetAcc: 93
  },
  {
    id: "bot-b", stage: "bottom", title: "B",
    blurb: "Left index, the awkward one. Reach down and in.",
    keys: ["b"],
    text: "bb bb bbb bbbb fb bf gb bg bb vb bv bb bn nb bb bb bbb bbbb fb bf",
    targetWpm: 18, targetAcc: 92
  },
  {
    id: "bot-xz", stage: "bottom", title: "X and Z",
    blurb: "Pinkies and ring fingers, the rarest letters in English.",
    keys: ["x", "z"],
    text: "xx zz xz zx xx zz xz zx sxs az aza sxs zx xz xx zz sx az sx az",
    targetWpm: 17, targetAcc: 92
  },
  {
    id: "bot-punct", stage: "bottom", title: "Comma, period, slash",
    blurb: "Right hand punctuation on the bottom row.",
    keys: [",", ".", "/"],
    text: "aa, ss. dd/ ff, jj. kk/ ll, ;; . .. ,, // ,. /, ., a, s. d/ f, j.",
    targetWpm: 18, targetAcc: 92
  },
  {
    id: "bot-words", stage: "bottom", title: "Bottom row words",
    blurb: "All three rows, one alphabet.",
    keys: ["c", "v", "b", "n", "m", "x", "z"],
    text: "can come back next box move very number because climb brave mix zone exact cabin bronze maximum twelve bounce",
    targetWpm: 24, targetAcc: 94
  },

  // ------------------------------------------------------------------ capital
  {
    id: "shift-basic", stage: "shift", title: "Shift with the other hand",
    blurb: "Press the letter with one hand and shift with the other.",
    keys: ["A", "S", "J", "K"],
    text: "Aa Ss Jj Kk Aa Ss Jj Kk Ff Dd Ll Ee Aa Jj Kk Ss Dd Ff Ll",
    targetWpm: 18, targetAcc: 92
  },
  {
    id: "shift-words", stage: "shift", title: "Capitalised words",
    blurb: "Sentences begin with a capital. Make it one motion.",
    keys: ["A", "T", "W"],
    text: "The Week Ahead London Paris Monday Tuesday Wednesday Thursday Friday Saturday Sunday March April August",
    targetWpm: 22, targetAcc: 93
  },
  {
    id: "shift-sentences", stage: "shift", title: "Sentence case",
    blurb: "Capital at the start, full stop at the end.",
    keys: ["A", "I"],
    text: "The sun rose slowly. I watched it from the roof. A bird sang once and then was quiet. Nothing else moved.",
    targetWpm: 26, targetAcc: 94
  },

  // -------------------------------------------------------------- punctuation
  {
    id: "punct-end", stage: "punct", title: "Comma and full stop",
    blurb: "The two most common marks in English.",
    keys: [",", "."],
    text: "First, second, third. Then again, and again. Small steps, steady pace. Keep going, stay calm.",
    targetWpm: 24, targetAcc: 93
  },
  {
    id: "punct-quote", stage: "punct", title: "Apostrophe and quotes",
    blurb: "Apostrophes sit under the right pinky, quotes under the left.",
    keys: ["'", "\""],
    text: "It's fine, don't worry. She said \"hello\" and left. We'll meet at nine, they're late again.",
    targetWpm: 24, targetAcc: 92
  },
  {
    id: "punct-marks", stage: "punct", title: "Colon, semicolon, question",
    blurb: "Shift plus a home row key. Same finger, extra reach.",
    keys: [":", ";", "?", "!"],
    text: "Wait: what happened? Nothing; it was fine. Who said that? They did! Try again: one more time.",
    targetWpm: 24, targetAcc: 92
  },
  {
    id: "punct-mixed", stage: "punct", title: "Punctuated sentences",
    blurb: "Real prose with every mark in its place.",
    keys: [",", ".", "'", "?", "!"],
    text: "\"Type slowly,\" she said. \"Accuracy comes first; speed is a side effect.\" He nodded, unconvinced, and began again. It's working, isn't it?",
    targetWpm: 28, targetAcc: 93
  },

  // ------------------------------------------------------------------ numbers
  {
    id: "num-12345", stage: "numbers", title: "1 to 5",
    blurb: "Left hand on the number row, returning home between presses.",
    keys: ["1", "2", "3", "4", "5"],
    text: "11 22 33 44 55 12 23 34 45 51 13 24 35 41 52 11 22 33 44 55",
    targetWpm: 16, targetAcc: 92
  },
  {
    id: "num-67890", stage: "numbers", title: "6 to 0",
    blurb: "Right hand this time. Same rule: come back to the home row.",
    keys: ["6", "7", "8", "9", "0"],
    text: "66 77 88 99 00 67 78 89 90 06 68 79 80 09 60 66 77 88 99 00",
    targetWpm: 16, targetAcc: 92
  },
  {
    id: "num-mixed", stage: "numbers", title: "Numbers in context",
    blurb: "Dates, times and amounts, the way numbers actually appear.",
    keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
    text: "Call 555 0123 at 9:30 on 2026 11 01. Room 42, floor 7, seat 128. Pay 1499 by the 15th, not the 30th.",
    targetWpm: 20, targetAcc: 92
  },

  // ------------------------------------------------------------------ symbols
  {
    id: "sym-brackets", stage: "symbols", title: "Brackets",
    blurb: "Square and curly brackets live on the top row, shifted.",
    keys: ["[", "]", "{", "}"],
    text: "[a] [b] (c) (d) {e} {f} [x] {y} [1] {2} [q] {w} [] [] {} {} [] {}",
    targetWpm: 18, targetAcc: 91
  },
  {
    id: "sym-math", stage: "symbols", title: "Operators",
    blurb: "Plus, minus, equals, star, ampersand.",
    keys: ["+", "-", "=", "*", "&"],
    text: "1 + 2 = 3, 4 - 1 = 3, 6 * 2 = 12. a & b, x = y + 1. Total: 10 - 3 + 5 = 12.",
    targetWpm: 20, targetAcc: 91
  },
  {
    id: "sym-code", stage: "symbols", title: "Code punctuation",
    blurb: "Braces, semicolons and underscores in one line.",
    keys: ["{", "}", ";", "_", "(", ")"],
    text: "const name = \"value\"; function run() { return item_total + 1; } if (ready) { go(); }",
    targetWpm: 22, targetAcc: 91
  },

  // -------------------------------------------------------------------- speed
  {
    id: "speed-common", stage: "speed", title: "The common hundred",
    blurb: "The words that make up a third of everything written.",
    keys: [],
    text: "the be to of and a in that have it for not on with he as you do at this but his by from they we say her she or an will my one all would there their what so up out if about",
    targetWpm: 40, targetAcc: 95
  },
  {
    id: "speed-sentences", stage: "speed", title: "Sentences",
    blurb: "Sixteen short sentences, no repeated target.",
    keys: [],
    text: "The quick brown fox jumps over the lazy dog. Practice a little every day and the speed will come. Keep your fingers on the home row and your eyes on the screen.",
    targetWpm: 45, targetAcc: 95
  },
  {
    id: "speed-paragraph", stage: "speed", title: "Paragraph",
    blurb: "Punctuation, capitals and rhythm all at once.",
    keys: [],
    text: "Touch typing is not about moving your fingers quickly. It is about removing doubt. When each finger knows where it belongs, you stop hunting for keys and start reading ahead.",
    targetWpm: 50, targetAcc: 96
  }
]

function stageFor(id) {
  for (var i = 0; i < STAGES.length; i++) {
    if (STAGES[i].id === id) return STAGES[i]
  }
  return null
}

function lessonsIn(stageId) {
  var out = []
  for (var i = 0; i < LESSONS.length; i++) {
    if (LESSONS[i].stage === stageId) out.push(LESSONS[i])
  }
  return out
}

function find(id) {
  for (var i = 0; i < LESSONS.length; i++) {
    if (LESSONS[i].id === id) return LESSONS[i]
  }
  return null
}

function indexOf(id) {
  for (var i = 0; i < LESSONS.length; i++) {
    if (LESSONS[i].id === id) return i
  }
  return 0
}

// A lesson is unlocked when it is the first of the curriculum or when the
// lesson before it has been completed. Teachers will recognise this.
function unlocked(profile, lesson) {
  if (!lesson) return false
  var i = indexOf(lesson.id)
  if (i === 0) return true
  var prev = LESSONS[i - 1]
  var rec = profile && profile.lessons ? profile.lessons[prev.id] : null
  return !!(rec && rec.done)
}

function nextLesson(profile) {
  for (var i = 0; i < LESSONS.length; i++) {
    var rec = profile && profile.lessons ? profile.lessons[LESSONS[i].id] : null
    if (!rec || !rec.done) return LESSONS[i]
  }
  return null
}

function completedCount(profile) {
  var n = 0
  for (var i = 0; i < LESSONS.length; i++) {
    var rec = profile && profile.lessons ? profile.lessons[LESSONS[i].id] : null
    if (rec && rec.done) n++
  }
  return n
}

function starsFor(record) {
  if (!record || !record.bestWpm) return 0
  var lesson = null
  for (var i = 0; i < LESSONS.length; i++) {
    if (LESSONS[i].id === record.lessonId) { lesson = LESSONS[i]; break }
  }
  var wpmTarget = lesson ? lesson.targetWpm : 20
  var accTarget = lesson ? lesson.targetAcc : 94
  var stars = 0
  if (record.bestAcc >= Math.max(88, accTarget - 6)) stars = 1
  if (record.bestAcc >= accTarget && record.bestWpm >= wpmTarget) stars = 2
  if (record.bestAcc >= Math.min(99, accTarget + 3) && record.bestWpm >= wpmTarget * 1.25) stars = 3
  return stars
}
