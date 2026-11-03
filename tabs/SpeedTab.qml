import QtQuick
import qs.Commons
import "../components"
import "../Code.js" as Code
import "../Model.js" as Model

// Speed test configuration plus the run history. The run itself happens in
// the shared PracticeView, so this tab never owns a timer or a cursor.
Item {
  id: root

  property var app

  readonly property var profile: app ? app.profile : null
  readonly property var settings: profile ? profile.settings : Model.defaultSettings()
  readonly property var history: profile ? Model.recentTests(profile, 20) : []
  readonly property int testCount: profile ? profile.tests.length : 0
  // A best can be set by any lesson, drill or test, so it only means something
  // once the user has actually typed a run.
  readonly property int runs: profile
    ? profile.counters.lessons + profile.counters.drills + profile.counters.tests
    : 0

  readonly property var modeOptions: [
    { id: "time", label: "Time" },
    { id: "words", label: "Words" },
    { id: "quote", label: "Quote" },
    { id: "code", label: "Code" }
  ]

  readonly property var amounts: {
    if (settings.testMode === "code") return Code.LANGUAGES
    if (settings.testMode === "time") {
      return [
        { id: "15", label: "15s" }, { id: "30", label: "30s" },
        { id: "60", label: "60s" }, { id: "120", label: "120s" }
      ]
    }
    if (settings.testMode === "words") {
      return [
        { id: "10", label: "10" }, { id: "25", label: "25" },
        { id: "50", label: "50" }, { id: "100", label: "100" }
      ]
    }
    return [
      { id: "short", label: "Short" },
      { id: "medium", label: "Medium" },
      { id: "long", label: "Long" }
    ]
  }

  function amountId() {
    if (settings.testMode === "code") return settings.codeLang
    if (settings.testMode === "quote") return settings.quoteLength
    return String(settings.testAmount)
  }

  function pickAmount(id) {
    if (settings.testMode === "code") root.app.setSetting("codeLang", id)
    else if (settings.testMode === "quote") root.app.setSetting("quoteLength", id)
    else root.app.setSetting("testAmount", Number(id))
  }

  PageScroll {
    anchors.fill: parent

    // ------------------------------------------------------------- launcher

    Card {
      width: parent.width
      title: "Speed test"
      hint: "A clean measurement: no lesson targets, no hand-holding. Raw speed and accuracy over the whole run."

      SettingRow {
        label: "Mode"
        hint: "Timed runs end on the clock. Every other mode ends at the last character."
        controlWidth: Style.space(250)

        Segmented {
          x: parent.width - width
          options: root.modeOptions
          value: root.settings.testMode
          onPicked: function (id) { root.app.setSetting("testMode", id) }
        }
      }

      SettingRow {
        label: settings.testMode === "code"
          ? "Language"
          : settings.testMode === "quote"
            ? "Quote length"
            : (settings.testMode === "time" ? "Duration" : "Word count")
        controlWidth: Style.space(settings.testMode === "code" ? 320 : 250)

        Segmented {
          x: parent.width - width
          options: root.amounts
          value: root.amountId()
          onPicked: function (id) { root.pickAmount(id) }
        }
      }

      Item {
        width: parent.width
        height: Style.space(36)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          Chip {
            label: "punctuation"
            visible: root.settings.testMode !== "code"
            active: root.settings.punctuation
            onClicked: root.app.setSetting("punctuation", !root.settings.punctuation)
          }

          Chip {
            label: "numbers"
            visible: root.settings.testMode !== "code"
            active: root.settings.numbers
            onClicked: root.app.setSetting("numbers", !root.settings.numbers)
          }

          Chip {
            label: "strict"
            active: root.settings.strict
            onClicked: root.app.setSetting("strict", !root.settings.strict)
          }
        }

        TextButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          label: "Start test"
          primary: true
          onClicked: root.app.startTest()
        }
      }
    }

    // ---------------------------------------------------------------- bests

    Row {
      width: parent.width
      spacing: Style.space(10)

      Card {
        width: (parent.width - Style.space(20)) / 3
        Stat {
          value: root.runs > 0 ? String(Math.round(root.profile ? root.profile.best.wpm : 0)) : "—"
          unit: root.runs > 0 ? "wpm" : ""
          label: "personal best"
          valueSize: Style.font.heading
        }
      }

      Card {
        width: (parent.width - Style.space(20)) / 3
        Stat {
          value: root.runs > 0 ? String(Math.round(root.profile ? root.profile.best.acc : 0)) + "%" : "—"
          unit: ""
          label: "best accuracy"
          valueSize: Style.font.heading
        }
      }

      Card {
        width: (parent.width - Style.space(20)) / 3
        Stat {
          value: root.testCount > 0
            ? String(Math.round(Model.averageWpm(root.profile || Model.emptyProfile(), 10)))
            : "—"
          unit: root.testCount > 0 ? "wpm" : ""
          label: root.testCount > 0 ? "recent average" : "no tests yet"
          valueSize: Style.font.heading
        }
      }
    }

    // --------------------------------------------------------------- history

    Card {
      width: parent.width
      title: root.history.length === 0
        ? "Test history"
        : root.history.length === 1 ? "Last run" : "Last " + root.history.length + " runs"
      hint: "WPM per test, oldest on the left. A rising line with flat accuracy is the shape you want."

      LineChart {
        width: parent.width
        height: Style.space(120)
        values: root.history.map(function (t) { return t.wpm })
      }

      Item {
        width: parent.width
        height: Style.space(18)

        Text {
          anchors.left: parent.left
          text: root.history.length === 0
            ? "no runs recorded"
            : root.history.length === 1
              ? "one run so far — the next one sets the trend"
              : "trend " + (Model.trend(root.profile, 10) >= 0 ? "+" : "") + Model.trend(root.profile, 10).toFixed(1) + " wpm"
          color: Util.alpha(Color.foreground, 0.64)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.right: parent.right
          text: root.history.length > 0 ? "showing " + root.history.length + " of " + root.profile.tests.length : ""
          color: Util.alpha(Color.foreground, 0.52)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Repeater {
        model: root.history.slice().reverse().slice(0, 8)

        delegate: Item {
          id: runRow
          required property var modelData
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(96)
            text: runRow.modelData.mode === "code"
              ? "code"
              : runRow.modelData.mode + " " + Math.round(runRow.modelData.amount)
            color: Util.alpha(Color.foreground, 0.74)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(104)
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(runRow.modelData.wpm) + " wpm"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(runRow.modelData.acc) + "%  ·  " +
              Math.round(runRow.modelData.seconds) + "s  ·  steady " +
              Math.round(runRow.modelData.consistency) + "%"
            color: Util.alpha(Color.foreground, 0.64)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Util.alpha(Color.foreground, 0.05)
          }
        }
      }
    }
  }
}
