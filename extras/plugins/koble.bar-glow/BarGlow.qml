import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons

// The bar has no border of its own, so this draws a thin click-through strip
// on each screen, butted against the bar's inner edge: a bright accent line
// with a soft glow fading out over the desktop. It only shows while the
// koble-metal theme is active, so it can stay enabled across theme changes.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property var barState: shell ? shell.bar : null
  readonly property string position: barState ? barState.position : "top"
  readonly property int barSize: barState ? barState.barSize : 0
  readonly property bool barHidden: barState ? barState.barHidden : false
  readonly property bool vertical: position === "left" || position === "right"

  readonly property int lineSize: 2
  readonly property int glowSize: 12
  readonly property color glowColor: Commons.Color.accent

  property string themeName: ""
  readonly property bool active: themeName === "koble-metal" && barSize > 0 && !barHidden

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.themeName = text().trim()
    onLoadFailed: root.themeName = ""
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      visible: root.active
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "koble-bar-glow"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      // Visual only: never take clicks from the windows underneath.
      mask: Region {}

      anchors {
        top: root.position !== "bottom"
        bottom: root.position !== "top"
        left: root.position !== "right"
        right: root.position !== "left"
      }

      margins {
        top: root.position === "top" ? root.barSize : 0
        bottom: root.position === "bottom" ? root.barSize : 0
        left: root.position === "left" ? root.barSize : 0
        right: root.position === "right" ? root.barSize : 0
      }

      implicitWidth: root.vertical ? root.lineSize + root.glowSize : 0
      implicitHeight: root.vertical ? 0 : root.lineSize + root.glowSize

      // Lay the strip out as if the bar were on top, then rotate it into
      // place for the other edges.
      Item {
        readonly property real angle: root.position === "bottom" ? 180
          : root.position === "left" ? -90
          : root.position === "right" ? 90 : 0

        anchors.centerIn: parent
        width: root.vertical ? parent.height : parent.width
        height: root.lineSize + root.glowSize
        rotation: angle

        Rectangle {
          id: glow
          anchors.fill: parent
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(root.glowColor, 0.45) }
            GradientStop { position: 0.35; color: Qt.alpha(root.glowColor, 0.14) }
            GradientStop { position: 1.0; color: Qt.alpha(root.glowColor, 0.0) }
          }
        }

        Rectangle {
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: root.lineSize
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.alpha(root.glowColor, 0.55) }
            GradientStop { position: 0.5; color: Qt.alpha(root.glowColor, 0.95) }
            GradientStop { position: 1.0; color: Qt.alpha(root.glowColor, 0.55) }
          }
        }
      }
    }
  }
}
