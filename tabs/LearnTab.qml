import QtQuick
import qs.Commons
import "../components"
import "../Lessons.js" as Lessons

// Curriculum browser. One card per stage, each lesson a tile with its star
// rating. Nothing here types — it only calls back into the Academy root.
Item {
  id: root

  property var app

  readonly property var profile: app ? app.profile : null
  readonly property var next: profile ? Lessons.nextLesson(profile) : null
  readonly property int done: profile ? Lessons.completedCount(profile) : 0
  readonly property int total: Lessons.LESSONS.length

  PageScroll {
    anchors.fill: parent

    // ------------------------------------------------------------ continue

    Card {
      width: parent.width
      title: root.next ? "Continue: " + root.next.title : "Curriculum complete"
      hint: root.next
        ? root.next.blurb
        : "Every lesson is finished. Re-run any of them for stars, or move to drills and speed tests."
      active: true

      Item {
        width: parent.width
        height: Style.space(34)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(10)

          Meter {
            width: Style.space(180)
            anchors.verticalCenter: parent.verticalCenter
            value: root.total > 0 ? root.done / root.total : 0
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.done + " of " + root.total + " lessons"
            color: Util.alpha(Color.foreground, 0.70)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        TextButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          label: root.next ? "Start lesson" : "Open speed test"
          primary: true
          onClicked: {
            if (root.next) root.app.startLesson(root.next.id)
            else root.app.startTest()
          }
        }
      }
    }

    // -------------------------------------------------------------- stages

    Repeater {
      model: Lessons.STAGES

      delegate: Card {
        id: stageCard
        required property var modelData
        width: parent.width

        readonly property var items: Lessons.lessonsIn(stageCard.modelData.id)
        readonly property int stageDone: {
          var n = 0
          for (var i = 0; i < stageCard.items.length; i++) {
            var rec = root.profile && root.profile.lessons ? root.profile.lessons[stageCard.items[i].id] : null
            if (rec && rec.done) n += 1
          }
          return n
        }

        title: stageCard.modelData.title
        hint: stageCard.modelData.blurb

        Item {
          width: parent.width
          height: Style.space(16)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: stageCard.stageDone + " / " + stageCard.items.length + " complete"
            color: Util.alpha(Color.foreground, 0.62)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          Meter {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(120)
            thickness: Style.space(3)
            value: stageCard.items.length > 0 ? stageCard.stageDone / stageCard.items.length : 0
          }
        }

        Flow {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: stageCard.items

            delegate: Rectangle {
              id: tile
              required property var modelData

              readonly property var record: root.profile && root.profile.lessons ? root.profile.lessons[tile.modelData.id] : null
              readonly property bool open: root.profile ? Lessons.unlocked(root.profile, tile.modelData) : tile.modelData.stage === "home"
              readonly property int stars: Lessons.starsFor(tile.record)

              width: Math.max(Style.space(132), (parent.width - Style.space(24)) / 3)
              height: Style.space(74)
              radius: 0
              color: Util.alpha(Color.foreground, hover.hovered && tile.open ? 0.07 : 0.03)
              border.width: 1
              border.color: Util.alpha(Color.foreground, tile.open ? 0.12 : 0.06)
              // Locked tiles stay readable — the lock glyph and the muted
              // border carry "not yet", not a fade to invisibility.
              opacity: tile.open ? 1 : 0.62

              Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(4)

                Text {
                  width: parent.width
                  text: tile.open ? tile.modelData.title : "🔒 " + tile.modelData.title
                  color: Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: tile.record && tile.record.done
                    ? (tile.record.bestWpm > 0
                        ? "best " + Math.round(tile.record.bestWpm) + " wpm"
                        : "complete · no timed best")
                    : (tile.modelData.targetWpm + " wpm target")
                  color: Util.alpha(Color.foreground, 0.64)
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }

                Row {
                  spacing: Style.space(3)

                  Repeater {
                    model: 3

                    delegate: Text {
                      required property int index
                      text: "★"
                      color: index < tile.stars ? Color.accent : Util.alpha(Color.foreground, 0.14)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }

              HoverHandler { id: hover }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (tile.open) root.app.startLesson(tile.modelData.id)
                  else root.app.toast("Finish the lesson before this one first")
                }
              }
            }
          }
        }
      }
    }
  }
}
