import QtQuick
import qs.Commons

// Renders the passage as a wrapping Flow of word rows, each word a Row of
// single-character cells. Every cell owns its own caret test, which keeps the
// caret trivial: it is just the cell whose index equals the cursor.
//
// Two rules learned the hard way in the sibling typing plugin:
//   1. A Repeater delegate must name itself with an `id`; never reach through
//      `parent.modelData`, because `parent` is the container, not the delegate.
//   2. Anything that mutates a sibling from inside a binding becomes a loop.
//      Scrolling is therefore imperative (`ensureVisible`) and publishes a
//      plain number that the Flow's y binds to.
Item {
  id: root

  property string text: ""
  property var states: []
  property int cursor: 0
  property bool caretEnabled: true
  property bool caretBlink: true
  property string caretStyle: "line"

  property int fontSize: Math.round(Style.font.baseSize * 1.9)
  property int lineHeight: Math.round(fontSize * 1.8)
  property int visibleLines: 3
  property int caretThickness: Math.max(2, Math.round(fontSize * 0.09))

  property var words: []
  property real scrollTarget: 0
  property bool caretVisible: true

  readonly property int lineGap: Style.space(2)

  // Height the wrapped passage actually needs. Owners use it to shrink the
  // view to short drills instead of always reserving `visibleLines` rows.
  readonly property real contentHeight: flow.implicitHeight

  implicitHeight: lineHeight * visibleLines + lineGap * (visibleLines - 1)
  implicitWidth: 320
  clip: true

  onTextChanged: rebuild()
  onCursorChanged: ensureVisible()
  onWidthChanged: Qt.callLater(ensureVisible)
  onHeightChanged: Qt.callLater(ensureVisible)

  Timer {
    id: blink
    interval: 560
    repeat: true
    running: root.caretEnabled && root.caretBlink && root.caretStyle !== "off"
    onTriggered: root.caretVisible = !root.caretVisible
  }

  Connections {
    target: root
    function onCursorChanged() { root.caretVisible = true; blink.restart() }
  }

  function rebuild() {
    words = splitWords(text)
    scrollTarget = 0
    caretVisible = true
    Qt.callLater(ensureVisible)
  }

  // A "word" is a run of non-space characters plus its trailing space. Keeping
  // the space inside the row means the Flow can only break between words, so a
  // line never starts with an orphaned space.
  function splitWords(value) {
    var out = []
    var n = value.length
    var i = 0
    var k = 0
    while (i < n) {
      var start = i
      var chars = []
      while (i < n && value.charAt(i) !== " ") {
        chars.push({ ch: value.charAt(i), idx: i })
        i += 1
      }
      if (i < n) {
        chars.push({ ch: " ", idx: i })
        i += 1
      }
      out.push({ key: "w" + k, start: start, end: i, chars: chars })
      k += 1
    }
    if (out.length > 0) {
      var last = out[out.length - 1]
      out[out.length - 1] = {
        key: last.key,
        start: last.start,
        end: last.end,
        chars: last.chars.concat([{ ch: "", idx: n, sentinel: true }])
      }
    }
    return out
  }

  function wordIndexForCursor() {
    var list = words
    for (var i = 0; i < list.length; i++) {
      if (cursor < list[i].end) return i
    }
    return Math.max(0, list.length - 1)
  }

  function ensureVisible() {
    if (!wordRepeater || wordRepeater.count === 0) return
    var item = wordRepeater.itemAt(wordIndexForCursor())
    if (!item) return

    var viewH = height
    if (viewH <= 0) return

    var top = item.y
    var bottom = item.y + item.height
    var current = scrollTarget
    var target = current

    if (bottom > current + viewH - root.lineGap) target = bottom - viewH + root.lineGap
    if (top < target) target = top
    if (target < 0) target = 0

    if (Math.abs(target - current) > 0.5) scrollTarget = target
  }

  Flow {
    id: flow
    x: 0
    y: -root.scrollTarget
    width: root.width
    spacing: 0

    Behavior on y { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

    Repeater {
      id: wordRepeater
      model: root.words

      delegate: Row {
        id: wordRow
        required property var modelData
        spacing: 0

        Repeater {
          model: wordRow.modelData.chars

          delegate: Item {
            id: cell
            required property var modelData

            readonly property int mark: root.states[cell.modelData.idx] || 0
            readonly property bool isCursor: cell.modelData.idx === root.cursor

            width: glyph.implicitWidth
            height: root.lineHeight

            Text {
              id: glyph
              anchors.verticalCenter: parent.verticalCenter
              text: cell.modelData.ch === " " ? "\u00A0"
                : (cell.modelData.sentinel ? "" : cell.modelData.ch)
              font.family: Style.font.family
              font.pixelSize: root.fontSize
              color: {
                if (cell.mark === 1) return Color.foreground
                if (cell.mark === 2) return Color.urgent
                if (cell.isCursor) return Util.alpha(Color.foreground, 0.96)
                return Util.alpha(Color.foreground, 0.32)
              }
            }

            Rectangle {
              visible: cell.mark === 2
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(3)
              height: Math.max(1, Math.round(root.fontSize * 0.055))
              color: Util.alpha(Color.urgent, 0.8)
            }

            Rectangle {
              id: caret
              visible: cell.isCursor && root.caretVisible && root.caretEnabled && root.caretStyle !== "off"

              readonly property bool block: root.caretStyle === "block"
              readonly property bool underline: root.caretStyle === "underline"

              anchors.left: parent.left
              width: caret.block || caret.underline ? cell.width : root.caretThickness
              height: caret.underline
                ? Math.max(1, Math.round(root.fontSize * 0.06))
                : root.lineHeight - Style.space(9)
              y: caret.underline
                ? parent.height - height - Style.space(3)
                : Style.space(4)
              radius: 0
              color: caret.block ? Util.alpha(Color.accent, 0.22) : Color.accent
            }
          }
        }
      }
    }
  }
}
