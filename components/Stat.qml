import QtQuick
import qs.Commons

// A number and its caption. Used all over the header and progress tab, so the
// typography is pinned here instead of being repeated at every call site.
Column {
  id: root

  property string value: ""
  property string unit: ""
  property string label: ""
  property color tint: Color.foreground
  property int valueSize: Style.font.heading

  spacing: Style.space(1)

  Row {
    spacing: Style.space(3)

    Text {
      text: root.value
      color: root.tint
      font.family: Style.font.family
      font.pixelSize: root.valueSize
      font.letterSpacing: -0.2
    }

    Text {
      visible: root.unit.length > 0
      text: root.unit
      color: Util.alpha(root.tint, 0.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(3)
    }
  }

  Text {
    visible: root.label.length > 0
    text: root.label
    color: Util.alpha(Color.foreground, 0.62)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 0.3
  }
}
