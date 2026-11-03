import QtQuick
import qs.Commons
import "../Layout.js" as Layout

// Visual QWERTY keyboard. Three jobs: show which finger owns which key, show
// where the next character is, and shade keys by measured accuracy.
//
// The grid is 15 units wide because that is the ANSI bottom row. Every row
// carries explicit key widths so the caps line up the way a real keyboard
// staggers, instead of pretending every key is square.
Item {
  id: root

  property string nextKey: ""
  property string pressed: ""
  property var keyStats: ({})
  property bool heatmap: true
  property bool showFingers: true
  property int gap: Math.max(2, Math.round(Style.space(4)))
  property int keyHeight: Math.max(26, Math.round(Style.space(38)))
  property int labelSize: Style.font.caption

  readonly property real unit: (width - gap * 14) / 15
  readonly property int rowCount: rows.length

  implicitWidth: 520
  implicitHeight: rowCount * keyHeight + (rowCount - 1) * gap

  signal keyClicked(string ch)

  // ---------------------------------------------------------------- geometry

  function makeCap(ch, w) {
    return { ch: ch, w: w || 1, decor: false, label: "" }
  }

  function decor(label, w) {
    return { ch: "", w: w || 1, decor: true, label: label }
  }

  // Layout.ROWS carries {ch, finger} records, so each key has to be re-wrapped
  // as a cap before the row can be measured. Concatenating the records
  // straight in leaves `w` undefined and the whole row collapses.
  function caps(keys) {
    var out = []
    for (var i = 0; i < keys.length; i++) out.push(makeCap(keys[i].ch, 1))
    return out
  }

  function buildRows() {
    var r = Layout.ROWS
    return [
      caps(r[0].keys).concat([decor("⌫", 2)]),
      [decor("tab", 1.5)].concat(caps(r[1].keys.slice(0, 12))).concat([makeCap("\\", 1.5)]),
      [decor("caps", 1.75)].concat(caps(r[2].keys)).concat([decor("enter", 2.25)]),
      [decor("shift", 2.25)].concat(caps(r[3].keys)).concat([decor("shift", 2.75)]),
      [
        decor("ctrl", 1.5), decor("alt", 1.5), decor("cmd", 1.5),
        makeCap(" ", 6),
        decor("alt", 1.5), decor("cmd", 1.5), decor("ctrl", 1.5)
      ]
    ]
  }

  property var rows: buildRows()

  function keyWidth(units) {
    return units * unit + (units - 1) * gap
  }

  // ---------------------------------------------------------------- per-key

  function normalised(ch) {
    if (ch === " ") return "space"
    return String(ch).toLowerCase()
  }

  function isNext(ch) {
    if (!nextKey || ch === "") return false
    return Layout.baseKey(ch) === Layout.baseKey(nextKey)
  }

  function shiftWanted() {
    return nextKey.length === 1 && Layout.needsShift(nextKey)
  }

  function statsFor(ch) {
    var all = root.keyStats || {}
    return all[root.normalised(ch)] || null
  }

  function accuracyFor(ch) {
    var e = statsFor(ch)
    if (!e) return -1
    var total = (Number(e.hits) || 0) + (Number(e.misses) || 0)
    if (total < 3) return -1
    return (Number(e.hits) || 0) / total
  }

  function heatTint(ch) {
    if (!root.heatmap) return ""
    var acc = accuracyFor(ch)
    if (acc < 0) return ""
    if (acc >= 0.985) return Util.alpha(Color.foreground, 0.06)
    var severity = Util.clamp((1 - acc) * 3.2, 0.05, 1)
    return Util.alpha(Color.urgent, 0.08 + severity * 0.42)
  }

  function fingerTint(ch) {
    var id = Layout.fingerFor(ch)
    if (!id) return Color.foreground
    return Layout.fingerColor(id)
  }

  // ------------------------------------------------------------------ render

  Column {
    anchors.fill: parent
    spacing: root.gap

    Repeater {
      model: root.rows

      delegate: Row {
        id: keyRow
        required property var modelData
        spacing: root.gap
        x: Math.max(0, (root.width - width) / 2)

        Repeater {
          model: keyRow.modelData

          delegate: Rectangle {
            id: keyCap
            required property var modelData

            readonly property bool isDecor: keyCap.modelData.decor === true
            readonly property string ch: keyCap.modelData.ch
            readonly property bool target: !keyCap.isDecor && root.isNext(keyCap.ch)
            readonly property bool shiftTarget: keyCap.isDecor && keyCap.modelData.label === "shift" && root.shiftWanted()
            readonly property bool hot: !keyCap.isDecor && root.pressed !== "" && root.normalised(root.pressed) === root.normalised(keyCap.ch)
            readonly property string heat: keyCap.isDecor ? "" : root.heatTint(keyCap.ch)
            readonly property bool wide: keyCap.modelData.w > 1.4

            width: root.keyWidth(keyCap.modelData.w)
            height: root.keyHeight
            radius: 0

            color: {
              if (keyCap.hot) return Util.alpha(Color.accent, 0.42)
              if (keyCap.target || keyCap.shiftTarget) return Util.alpha(Color.accent, 0.24)
              if (keyCap.heat !== "") return keyCap.heat
              return Util.alpha(Color.foreground, hover.hovered && !keyCap.isDecor ? 0.09 : 0.035)
            }

            border.width: 1
            border.color: {
              if (keyCap.target || keyCap.shiftTarget) return Util.alpha(Color.accent, 0.75)
              if (keyCap.hot) return Util.alpha(Color.accent, 0.9)
              return Util.alpha(Color.foreground, 0.10)
            }

            Behavior on color { ColorAnimation { duration: 90 } }

            // Finger stripe along the bottom edge: the whole point of the
            // visualiser is that the hand map is readable at a glance.
            Rectangle {
              visible: root.showFingers && !keyCap.isDecor
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: Style.space(3)
              height: 2
              radius: 0
              color: Util.alpha(root.fingerTint(keyCap.ch), keyCap.ch === " " ? 0.5 : 0.75)
            }

            // Shifted glyph, printed above the unshifted one like a real keycap.
            Text {
              visible: !keyCap.isDecor && Layout.altLabel(keyCap.ch).length > 0
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.leftMargin: Style.space(5)
              anchors.topMargin: Style.space(3)
              text: Layout.altLabel(keyCap.ch)
              color: Util.alpha(Color.foreground, 0.56)
              font.family: Style.font.family
              font.pixelSize: Math.max(8, root.labelSize - 2)
            }

            Text {
              anchors.centerIn: parent
              text: keyCap.isDecor ? keyCap.modelData.label : Layout.capLabel(keyCap.ch)
              color: keyCap.isDecor
                ? Util.alpha(Color.foreground, 0.30)
                : Util.alpha(Color.foreground, keyCap.target ? 0.98 : 0.72)
              font.family: Style.font.family
              font.pixelSize: keyCap.isDecor
                ? Math.max(9, root.labelSize - 1)
                : (keyCap.wide ? Math.round(root.labelSize * 0.9) : root.labelSize)
              font.letterSpacing: keyCap.isDecor ? 0.6 : 0
            }

            // The tactile bump on F and J.
            Rectangle {
              visible: !keyCap.isDecor && Layout.isHomeAnchor(keyCap.ch)
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(7)
              width: Style.space(10)
              height: 2
              radius: 0
              color: Util.alpha(Color.foreground, 0.66)
            }

            // Error count badge, only in heatmap mode where it adds signal.
            Rectangle {
              visible: root.heatmap && !keyCap.isDecor && root.accuracyFor(keyCap.ch) >= 0 && root.accuracyFor(keyCap.ch) < 0.985
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(3)
              width: Style.space(12)
              height: width
              radius: 0
              color: Util.alpha(Color.urgent, 0.22)
            }

            HoverHandler { id: hover }

            MouseArea {
              anchors.fill: parent
              enabled: !keyCap.isDecor && keyCap.ch !== ""
              cursorShape: keyCap.isDecor ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: root.keyClicked(keyCap.ch)
            }
          }
        }
      }
    }
  }
}
