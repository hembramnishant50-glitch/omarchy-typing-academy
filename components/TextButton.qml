import QtQuick
import qs.Commons

// Text button. `primary` fills with the accent; everything else is a quiet
// outline so a screen never ends up with three competing focal points.
Rectangle {
  id: root

  property string label: ""
  property bool primary: false
  property bool danger: false
  property bool enabledButton: true
  property int horizontalPadding: Style.space(14)
  property int fontSize: Style.font.body

  signal clicked()

  readonly property bool hot: hover.hovered && enabledButton
  readonly property color base: danger ? Color.urgent : (primary ? Color.accent : Color.foreground)

  implicitWidth: btnText.implicitWidth + horizontalPadding * 2
  implicitHeight: Style.space(30)
  radius: 0
  opacity: enabledButton ? 1 : 0.4

  color: primary
    ? Util.alpha(base, hot ? 0.24 : 0.18)
    : Util.alpha(base, hot ? 0.12 : 0.04)

  border.width: 1
  border.color: primary
    ? Util.alpha(base, 0.6)
    : Util.alpha(base, hot ? 0.34 : 0.16)

  Behavior on color { ColorAnimation { duration: 110 } }

  Text {
    id: btnText
    anchors.centerIn: parent
    text: root.label
    color: root.primary ? root.base : Util.alpha(root.base, 0.88)
    font.family: Style.font.family
    font.pixelSize: root.fontSize
    font.letterSpacing: 0.3
  }

  HoverHandler { id: hover }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabledButton
    cursorShape: root.enabledButton ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}
