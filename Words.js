.pragma library

// Text corpus for lessons, drills and tests. Everything here is plain data;
// the generators at the bottom are pure functions of Math.random so a passage
// can be rebuilt without holding on to state.

var COMMON = ("the be to of and a in that have it for not on with he as you do at this but his " +
  "by from they we say her she or an will my one all would there their what so up out if " +
  "about who get which go me when make can like time no just him know take people into year " +
  "your good some could them see other than then now look only come its over think also back " +
  "after use two how our work first well way even new want because any these give day most us").split(" ")

var EVERYDAY = ("home house water light music small large early clear young world night morning " +
  "letter number window garden simple person family friend school street market coffee dinner " +
  "summer winter travel river ocean forest mountain village city paper pencil table chair floor " +
  "ceiling garden kitchen office library station ticket pocket silver golden quiet bright gentle " +
  "strong happy tired ready open close begin finish answer question story picture memory moment " +
  "reason change choice future period season minute second hour week month garden orchard").split(" ")

var LONGER = ("morning thought another between problem different important together probably " +
  "remember consider continue describe discover position question sentence possible practice " +
  "computer keyboard accuracy language exercise progress lesson rhythm balance comfort " +
  "adventure ordinary beautiful wonderful afternoon experience knowledge direction " +
  "understanding performance concentration").split(" ")

var SYLLABLES = ("al be ca de fi go hu ja ki lo ma ne po qui ra si to vu wa xe yo za " +
  "bri cra dre fla gru hin jol kle man nor pel rus tan ver win zel").split(" ")

var SENTENCES = [
  "The quick brown fox jumps over the lazy dog.",
  "Practice a little every day and the speed will come.",
  "Keep your fingers on the home row and your eyes on the screen.",
  "A calm rhythm beats a fast burst that falls apart.",
  "Accuracy first, then speed, and never the other way round.",
  "Rest your wrists, relax your shoulders, and breathe.",
  "Small steady steps cover more ground than one long sprint.",
  "The best time to build a habit is before you need it.",
  "Look at the words ahead, not at the letter you are typing.",
  "Every mistake tells you which key to practise next.",
  "Type to the beat of your own breathing.",
  "Slow is smooth and smooth becomes fast.",
  "Your hands already know the shape of the keyboard.",
  "A quiet room and a warm cup make the hour pass quickly.",
  "The cursor keeps moving, so let the errors go.",
  "Measure the week, not the minute."
]

var PARAGRAPHS = [
  "Touch typing is not about moving your fingers quickly. It is about removing doubt. When each finger knows where it belongs, you stop hunting for keys and start reading ahead. The speed you see in a fast typist is really a lack of hesitation, and hesitation is the only thing practice actually removes. Sit tall, keep your wrists off the desk, and let the small muscles of the hand do the work.",
  "A good practice session has a shape. Begin slowly enough that you can be accurate, hold that speed until it feels boring, then push the tempo just past comfortable. When the errors arrive, drop back down. This is the same loop a musician uses, and it works because the hands learn from repetition that is correct, not from repetition that is merely fast.",
  "The home row is the anchor of the whole keyboard. Your index fingers rest on the two keys with the raised marks, and every other finger lines up beside them. From that position, each key belongs to exactly one finger, and the journey is short. When you lose your place, do not look down. Feel for the marks, reset, and continue."
]

var QUOTES = [
  { text: "We are what we repeatedly do. Excellence, then, is not an act but a habit.", who: "Aristotle" },
  { text: "It is not that I am so smart, it is just that I stay with problems longer.", who: "Albert Einstein" },
  { text: "Simplicity is the ultimate sophistication.", who: "Leonardo da Vinci" },
  { text: "The only way to do great work is to love what you do.", who: "Steve Jobs" },
  { text: "Programs must be written for people to read, and only incidentally for machines to execute.", who: "Harold Abelson" },
  { text: "Any fool can write code that a computer can understand. Good programmers write code that humans can understand.", who: "Martin Fowler" },
  { text: "Talk is cheap. Show me the code.", who: "Linus Torvalds" },
  { text: "Premature optimization is the root of all evil.", who: "Donald Knuth" },
  { text: "The best way to predict the future is to invent it.", who: "Alan Kay" }
]

// The three-letter groups that show up over and over in English. Drilling them
// as chunks is what turns letter-by-letter typing into word-shaped movement.
var TRIGRAMS = ("the and ing her hat his tha ere for ent ion ter was you ith ver all " +
  "wit thi tio nde has ome men est ove ain ate one our out day get hin hic ndt").split(" ")

function randInt(n) {
  return Math.floor(Math.random() * n)
}

function pick(list) {
  return list[randInt(list.length)]
}

function shuffle(list) {
  var out = list.slice()
  for (var i = out.length - 1; i > 0; i--) {
    var j = randInt(i + 1)
    var t = out[i]
    out[i] = out[j]
    out[j] = t
  }
  return out
}

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1)
}

// A pool weighted toward the words people actually type.
function wordPool() {
  var pool = COMMON.concat(EVERYDAY).concat(EVERYDAY).concat(LONGER)
  return pool
}

function decorate(word, punctuation, numbers) {
  var out = word
  if (numbers && Math.random() < 0.10) {
    out = String(randInt(9000) + 100)
  }
  if (punctuation) {
    var roll = Math.random()
    if (roll < 0.10) out = capitalize(out)
    if (roll > 0.90) out = out + "."
    else if (roll > 0.84) out = out + ","
    else if (roll > 0.80) out = out + "?"
    else if (roll > 0.77) out = out + "!"
    else if (roll > 0.75) out = "\"" + out + "\""
    else if (roll > 0.73) out = "(" + out + ")"
  }
  return out
}

function makeWords(count, opts) {
  var o = opts || {}
  var pool = wordPool()
  var words = []
  var bag = []
  while (words.length < count) {
    if (bag.length === 0) bag = shuffle(pool)
    var w = bag.pop()
    if (!w) continue
    words.push(decorate(w, o.punctuation === true, o.numbers === true))
  }
  return words.join(" ")
}

function makeSentences(count) {
  var out = []
  for (var i = 0; i < count; i++) out.push(pick(SENTENCES))
  return out.join(" ")
}

function makeParagraph() {
  return pick(PARAGRAPHS)
}

function makeQuote(length) {
  var pool = QUOTES
  if (length === "short") pool = QUOTES.filter(function (q) { return q.text.length < 90 })
  if (length === "long") pool = QUOTES.filter(function (q) { return q.text.length >= 90 })
  if (pool.length === 0) pool = QUOTES
  var q = pick(pool)
  return { text: q.text, who: q.who }
}

// Words that actually contain the target letters, so a key drill reads like
// language rather than alphabet soup.
function wordsWith(keys, count) {
  var pool = wordPool()
  var out = []
  var wanted = keys.map(function (k) { return String(k).toLowerCase() })
  for (var i = 0; i < pool.length && out.length < count; i++) {
    var w = pool[i]
    for (var j = 0; j < wanted.length; j++) {
      if (w.indexOf(wanted[j]) !== -1) {
        out.push(w)
        break
      }
    }
  }
  if (out.length === 0) return makeWords(count)
  var result = []
  while (result.length < count) result = result.concat(out)
  return result.slice(0, count).join(" ")
}

// Short nonsense syllables built from the target keys. Repeating a small
// alphabet forces the hand to find the same key over and over, which is what
// builds the map.
function makeKeyDrill(keys, chars) {
  var list = keys.map(function (k) { return String(k) })
  if (list.length === 0) return ""
  var target = chars || 220
  var out = []
  var len = 0
  while (len < target) {
    var syllables = 2 + randInt(2)
    var word = ""
    for (var s = 0; s < syllables; s++) {
      var n = 1 + randInt(2)
      for (var c = 0; c < n; c++) word += pick(list)
    }
    out.push(word)
    len += word.length + 1
  }
  return out.join(" ")
}

function makeBigramDrill(pairs, chars) {
  var list = pairs.slice()
  if (list.length === 0) return ""
  var target = chars || 200
  var out = []
  var len = 0
  while (len < target) {
    var word = ""
    var n = 2 + randInt(2)
    for (var i = 0; i < n; i++) word += pick(list)
    out.push(word)
    len += word.length + 1
  }
  return out.join(" ")
}

// Common three-letter chunks. Two of them joined makes a token that the hands
// can learn as one shape instead of three separate reaches.
function makeTrigramDrill(list, chars) {
  var pool = (list && list.length > 0 ? list : TRIGRAMS).slice()
  if (pool.length === 0) return ""
  var target = chars || 180
  var out = []
  var len = 0
  while (len < target) {
    var word = ""
    var n = 1 + randInt(2)
    for (var i = 0; i < n; i++) word += pick(pool)
    out.push(word)
    len += word.length + 1
  }
  return out.join(" ")
}

// Long enough that a 60 second test never runs out of words at any speed a
// human can type.
function makeTestText(mode, amount, opts) {
  if (mode === "quote") return makeQuote(opts && opts.quoteLength).text
  if (mode === "words") return makeWords(amount, opts)
  var wordCount = Math.max(60, Math.ceil(amount * 6))
  return makeWords(wordCount, opts)
}

// Alternating hands. Each token flips side on every character, so a four-letter
// token is left-right-left-right. Both pools are supplied by the caller, which
// keeps the layout knowledge (which key belongs to which hand) in DrillTab.
function makeAlternatingDrill(left, right, chars) {
  var a = (left || []).map(function (k) { return String(k) })
  var b = (right || []).map(function (k) { return String(k) })
  if (a.length === 0 || b.length === 0) return ""
  var target = chars || 200
  var out = []
  var len = 0
  while (len < target) {
    var pairs = 2 + randInt(2)
    var word = ""
    for (var i = 0; i < pairs; i++) word += pick(a) + pick(b)
    out.push(word)
    len += word.length + 1
  }
  return out.join(" ")
}

// Same-hand rolls: walk along one finger group's keys, bouncing off the ends so
// the hand has to reverse without leaving the row. This is the motion behind
// "asdf" and "jkl;" style rolls that fluent typing depends on.
function makeRollDrill(groups, chars) {
  var pool = (groups || []).filter(function (g) { return g && g.length > 1 })
  if (pool.length === 0) return ""
  var target = chars || 200
  var out = []
  var len = 0
  while (len < target) {
    var keys = pick(pool)
    var at = randInt(keys.length)
    var step = Math.random() < 0.5 ? 1 : -1
    var take = 3 + randInt(3)
    var word = ""
    for (var i = 0; i < take; i++) {
      word += keys[at]
      if (at + step < 0 || at + step >= keys.length) step = -step
      at += step
    }
    out.push(word)
    len += word.length + 1
  }
  return out.join(" ")
}
