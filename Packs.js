.pragma library

// Ready-made passages for the Drills tab. A pack is a single line with single
// spaces between words — the typing surface splits on spaces only, so a newline
// or a double space would produce a stray "word" the learner can never clear.
// Everything is ASCII so every character is reachable on a US layout.
//
// `hint` is shown under the passage title and doubles as the card subtitle.

var PACKS = [
  {
    id: "code-talk",
    title: "Code talk",
    hint: "The words you read all day, so your hands stop stalling on them.",
    text: "the function returns a value and the value is cached the cache is keyed by " +
      "argument and the argument is validated before the call the call is async and " +
      "the promise resolves once the request settles a request without a timeout is a " +
      "leak waiting to happen retry the failure with backoff and log the shape of the " +
      "error the shape is stable and the code is boring and boring code ships"
  },
  {
    id: "numbers",
    title: "Numbers in prose",
    hint: "Digits and words in the same breath, which is where most runs break.",
    text: "the server handled 4500 requests in 30 seconds and 12 of them failed the " +
      "queue drained in 8 seconds and the retry window is 90 seconds a batch of 64 " +
      "rows takes 250 milliseconds and 3 retries at most the limit is 1000 keys per " +
      "day and the key expires after 3600 seconds so renew it every 55 minutes"
  },
  {
    id: "punctuation",
    title: "Punctuation",
    hint: "Commas, quotes, brackets and stops; the keys that break a rhythm.",
    text: "there are three things to remember: measure first, change one thing, and " +
      "measure again. if the result is worse (and it usually is), revert it; if the " +
      "result is better, keep it. \"fast enough\" is a number, not a feeling; write " +
      "the number down. then write the date, the change, and the number again"
  },
  {
    id: "email",
    title: "Email phrasing",
    hint: "The sentences you actually have to type at work.",
    text: "thanks for the note; i have copied the relevant people so we can close this " +
      "out in one thread. the short version is that the deadline holds and the scope " +
      "does not, so please confirm which of the two you would like to move. if you " +
      "have a moment tomorrow morning i can walk you through the numbers and the " +
      "assumptions behind them. best regards and thanks again for the quick reply"
  },
  {
    id: "travel",
    title: "Travel",
    hint: "Place names, small logistics and the punctuation of a route.",
    text: "the train leaves from platform 4 at 7:15 and arrives in the old town just " +
      "after nine. from there it is a short walk to the harbour, where the ferry runs " +
      "every 40 minutes until midnight. buy the ticket at the kiosk, not on board, " +
      "and keep the receipt: the conductor will ask for it once, near the bridge"
  },
  {
    id: "caps",
    title: "Capitals",
    hint: "Shift on the opposite hand; proper nouns that keep showing up.",
    text: "On Monday the team met in Berlin to review the Apollo release with Dana and " +
      "Marcus. The next stop is Lisbon in March, then Osaka in June, then back to " +
      "London for the final review. Every city adds a page to the report, and every " +
      "page needs a name, a date, and a signature. September is the deadline"
  }
]

function list() {
  return PACKS
}

function find(id) {
  var key = String(id || "")
  for (var i = 0; i < PACKS.length; i++) {
    if (PACKS[i].id === key) return PACKS[i]
  }
  return null
}

// Returns { id, title, hint, text }. startDrill takes a plain string, so callers
// pass `pack.text` and use the title and hint for the session header.
function make(id) {
  var pack = find(id)
  return pack ? { id: pack.id, title: pack.title, hint: pack.hint, text: pack.text } : null
}
