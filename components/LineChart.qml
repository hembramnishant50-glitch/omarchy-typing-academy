import QtQuick
import QtQuick.Shapes
import qs.Commons

// Polyline chart for test history. Uses QtQuick.Shapes rather than Canvas so
// there is no imperative paint state to keep in sync with the model.
Item {
  id: root

  property var values: []
  property color lineColor: Color.accent
  property real floorValue: 0
  property int lineWidth: 2
  property bool showArea: true

  readonly property int count: (values || []).length
  readonly property real peak: {
    var list = values || []
    var top = floorValue
    for (var i = 0; i < list.length; i++) top = Math.max(top, Number(list[i]) || 0)
    return top > 0 ? top * 1.12 : 1
  }

  implicitWidth: 200
  implicitHeight: 80
  clip: true

  function linePoints() {
    var list = values || []
    if (list.length === 0 || width <= 0 || height <= 0) return []
    var top = peak
    var out = []
    var n = list.length
    var w = width - lineWidth
    var h = height - lineWidth
    for (var i = 0; i < n; i++) {
      var x = lineWidth / 2 + (n === 1 ? w / 2 : (i / (n - 1)) * w)
      var ratio = Util.clamp((Number(list[i]) || 0) / top, 0, 1)
      out.push(Qt.point(x, lineWidth / 2 + h - ratio * h))
    }
    return out
  }

  function areaPoints() {
    var line = linePoints()
    if (line.length === 0) return []
    var out = line.slice()
    out.push(Qt.point(line[line.length - 1].x, height))
    out.push(Qt.point(line[0].x, height))
    return out
  }

  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Util.alpha(Color.foreground, 0.08)
  }

  Shape {
    anchors.fill: parent
    visible: root.count > 0

    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"
      // ShapePath is not an Item, so it has no `visible`; hide the area by
      // making it fully transparent instead.
      fillColor: root.showArea ? Util.alpha(root.lineColor, 0.10) : "transparent"
      PathPolyline { path: root.areaPoints() }
    }

    ShapePath {
      strokeWidth: root.lineWidth
      strokeColor: root.lineColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathPolyline { path: root.linePoints() }
    }
  }

  // A lone point has no segment to stroke, so a single run left the chart
  // blank. Mark it with a dot instead.
  Rectangle {
    readonly property var only: root.count === 1 ? root.linePoints()[0] : null
    visible: root.count === 1
    width: Style.space(5)
    height: width
    radius: 0
    color: root.lineColor
    x: only ? only.x - width / 2 : 0
    y: only ? only.y - height / 2 : 0
  }

  Text {
    anchors.centerIn: parent
    visible: root.count === 0
    text: "No runs yet"
    color: Util.alpha(Color.foreground, 0.52)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
