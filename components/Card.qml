import QtQuick
import qs.Commons

// Bordered surface. Children declared inside the card are appended to `body`,
// which is a Column — so a card lays itself out from `implicitHeight` without
// the caller needing to reach for anchors.
Rectangle {
  id: root

  property string title: ""
  property string hint: ""
  property int padding: Style.space(16)
  property int gap: Style.space(10)
  property color tint: Color.foreground
  property bool interactive: false
  property bool active: false

  signal clicked()

  default property alias content: body.data
  property alias bodySpacing: body.spacing

  readonly property bool hot: hover.hovered && interactive

  implicitWidth: 240
  implicitHeight: shell.implicitHeight + padding * 2

  radius: 0
  color: Util.alpha(tint, active ? 0.06 : hot ? 0.05 : 0.03)
  border.width: 1
  border.color: Util.alpha(tint, active ? 0.28 : hot ? 0.20 : 0.09)

  Behavior on color { ColorAnimation { duration: 120 } }

  Column {
    id: shell
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.padding
    spacing: root.gap

    Column {
      width: shell.width
      visible: root.title.length > 0
      spacing: Style.space(3)

      Text {
        width: parent.width
        text: root.title
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: root.hint.length > 0
        text: root.hint
        color: Util.alpha(Color.foreground, 0.66)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        lineHeight: 1.25
      }
    }

    Column {
      id: body
      width: shell.width
      spacing: Style.space(8)
    }
  }

  HoverHandler { id: hover }

  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}
