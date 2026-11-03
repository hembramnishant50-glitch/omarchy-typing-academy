import QtQuick
import qs.Commons
import "../components"
import "../Layout.js" as Layout
import "../Words.js" as Words
import "../Model.js" as Model
import "../ui"

// The hand map. A full keyboard coloured by measured accuracy, the finger
// legend underneath, and a one-tap route into a drill for any key.
Item {
  id: root

  property var app
  property bool heatmap: true
  property bool showFingers: true

  readonly property var profile: app ? app.profile : null
  readonly property var weak: profile ? Model.weakKeys(profile, 10) : []
  readonly property var slow: profile ? Model.slowKeys(profile, 6) : []

  function drillKey(ch) {
    var label = ch === " " ? "space" : ch
    root.app.startDrill(
      Words.makeKeyDrill([ch === " " ? " " : ch], 200),
      "Key drill: " + label,
      Layout.fingerName(Layout.fingerFor(ch)) + " · press it until it stops being a decision."
    )
  }

  PageScroll {
    anchors.fill: parent

    Card {
      width: parent.width
      title: "Keyboard map"
      hint: "Hot keys are the ones costing you accuracy. The stripe under each cap is the finger that owns it."

      ScreenKeyboard {
        width: parent.width
        nextKey: ""
        keyStats: root.profile ? root.profile.keys : ({})
        heatmap: root.heatmap
        showFingers: root.showFingers
        onKeyClicked: function (ch) { root.drillKey(ch) }
      }

      Item {
        width: parent.width
        height: Style.space(28)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          Chip {
            label: "heatmap"
            active: root.heatmap
            onClicked: root.heatmap = !root.heatmap
          }

          Chip {
            label: "finger hints"
            active: root.showFingers
            onClicked: root.showFingers = !root.showFingers
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "click any key to drill it"
          color: Util.alpha(Color.foreground, 0.54)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    // ------------------------------------------------------------- finger map

    Card {
      width: parent.width
      title: "Which finger owns what"
      hint: "Rest the index fingers on F and J — the two keys with the raised marks — and everything else follows."

      Flow {
        width: parent.width
        spacing: Style.space(8)

        Repeater {
          model: Layout.FINGERS

          delegate: Rectangle {
            id: fingerTile
            required property var modelData
            width: Math.max(Style.space(104), (parent.width - Style.space(32)) / 5)
            height: Style.space(34)
            radius: 0
            color: Util.alpha(Color.foreground, 0.03)
            border.width: 1
            border.color: Util.alpha(Color.foreground, 0.09)

            Rectangle {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(8)
              height: width
              radius: 0
              color: fingerTile.modelData.color
            }

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(24)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: fingerTile.modelData.name
              color: Util.alpha(Color.foreground, 0.72)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
        }
      }

      Text {
        width: parent.width
        text: "Left pinky: ` 1 Q A Z  ·  Left ring: 2 W S X  ·  Left middle: 3 E D C  ·  Left index: 4 5 R T F G V B\n" +
              "Right index: 6 7 Y U H J N M  ·  Right middle: 8 I K ,  ·  Right ring: 9 O L .  ·  Right pinky: 0 - = P [ ] \\ ; ' /  ·  Thumbs: space"
        color: Util.alpha(Color.foreground, 0.6)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        lineHeight: 1.4
      }
    }

    // ----------------------------------------------------------- problem keys

    Row {
      width: parent.width
      spacing: Style.space(10)

      Card {
        width: (parent.width - Style.space(10)) / 2
        title: "Least accurate"
        hint: "Measured across every lesson, drill and test."

        Repeater {
          model: root.weak

          delegate: Item {
            id: accRow
            required property var modelData
            width: parent.width
            height: Style.space(26)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(60)
              text: accRow.modelData.key === "space" ? "space" : accRow.modelData.key
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            Meter {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(58)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(52)
              anchors.verticalCenter: parent.verticalCenter
              thickness: Style.space(4)
              fill: accRow.modelData.acc < 92 ? Color.urgent : Color.accent
              value: accRow.modelData.acc / 100
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(accRow.modelData.acc) + "%"
              color: Util.alpha(Color.foreground, 0.74)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.drillKey(accRow.modelData.key === "space" ? " " : accRow.modelData.key)
            }
          }
        }

        Text {
          width: parent.width
          visible: root.weak.length === 0
          text: "Type a little and this list appears."
          color: Util.alpha(Color.foreground, 0.52)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Card {
        width: (parent.width - Style.space(10)) / 2
        title: "Slowest"
        hint: "Correct, but the hand hesitates. Drill these at an even tempo."

        Repeater {
          model: root.slow

          delegate: Item {
            id: slowRow
            required property var modelData
            width: parent.width
            height: Style.space(26)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(60)
              text: slowRow.modelData.key === "space" ? "space" : slowRow.modelData.key
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            Meter {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(58)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(72)
              anchors.verticalCenter: parent.verticalCenter
              thickness: Style.space(4)
              value: Util.clamp(slowRow.modelData.ms / 400, 0, 1)
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(slowRow.modelData.ms) + "ms"
              color: Util.alpha(Color.foreground, 0.74)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.drillKey(slowRow.modelData.key === "space" ? " " : slowRow.modelData.key)
            }
          }
        }

        Text {
          width: parent.width
          visible: root.slow.length === 0
          text: "Not enough samples yet."
          color: Util.alpha(Color.foreground, 0.52)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
