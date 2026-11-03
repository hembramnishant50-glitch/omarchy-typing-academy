import QtQuick
import qs.Commons

// Small pill used for tabs, mode pickers and lesson status. Deliberately not
// QtQuick.Controls — a Button would drag in its own palette and hover chrome
// that fights the shell theme.
Rectangle {
  id: root

  property string label: ""
  property bool active: false
  property bool interactive: true
  property color tint: Color.foreground
  property color accentColor: Color.accent
  property int horizontalPadding: Style.space(10)
  property int fontSize: Style.font.bodySmall

  signal clicked()

  readonly property bool hot: hover.hovered && interactive

  implicitWidth: chipText.implicitWidth + horizontalPadding * 2
  implicitHeight: Style.space(24)
  radius: 0

  color: active
    ? Util.alpha(accentColor, 0.16)
    : hot
      ? Util.alpha(tint, 0.10)
      : Util.alpha(tint, 0.04)

  border.width: 1
  border.color: active
    ? Util.alpha(accentColor, 0.45)
    : Util.alpha(tint, hot ? 0.22 : 0.10)

  Behavior on color { ColorAnimation { duration: 110 } }

  Text {
    id: chipText
    anchors.centerIn: parent
    text: root.label
    color: root.active ? root.accentColor : Util.alpha(root.tint, 0.78)
    font.family: Style.font.family
    font.pixelSize: root.fontSize
    font.letterSpacing: 0.4
  }

  HoverHandler { id: hover }

  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}
