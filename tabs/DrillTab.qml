import QtQuick
import qs.Commons
import "../components"
import "../Words.js" as Words
import "../Layout.js" as Layout
import "../Packs.js" as Packs
import "../Model.js" as Model

// Targeted practice. Every card here produces a passage and hands it to the
// Academy root, which owns the single PracticeView.
Item {
  id: root

  property var app
  property string customText: ""

  readonly property var profile: app ? app.profile : null
  readonly property var weak: profile ? Model.weakKeys(profile, 6) : []
  readonly property var slow: profile ? Model.slowKeys(profile, 6) : []
  readonly property var pairs: profile ? Model.weakBigrams(profile, 6) : []

  // Hand and finger membership comes from the layout table, so a drill can
  // never disagree with the on-screen keyboard about which finger owns a key.
  readonly property var leftKeys: keysForHand("l")
  readonly property var rightKeys: keysForHand("r")
  readonly property var rollGroups: [
    keysForFinger("li"), keysForFinger("lm"), keysForFinger("lr"),
    keysForFinger("ri"), keysForFinger("rm"), keysForFinger("rr")
  ]

  function keysForHand(side) {
    var out = []
    for (var r = 0; r < Layout.ROWS.length; r++) {
      var keys = Layout.ROWS[r].keys
      for (var i = 0; i < keys.length; i++) {
        var ch = String(keys[i].ch)
        if (ch.length === 1 && ch >= "a" && ch <= "z" && keys[i].finger.charAt(0) === side) out.push(ch)
      }
    }
    return out
  }

  function keysForFinger(id) {
    var out = []
    for (var r = 0; r < Layout.ROWS.length; r++) {
      var keys = Layout.ROWS[r].keys
      for (var i = 0; i < keys.length; i++) {
        var ch = String(keys[i].ch)
        if (ch.length === 1 && ch >= "a" && ch <= "z" && keys[i].finger === id) out.push(ch)
      }
    }
    return out
  }

  readonly property var drills: [
    {
      id: "weak", title: "Weak keys", hint: "Keys you most often get wrong, wrapped in real words.",
      build: function () {
        var keys = root.weak.map(function (k) { return k.key })
        if (keys.length === 0) keys = ["f", "j", "d", "k", "s", "l"]
        return Words.makeKeyDrill(keys, 220)
      }
    },
    {
      id: "slow", title: "Slow keys", hint: "Keys you press correctly but late. Tempo work.",
      build: function () {
        var keys = root.slow.map(function (k) { return k.key })
        if (keys.length === 0) keys = ["r", "t", "y", "u", "e", "i"]
        return Words.makeKeyDrill(keys, 220)
      }
    },
    {
      id: "bigrams", title: "Awkward pairs", hint: "Two-letter transitions that cost you accuracy.",
      build: function () {
        var list = root.pairs.map(function (b) { return b.pair })
        if (list.length === 0) list = ["th", "he", "in", "er", "an"]
        return Words.makeBigramDrill(list, 200)
      }
    },
    {
      id: "home", title: "Home row", hint: "A S D F G H J K L without leaving the anchors.",
      build: function () { return Words.wordsWith(["a", "s", "d", "f", "g", "h", "j", "k", "l"], 50) }
    },
    {
      id: "top", title: "Top row", hint: "Reach up from home for Q W E R T Y U I O P.",
      build: function () { return Words.wordsWith(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], 50) }
    },
    {
      id: "bottom", title: "Bottom row", hint: "Z X C V B N M, the row hands forget.",
      build: function () { return Words.wordsWith(["z", "x", "c", "v", "b", "n", "m"], 50) }
    },
    {
      id: "shift", title: "Shift control", hint: "Capitals with the opposite hand on shift.",
      build: function () { return Words.makeWords(40, { punctuation: true }) }
    },
    {
      id: "numbers", title: "Number row", hint: "Digits pressed without looking down.",
      build: function () {
        return Words.makeKeyDrill(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], 200)
      }
    },
    {
      id: "symbols", title: "Symbols", hint: "The punctuation that trips up code and prose.",
      build: function () {
        return Words.makeKeyDrill([";", "'", ",", ".", "/", "-", "=", "[", "]"], 200)
      }
    },
    {
      id: "punct", title: "Punctuated text", hint: "Real sentences with commas, quotes and stops.",
      build: function () { return Words.makeSentences(6) }
    },
    {
      id: "alternate", title: "Alternating hands", hint: "Left, right, left, right — the pattern under most fast words.",
      build: function () { return Words.makeAlternatingDrill(root.leftKeys, root.rightKeys, 200) }
    },
    {
      id: "rolls", title: "Same-hand rolls", hint: "Walk one finger group without leaving its row.",
      build: function () { return Words.makeRollDrill(root.rollGroups, 200) }
    },
    {
      id: "trigrams", title: "Common trigrams", hint: "The three-letter chunks that most English words are built from.",
      build: function () { return Words.makeTrigramDrill(Words.TRIGRAMS, 180) }
    }
  ]

  PageScroll {
    anchors.fill: parent

    // ------------------------------------------------------- diagnosis row

    Card {
      width: parent.width
      title: "What your typing says"
      hint: root.weak.length === 0
        ? "Not enough data yet. Finish a lesson or a test and this fills in."
        : "Lowest-accuracy keys from your profile. Tap one to drill it on its own."

      Flow {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.weak

          delegate: Chip {
            id: weakChip
            required property var modelData
            label: (weakChip.modelData.key === "space" ? "space" : weakChip.modelData.key) +
              "  " + Math.round(weakChip.modelData.acc) + "%"
            tint: Color.urgent
            onClicked: {
              var ch = weakChip.modelData.key === "space" ? " " : weakChip.modelData.key
              root.app.startDrill(
                Words.makeKeyDrill([ch], 200),
                "Key drill: " + (ch === " " ? "space" : ch),
                "One key, repeated until it stops being a decision."
              )
            }
          }
        }

        Text {
          visible: root.weak.length === 0
          text: "No weak keys measured yet"
          color: Util.alpha(Color.foreground, 0.54)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Flow {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.pairs

          delegate: Chip {
            id: pairChip
            required property var modelData
            label: pairChip.modelData.pair + "  " + Math.round(pairChip.modelData.acc) + "%"
            onClicked: root.app.startDrill(
              Words.makeBigramDrill([pairChip.modelData.pair], 180),
              "Pair drill: " + pairChip.modelData.pair,
              "Repeat the transition until the fingers stop negotiating."
            )
          }
        }
      }
    }

    // ------------------------------------------------------------ drill grid

    Flow {
      width: parent.width
      spacing: Style.space(10)

      Repeater {
        model: root.drills

        delegate: Card {
          id: drillCard
          required property var modelData
          width: (parent.width - Style.space(10)) / 2
          interactive: true
          title: drillCard.modelData.title
          hint: drillCard.modelData.hint

          Row {
            width: parent.width
            spacing: Style.space(6)

            TextButton {
              label: "Start drill"
              onClicked: root.app.startDrill(drillCard.modelData.build(), drillCard.modelData.title, drillCard.modelData.hint)
            }
          }

          onClicked: root.app.startDrill(drillCard.modelData.build(), drillCard.modelData.title, drillCard.modelData.hint)
        }
      }
    }

    // ------------------------------------------------------------ text packs

    Card {
      width: parent.width
      title: "Text packs"
      hint: "Real-world passages grouped by the kind of typing they ask for."

      Flow {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: Packs.list()

          delegate: Chip {
            id: packChip
            required property var modelData
            label: packChip.modelData.title
            onClicked: root.startPack(packChip.modelData.id)
          }
        }
      }
    }

    // --------------------------------------------------------- custom text

    Card {
      width: parent.width
      title: "Your own text"
      hint: "Paste anything — a paragraph you like, code, or a paragraph you have to type at work."

      Rectangle {
        width: parent.width
        height: Math.max(Style.space(70), input.implicitHeight + Style.space(16))
        radius: 0
        color: Util.alpha(Color.foreground, 0.04)
        border.width: 1
        border.color: Util.alpha(Color.foreground, input.activeFocus ? 0.28 : 0.12)

        TextInput {
          id: input
          anchors.fill: parent
          anchors.margins: Style.space(8)
          text: root.customText
          color: Color.foreground
          selectionColor: Util.alpha(Color.accent, 0.4)
          selectedTextColor: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          wrapMode: TextInput.Wrap
          selectByMouse: true
          clip: true
          onTextChanged: root.customText = text
          Keys.onReturnPressed: root.startCustom()
          Keys.onEnterPressed: root.startCustom()
          // Focus here bypasses the Academy's key catcher, so Escape has to be
          // handled locally or the overlay becomes unclosable from this box.
          Keys.onEscapePressed: root.app.dismiss()
        }

        Text {
          anchors.fill: parent
          anchors.margins: Style.space(8)
          visible: input.text.length === 0
          text: "Type or paste text here…"
          color: Util.alpha(Color.foreground, 0.48)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          wrapMode: Text.Wrap
        }
      }

      Item {
        width: parent.width
        height: Style.space(30)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.customText.length + " characters"
          color: Util.alpha(Color.foreground, 0.58)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        TextButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          label: "Practise this"
          primary: true
          enabledButton: root.customText.trim().length >= 10
          onClicked: root.startCustom()
        }
      }
    }
  }

  // Enter on this tab starts the first card — the weak-key drill, which is the
  // one an unattended learner should be doing. Same entry point the cards use.
  function startDefault() {
    var first = root.drills.length > 0 ? root.drills[0] : null
    if (!first) return false
    root.app.startDrill(first.build(), first.title, first.hint)
    return true
  }

  function startPack(id) {
    var pack = Packs.make(id)
    if (!pack) {
      root.app.toast("That pack is unavailable")
      return
    }
    root.app.startDrill(pack.text, "Pack: " + pack.title, pack.hint)
  }

  function startCustom() {
    var value = root.customText.trim()
    if (value.length < 10) {
      root.app.toast("Add at least ten characters to practise")
      return
    }
    root.app.startDrill(value, "Custom text", "Your own passage, taken one word at a time.")
  }
}
