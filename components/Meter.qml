import QtQuick
import qs.Commons

// Progress bar. Hand-rolled rather than QtQuick.Controls.ProgressBar so the
// track and fill are both plain theme-derived colors.
Item {
  id: root

  property real value: 0
  property color fill: Color.accent
  property color trackColor: Util.alpha(Color.foreground, 0.08)
  property int thickness: Style.space(5)

  readonly property real clamped: Util.clamp(value, 0, 1)

  implicitHeight: thickness
  implicitWidth: 80

  Rectangle {
    anchors.fill: parent
    radius: 0
    color: root.trackColor
  }

  Rectangle {
    height: parent.height
    width: Math.max(0, parent.width * root.clamped)
    radius: 0
    color: root.fill
    visible: width > 0

    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  }
}
