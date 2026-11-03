import QtQuick
import qs.Commons

// Flickable page body. Tabs only ever need vertical scrolling, so this pins
// contentWidth and derives contentHeight from the column it hosts. A slim
// indicator on the right is drawn by hand — importing QtQuick.Controls just
// for a scrollbar would drag a whole second palette into the plugin.
Flickable {
  id: root

  property int gap: Style.space(14)
  property int bottomPadding: Style.space(20)

  default property alias content: body.data

  clip: true
  contentWidth: width
  contentHeight: body.implicitHeight + bottomPadding
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: Flickable.VerticalFlick

  // The indicator lives in a reserved gutter instead of sitting on top of the
  // cards, which would otherwise draw a line straight through their borders.
  readonly property int indicatorGutter: Style.space(9)

  Column {
    id: body
    width: Math.max(0, root.width - root.indicatorGutter)
    spacing: root.gap
  }

  readonly property real visibleRatio: contentHeight > height && contentHeight > 0
    ? Util.clamp(height / contentHeight, 0.08, 1)
    : 1

  Rectangle {
    visible: root.contentHeight > root.height
    width: 3
    radius: 0
    color: Util.alpha(Color.foreground, 0.18)
    x: root.width - width - Style.space(2)
    height: Math.max(Style.space(24), root.height * root.visibleRatio)
    y: root.height > 0
      ? Util.clamp(root.contentY / Math.max(1, root.contentHeight) * root.height, 0, root.height - height)
      : 0
  }
}
