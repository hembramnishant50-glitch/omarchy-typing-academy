import QtQuick
import qs.Commons

// Label on the left, control on the right. Rows like this appear in Settings
// and in the drill builders, so the baseline alignment lives in one place.
Item {
  id: root

  property string label: ""
  property string hint: ""
  property int controlWidth: -1

  default property alias control: slot.data

  // A plain Item does not follow its own implicit size, and the card body is a
  // Column that sizes children from their height. Both have to be stated, or
  // every row collapses to nothing.
  width: parent ? parent.width : implicitWidth
  height: implicitHeight

  implicitHeight: Math.max(textBlock.implicitHeight, slot.implicitHeight) + Style.space(9)

  Column {
    id: textBlock
    anchors.left: parent.left
    anchors.right: slot.left
    anchors.rightMargin: Style.space(14)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Text {
      width: parent.width
      text: root.label
      color: Util.alpha(Color.foreground, 0.88)
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.hint.length > 0
      text: root.hint
      color: Util.alpha(Color.foreground, 0.64)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      lineHeight: 1.2
    }
  }

  Item {
    id: slot
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: root.controlWidth > 0 ? root.controlWidth : childrenRect.width
    height: childrenRect.height
  }
}
