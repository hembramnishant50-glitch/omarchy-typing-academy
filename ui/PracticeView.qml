import QtQuick
import qs.Commons
import "../components"
import "../Model.js" as Model

// The one place typing actually happens. Lessons, drills and tests all hand
// this component a passage and a policy; it owns nothing but the run.
//
// Deliberately does not take the Academy root as a property. Everything it
// needs is an explicit prop, so it can be dropped into a harness on its own.
Item {
  id: root

  property string title: ""
  property string subtitle: ""
  property string text: ""
  property string mode: "lesson"

  property bool strict: false
  property int timeLimit: 0
  property int targetWpm: 0
  property int targetAcc: 0

  property bool showKeyboard: true
  property bool showLiveWpm: true
  property bool showLiveAcc: true
  property bool caretBlink: true
  property string caretStyle: "line"
  property real fontScale: 1

  property string nextLabel: ""
  property bool showBack: false
  property string backLabel: "Back"

  property var keyStats: ({})

  property var result: null

  readonly property var engine: core
  readonly property bool running: core.started && !core.finished && core.cursor > 0
  readonly property int remaining: timeLimit > 0
    ? Math.max(0, Math.ceil(timeLimit - core.elapsed))
    : 0

  // What this run says about the next run. Derived from the result rather than
  // the profile so the card is honest about the run you just finished.
  readonly property var worstKeys: result ? Model.keysFromLog(result.keyLog, 5) : []
  readonly property var typoPairs: result ? Model.topTyposFromLog(result.typoLog, 3) : []
  readonly property var runCurve: (result && result.curve) ? result.curve : []

  signal finished(var outcome)
  signal keystroke(bool ok, string ch)
  signal nextRequested()
  signal backRequested()
  signal keyDrillRequested(string key)

  // PracticeView never takes focus itself. The Academy keeps a full-window
  // catcher focused for keys; stealing activeFocus from it silences typing, so
  // this asks the owner to put focus back where events are read.
  signal focusRequested()

  onTextChanged: core.load(text)
  Component.onCompleted: if (text.length > 0) core.load(text)

  function restart() {
    result = null
    core.restart()
  }

  function focusTyping() {
    root.focusRequested()
  }

  function press(ch) {
    core.press(ch)
  }

  function backspace() {
    core.backspace()
  }

  TypingEngine {
    id: core
    strict: root.strict
    timeLimit: root.timeLimit
    onPressed: function (ok, expected) { root.keystroke(ok, expected) }
    onCompleted: function (outcome) {
      root.result = outcome
      root.finished(outcome)
    }
  }

  // ------------------------------------------------------------------ header

  Column {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.space(1)

    Item {
      width: parent.width
      height: Math.max(titleBlock.implicitHeight, liveStats.height)

      Column {
        id: titleBlock
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          text: root.title
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.letterSpacing: -0.2
        }

        Text {
          text: root.subtitle
          visible: root.subtitle.length > 0
          color: Util.alpha(Color.foreground, 0.64)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Row {
        id: liveStats
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(18)

        Stat {
          // Before the first key a timed run has its whole clock ahead of it,
          // so showing "0 s left" makes the test look already over.
          value: root.timeLimit > 0
            ? String(core.started || core.finished ? root.remaining : root.timeLimit)
            : (core.started ? String(Math.round(core.elapsed)) : "0")
          unit: "s"
          label: root.timeLimit > 0 ? "left" : "time"
          valueSize: Style.font.title
          tint: root.timeLimit > 0 && root.remaining <= 5 && core.started && !core.finished
            ? Color.urgent
            : Color.foreground
        }

        Stat {
          visible: root.showLiveWpm
          value: String(Math.round(core.started ? core.liveWpm : 0))
          unit: "wpm"
          label: root.targetWpm > 0 ? "target " + root.targetWpm : "speed"
          valueSize: Style.font.title
        }

        Stat {
          visible: root.showLiveAcc
          value: String(Math.round(core.started ? core.liveAcc : 100))
          unit: "%"
          label: root.targetAcc > 0 ? "target " + root.targetAcc : "accuracy"
          valueSize: Style.font.title
          tint: core.started && core.liveAcc < 90 ? Color.urgent : Color.foreground
        }

        Stat {
          value: String(Math.round(core.consistency))
          unit: "%"
          label: "consistency"
          valueSize: Style.font.title
          tint: Util.alpha(Color.foreground, 0.72)
        }
      }
    }

    Item {
      width: parent.width
      height: Style.space(8)

      Meter {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        thickness: Style.space(3)
        value: root.timeLimit > 0
          ? Util.clamp(core.elapsed / Math.max(1, root.timeLimit), 0, 1)
          : core.progress
        fill: root.timeLimit > 0 && root.remaining <= 5 && core.started ? Color.urgent : Color.accent
      }
    }
  }

  // -------------------------------------------------------------- typing area

  Item {
    id: typingArea
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: header.bottom
    anchors.topMargin: Style.space(18)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(20)

    // Passage, prompt and keys are one centred stack. Centring the halves
    // separately would strand the passage at the top of a tall empty band.
    Column {
      id: practiceStack
      width: parent.width
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(28)

      Column {
        id: typingBlock
        width: parent.width
        spacing: Style.space(10)

        // Dimmed rather than hidden so the finished passage stays legible as
        // context behind the result card.
        opacity: root.result ? 0.18 : 1

        Behavior on opacity { NumberAnimation { duration: 160 } }

        TypingView {
          id: view
          width: parent.width

          // Shrink to the real passage, capped at the scroll window. A fixed
          // four-line box leaves short drills floating with a hole under them.
          height: Math.min(implicitHeight, Math.max(lineHeight, contentHeight))

          text: root.text
          states: core.states
          cursor: core.cursor
          caretEnabled: !core.finished
          caretBlink: root.caretBlink
          caretStyle: root.caretStyle
          fontSize: Math.round(Style.font.baseSize * 1.9 * root.fontScale)
          visibleLines: 4
        }

        // Prompt shown before the first keystroke so the surface does not look
        // broken or inert while waiting. It fades instead of disappearing: a
        // Column would reclaim its height and bounce the passage upward.
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.strict ? "Strict mode — wrong keys will not advance" : "Start typing when you are ready"
          color: Util.alpha(Color.foreground, 0.56)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          opacity: !core.started && !core.finished && root.text.length > 0 ? 1 : 0

          Behavior on opacity { NumberAnimation { duration: 140 } }
        }
      }

      ScreenKeyboard {
        id: keyboard
        // Capped and centred: stretching the board across the whole sheet
        // turns every key into a wide slab and dwarfs the passage.
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, Style.space(760))
        visible: root.showKeyboard
        height: visible ? implicitHeight : 0
        nextKey: core.nextChar
        pressed: ""
        keyStats: root.keyStats
        heatmap: false
        showFingers: true
        keyHeight: Math.max(24, Math.round(Style.space(34)))
        labelSize: Style.font.caption
      }
    }

    // ------------------------------------------------------------- result card

    Rectangle {
      id: resultCard
      anchors.centerIn: parent
      width: Math.min(parent.width - Style.space(40), Style.space(520))
      height: resultBody.implicitHeight + Style.space(36)
      visible: root.result !== null
      radius: 0
      color: Util.alpha(Color.background, 0.97)
      border.width: 1
      border.color: Util.alpha(Color.foreground, 0.16)

      Column {
        id: resultBody
        anchors.centerIn: parent
        width: parent.width - Style.space(40)
        spacing: Style.space(12)

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.resultHeader(root.result)
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(26)

          Column {
            spacing: Style.space(1)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.result ? String(Math.round(root.result.wpm)) : "0"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              font.letterSpacing: -1
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "wpm"
              color: Util.alpha(Color.foreground, 0.66)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            spacing: Style.space(1)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.result ? String(Math.round(root.result.acc)) + "%" : "—"
              color: root.result && root.result.acc < 95 ? Color.urgent : Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "accuracy"
              color: Util.alpha(Color.foreground, 0.66)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            spacing: Style.space(1)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.result ? String(Math.round(root.result.raw)) : "—"
              color: Util.alpha(Color.foreground, 0.86)
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "raw"
              color: Util.alpha(Color.foreground, 0.66)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            spacing: Style.space(1)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.result ? String(Math.round(root.result.consistency)) + "%" : "—"
              color: Util.alpha(Color.foreground, 0.86)
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "steady"
              color: Util.alpha(Color.foreground, 0.66)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.result && root.result.errors > 0
            ? root.result.errors + " mistake" + (root.result.errors === 1 ? "" : "s") + " in " + Math.round(root.result.seconds) + "s"
            : "clean run in " + (root.result ? Math.round(root.result.seconds) : 0) + "s"
          color: Util.alpha(Color.foreground, 0.68)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        // This run's pace, second by second. One point is a dot, not a curve,
        // so it only appears once there is a shape worth reading.
        LineChart {
          width: parent.width
          height: Style.space(64)
          visible: root.runCurve.length > 1
          values: root.runCurve
          lineColor: Color.accent
          showArea: true
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.worstKeys.length > 0

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "What to fix"
            color: Util.alpha(Color.foreground, 0.66)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 0.4
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: root.typoHint()
            color: Util.alpha(Color.foreground, 0.54)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(6)

            Repeater {
              model: root.worstKeys

              delegate: TextButton {
                id: keyChip
                required property var modelData
                label: keyChip.modelData === " " ? "space" : keyChip.modelData
                fontSize: Style.font.caption
                horizontalPadding: Style.space(10)
                onClicked: root.keyDrillRequested(keyChip.modelData)
              }
            }
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(8)

          TextButton {
            visible: root.showBack
            label: root.backLabel
            onClicked: root.backRequested()
          }

          TextButton {
            label: "Again"
            onClicked: root.restart()
          }

          TextButton {
            visible: root.nextLabel.length > 0
            label: root.nextLabel
            primary: true
            onClicked: root.nextRequested()
          }
        }
      }
    }
  }

  function resultHeader(outcome) {
    if (!outcome) return ""
    if (root.mode === "test") return "Test complete"
    if (outcome.acc >= 100) return "Flawless"
    if (outcome.acc >= 97) return "Clean run"
    if (outcome.acc >= 90) return "Solid"
    return "Keep going"
  }

  // One line naming the confusions, so the chips below read as a consequence
  // instead of a mystery. "pressed r for t" is the direction of the mistake.
  function typoHint() {
    var pairs = root.typoPairs
    if (!pairs || pairs.length === 0) return ""
    var parts = []
    for (var i = 0; i < pairs.length; i++) {
      var p = pairs[i]
      var want = p.want === " " ? "space" : p.want
      var got = p.got === " " ? "space" : p.got
      if (!got) parts.push("missed " + want)
      else parts.push(got + " for " + want)
    }
    return "pressed " + parts.join(" · ")
  }
}
