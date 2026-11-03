import QtQuick
import qs.Commons

// Theme-derived on/off control. `checked` is a plain property, not a binding,
// so the owner stays in charge of the value changing.
Item {
  id: root

  property bool checked: false

  signal toggled(bool value)

  implicitWidth: Style.space(38)
  implicitHeight: Style.space(20)

  Rectangle {
    id: track
    anchors.fill: parent
    radius: 0
    color: root.checked
      ? Util.alpha(Color.accent, 0.55)
      : Util.alpha(Color.foreground, hover.hovered ? 0.14 : 0.09)
    border.width: 1
    border.color: root.checked
      ? Util.alpha(Color.accent, 0.75)
      : Util.alpha(Color.foreground, 0.18)

    Behavior on color { ColorAnimation { duration: 130 } }
  }

  Rectangle {
    id: knob
    width: parent.height - Style.space(6)
    height: width
    radius: 0
    y: Style.space(3)
    x: root.checked ? parent.width - width - Style.space(3) : Style.space(3)
    color: root.checked ? Color.background : Util.alpha(Color.foreground, 0.62)

    Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
  }

  HoverHandler { id: hover }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled(!root.checked)
  }
}
