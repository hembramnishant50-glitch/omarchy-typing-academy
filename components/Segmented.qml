import QtQuick
import qs.Commons

// Exclusive single-choice row. Options are { id, label } objects so the
// caller can keep using stable string ids in its own state.
Row {
  id: root

  property var options: []
  property string value: ""

  signal picked(string id)

  spacing: Style.space(4)

  Repeater {
    model: root.options

    delegate: Chip {
      id: chip
      required property var modelData
      label: chip.modelData.label !== undefined ? chip.modelData.label : String(chip.modelData)
      active: root.value === chip.modelData.id
      onClicked: root.picked(chip.modelData.id)
    }
  }
}
