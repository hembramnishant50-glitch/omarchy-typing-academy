import QtQuick
import qs.Commons
import "../components"
import "../Model.js" as Model

// Every knob in one page. All of it writes through `app.setSetting`, which
// clones the profile and saves, so nothing here holds local state that could
// drift from disk.
Item {
  id: root

  property var app

  readonly property var profile: app ? app.profile : null
  readonly property var settings: profile ? profile.settings : Model.defaultSettings()

  property bool confirmReset: false

  function set(key, value) {
    root.app.setSetting(key, value)
  }

  // The stored volume is a continuous 0..1 float, the chips are five fixed
  // stops. Snap to the nearest stop so a default of 0.32 highlights "25"
  // instead of matching nothing and leaving the row blank.
  function volumeId() {
    var value = Number(root.settings.volume)
    var best = root.volumeOptions[0]
    var bestDelta = Math.abs(value - Number(best.id))
    for (var i = 1; i < root.volumeOptions.length; i++) {
      var delta = Math.abs(value - Number(root.volumeOptions[i].id))
      if (delta < bestDelta) { best = root.volumeOptions[i]; bestDelta = delta }
    }
    return best.id
  }

  readonly property var caretOptions: [
    { id: "line", label: "Line" },
    { id: "block", label: "Block" },
    { id: "underline", label: "Underline" },
    { id: "off", label: "Off" }
  ]

  readonly property var fontOptions: [
    { id: "0.85", label: "S" },
    { id: "1", label: "M" },
    { id: "1.2", label: "L" },
    { id: "1.45", label: "XL" }
  ]

  readonly property var volumeOptions: [
    { id: "0", label: "0" },
    { id: "0.25", label: "25" },
    { id: "0.5", label: "50" },
    { id: "0.75", label: "75" },
    { id: "1", label: "100" }
  ]

  readonly property var testModeOptions: [
    { id: "time", label: "Time" },
    { id: "words", label: "Words" },
    { id: "quote", label: "Quote" },
    { id: "code", label: "Code" }
  ]

  PageScroll {
    anchors.fill: parent

    // ---------------------------------------------------------------- typing

    Card {
      width: parent.width
      title: "Typing"
      hint: "How the practice surface behaves while you type."

      SettingRow {
        label: "Strict mode"
        hint: "A wrong key is marked but does not advance. Slower, and it stops sloppy habits forming."

        Switch {
          checked: root.settings.strict
          onToggled: function (value) { root.set("strict", value) }
        }
      }

      SettingRow {
        label: "Show keyboard"
        hint: "The live QWERTY map under the passage, with the next key lit."

        Switch {
          checked: root.settings.showKeyboard
          onToggled: function (value) { root.set("showKeyboard", value) }
        }
      }

      SettingRow {
        label: "Text size"
        hint: "Applies to the passage you type."
        controlWidth: Style.space(210)

        Segmented {
          x: parent.width - width
          options: root.fontOptions
          value: String(root.settings.fontSize)
          onPicked: function (id) { root.set("fontSize", Number(id)) }
        }
      }

      // The passage is on another view, so changing the size used to look like
      // nothing happened. Show the exact size here, at the same scale the
      // practice surface uses.
      Rectangle {
        width: parent.width
        height: sizeSample.implicitHeight + Style.space(16)
        color: Util.alpha(Color.foreground, 0.02)
        border.width: 1
        border.color: Util.alpha(Color.foreground, 0.08)
        radius: 0

        Text {
          id: sizeSample
          anchors.centerIn: parent
          width: parent.width - Style.space(24)
          text: "The quick brown fox jumps over the lazy dog."
          color: Util.alpha(Color.foreground, 0.82)
          font.family: Style.font.family
          font.pixelSize: Math.round(Style.font.baseSize * 1.9 * Number(root.settings.fontSize))
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }
      }

      SettingRow {
        label: "Caret"
        hint: "Line is the quietest; block is easiest to find."
        controlWidth: Style.space(250)

        Segmented {
          x: parent.width - width
          options: root.caretOptions
          value: root.settings.caretStyle
          onPicked: function (id) { root.set("caretStyle", id) }
        }
      }

      SettingRow {
        label: "Blinking caret"
        hint: "Turn it off if the movement distracts you."

        Switch {
          checked: root.settings.caretBlink
          onToggled: function (value) { root.set("caretBlink", value) }
        }
      }
    }

    // -------------------------------------------------------------- feedback

    Card {
      width: parent.width
      title: "Feedback"
      hint: "Clicks on a correct key, a lower knock on a mistake."

      SettingRow {
        label: "Sound"
        hint: "Keystroke and error sounds while typing."

        Switch {
          checked: root.settings.sound
          onToggled: function (value) { root.set("sound", value) }
        }
      }

      SettingRow {
        label: "Volume"
        hint: "Independent of the system volume."
        controlWidth: Style.space(250)

        Segmented {
          x: parent.width - width
          options: root.volumeOptions
          value: root.volumeId()
          onPicked: function (id) { root.set("volume", Number(id)) }
        }
      }

      SettingRow {
        label: "Live speed"
        hint: "WPM in the header while you type. Some people find it motivating, some find it loud."

        Switch {
          checked: root.settings.liveWpm
          onToggled: function (value) { root.set("liveWpm", value) }
        }
      }

      SettingRow {
        label: "Live accuracy"
        hint: "Accuracy in the header while you type."

        Switch {
          checked: root.settings.liveAcc
          onToggled: function (value) { root.set("liveAcc", value) }
        }
      }
    }

    // -------------------------------------------------------------- defaults

    Card {
      width: parent.width
      title: "Test defaults"
      hint: "What the Speed Test tab starts with. You can still change it there per run."

      SettingRow {
        label: "Default mode"
        controlWidth: Style.space(250)

        Segmented {
          x: parent.width - width
          options: root.testModeOptions
          value: root.settings.testMode
          onPicked: function (id) { root.set("testMode", id) }
        }
      }

      SettingRow {
        label: "Punctuation"
        hint: "Include commas, quotes and capitals in generated tests and drills."

        Switch {
          checked: root.settings.punctuation
          onToggled: function (value) { root.set("punctuation", value) }
        }
      }

      SettingRow {
        label: "Numbers"
        hint: "Drop digits into generated text."

        Switch {
          checked: root.settings.numbers
          onToggled: function (value) { root.set("numbers", value) }
        }
      }
    }

    // ---------------------------------------------------------------- profile

    Card {
      width: parent.width
      title: "Your profile"
      hint: "Stored at ~/.local/share/omarchy/typing-academy/profile.json."

      Item {
        width: parent.width
        height: Style.space(20)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Level " + Model.levelInfo(root.profile ? root.profile.xp : 0).level +
                " · " + Model.formatCount(root.profile ? root.profile.counters.keys : 0) + " keys" +
                " · " + Model.formatDuration(root.profile ? root.profile.counters.seconds : 0) + " practised"
          color: Util.alpha(Color.foreground, 0.66)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Item {
        width: parent.width
        height: Style.space(32)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          TextButton {
            visible: !root.confirmReset
            label: "Reset all progress"
            danger: true
            onClicked: root.confirmReset = true
          }

          TextButton {
            visible: root.confirmReset
            label: "Yes, erase everything"
            danger: true
            onClicked: {
              root.confirmReset = false
              root.app.resetProgress()
            }
          }

          TextButton {
            visible: root.confirmReset
            label: "Cancel"
            onClicked: root.confirmReset = false
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: root.confirmReset
          text: "Lessons, tests, streaks, achievements."
          color: Util.alpha(Color.urgent, 0.72)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
