import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Drop-in for omarchy.workspaces. Under the koble-metal theme it numbers every
// workspace and lights the current one with a tinted block, a bright edge on
// the side facing the desktop, and a glow rising off that edge. Under any
// other theme it looks like the stock widget.
BarWidget {
  id: root
  moduleName: "koble.workspaces"

  property string themeName: ""
  readonly property bool koble: themeName === "koble-metal"
  readonly property color accent: Commons.Color.accent

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.themeName = text().trim()
    onLoadFailed: root.themeName = ""
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + id + "\" })")
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(root.koble ? 0.5 : 1)
    rowSpacing: root.vertical ? Style.space(root.koble ? 1 : 2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: slot

        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property bool lit: root.koble && focused

        implicitWidth: button.implicitWidth
        implicitHeight: button.implicitHeight

        // Lit block: tinted fill with a glow rising off the inner edge.
        // Laid out for a top bar and rotated for the other edges.
        Item {
          anchors.centerIn: parent
          width: root.vertical ? parent.height : parent.width
          height: root.vertical ? parent.width : parent.height
          rotation: !root.bar ? 0
            : root.bar.position === "bottom" ? 180
            : root.bar.position === "left" ? -90
            : root.bar.position === "right" ? 90 : 0
          opacity: slot.lit ? 1 : 0
          visible: opacity > 0

          Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop { position: 0.0; color: Qt.alpha(root.accent, 0.10) }
              GradientStop { position: 0.6; color: Qt.alpha(root.accent, 0.22) }
              GradientStop { position: 1.0; color: Qt.alpha(root.accent, 0.42) }
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: root.accent
          }
        }

        WidgetButton {
          id: button

          anchors.fill: parent
          bar: root.bar
          text: root.koble
            ? (slot.modelData === 10 ? "0" : String(slot.modelData))
            : (slot.focused ? "󱓻" : (slot.modelData === 10 ? "0" : String(slot.modelData)))
          foreground: slot.lit ? Commons.Color.foreground : (root.bar ? root.bar.barForeground : Commons.Color.foreground)
          opacity: slot.occupied || slot.focused ? 1 : (root.koble ? 0.4 : 0.5)
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical ? root.barSize : Style.space(root.koble ? 22 : 20)
          fixedHeight: root.barSize
          onPressed: function() { root.focusWorkspace(slot.modelData) }
        }
      }
    }
  }
}
