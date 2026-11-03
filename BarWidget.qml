import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "nishant.typing-academy"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleAcademy() {
    const bar = root.bar
    if (bar && typeof bar.run === "function") {
      bar.run("omarchy-shell shell toggle nishant.typing-academy")
      return
    }
    Quickshell.execDetached(["bash", "-lc", "omarchy-shell shell toggle nishant.typing-academy"])
  }

  MouseArea {
    id: clickArea
    anchors.fill: parent
    onClicked: root.toggleAcademy()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uF19D"
    slotSize: Style.bar.iconSlot
    fontSize: Style.bar.iconFont
    tooltipText: "Typing Academy"
    pressable: false
    interactive: false
    onPressed: root.toggleAcademy()
  }
}
