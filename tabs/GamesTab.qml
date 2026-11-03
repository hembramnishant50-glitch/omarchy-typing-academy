import QtQuick
import qs.Commons
import "../components"
import "../ui"

// Game launcher. The board itself lives in ui/GameBoard.qml; this tab only
// picks the mode, hands the board the keyboard, and files the score.
//
// Key routing is the reason this tab exists at all: while it is on screen the
// Academy root sends raw key events to `app.keySink` before it looks at tab
// shortcuts, so a game can own Space, Backspace and every letter.
Item {
  id: root

  property var app

  readonly property var profile: app ? app.profile : null
  readonly property var games: profile ? profile.games : ({})

  readonly property var modes: [
    {
      id: "falling", title: "Falling words",
      hint: "Words drop toward the floor. Type one to clear it. Three misses end the run."
    },
    {
      id: "sprint", title: "Word sprint",
      hint: "One word at a time, as fast as you can, for forty-five seconds."
    },
    {
      id: "hunt", title: "Key hunt",
      hint: "A letter appears. Find it without looking down. It gets harder."
    },
    {
      id: "burst", title: "Speed burst",
      hint: "One letter at a time, as fast as you can, for fifteen seconds."
    },
    {
      id: "gauntlet", title: "Accuracy gauntlet",
      hint: "Words come one at a time. One wrong key ends the run. No clock."
    },
    {
      id: "mirror", title: "Pattern mirror",
      hint: "A sequence flashes. Type it back. Each round adds one more letter."
    }
  ]

  readonly property string mode: app ? app.gameMode : "falling"

  function bestFor(id) {
    var g = root.games ? root.games[id] : null
    if (!g) return 0
    return Math.round(Number(g.best) || 0)
  }

  function playsFor(id) {
    var g = root.games ? root.games[id] : null
    return g ? Math.round(Number(g.plays) || 0) : 0
  }

  function choose(id) {
    if (root.mode === id) return
    root.app.gameMode = id
    board.reset()
    board.mode = id
  }

  PageScroll {
    anchors.fill: parent

    // --------------------------------------------------------------- picker

    Card {
      width: parent.width
      title: "Games"
      hint: "Practice that does not feel like practice. Every game feeds the same key statistics as a lesson, so weak keys keep improving no matter what you play."

      Flow {
        width: parent.width
        spacing: Style.space(8)

        Repeater {
          model: root.modes

          delegate: Chip {
            id: modeChip
            required property var modelData
            label: modeChip.modelData.title
            active: root.mode === modeChip.modelData.id
            onClicked: root.choose(modeChip.modelData.id)
          }
        }
      }
    }

    // ---------------------------------------------------------------- board

    Card {
      width: parent.width
      padding: Style.space(10)

      Item {
        width: parent.width
        height: Math.max(Style.space(300), Math.min(Style.space(420), root.height * 0.46))

        GameBoard {
          id: board
          anchors.fill: parent
          mode: root.mode
          app: root.app
          onGameOver: function (result) {
            root.app.recordGame(root.mode, result)
          }
        }
      }

      Item {
        width: parent.width
        height: Style.space(30)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          TextButton {
            label: board.running ? "Restart" : "Start"
            primary: !board.running
            onClicked: board.start()
          }

          TextButton {
            visible: board.running
            label: "Stop"
            onClicked: board.finish()
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: board.running
            ? "esc ends the run"
            : "press space on the board to play"
          color: Util.alpha(Color.foreground, 0.54)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    // ---------------------------------------------------------------- bests

    Row {
      width: parent.width
      spacing: Style.space(10)

      Repeater {
        model: root.modes

        delegate: Card {
          id: bestCard
          required property var modelData
          width: (parent.width - Style.space(20)) / 3

          Stat {
            value: String(root.bestFor(bestCard.modelData.id))
            unit: "pts"
            label: bestCard.modelData.title + " best"
            valueSize: Style.font.heading
          }

          Text {
            width: parent.width
            text: {
              var played = root.playsFor(bestCard.modelData.id)
              return played === 1 ? "1 play" : played + " plays"
            }
            color: Util.alpha(Color.foreground, 0.58)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }

  // Hand the keyboard to the board while this tab is alive, and take it back
  // when the tab is replaced. The identity check keeps a late teardown from
  // clearing a sink that a newer tab has already claimed.
  Component.onCompleted: {
    board.mode = root.mode
    if (root.app) root.app.keySink = board
  }

  Component.onDestruction: {
    if (root.app && root.app.keySink === board) root.app.keySink = null
  }
}
