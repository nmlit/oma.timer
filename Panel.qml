import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Format.js" as Format

// Flytande kort som bara täcker sig självt; resten av skärmen fungerar
// medan det är öppet. Stängs med Esc eller från baren.
Panel {
  id: root
  moduleName: "oma.timer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var timer: hostWidget ? hostWidget.timer : null

  readonly property bool running: timer ? timer.running : false
  readonly property bool active: timer ? timer.active : false
  readonly property bool finished: timer ? timer.finished : false
  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.5)
  readonly property var presets: [1, 3, 5, 10, 15, 25, 45, 60]

  function open() {
    root.controller.show()
    Qt.callLater(function() { if (root.opened) keyCatcher.forceActiveFocus() })
  }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) root.close(); else root.open() }

  function applyInput() {
    if (!root.timer) return
    if (root.timer.setFromText(input.text)) {
      input.text = ""
      keyCatcher.forceActiveFocus()
    } else {
      input.invalid = true
    }
  }

  PanelWindow {
    id: win

    readonly property var anchorWindow: root.anchorItem ? root.anchorItem.QsWindow.window : null
    readonly property string barPos: root.bar ? root.bar.position : "top"
    readonly property bool sideBar: barPos === "left" || barPos === "right"
    readonly property real gap: Style.gapsOut
    readonly property real barThickness: anchorWindow ? (sideBar ? anchorWindow.width : anchorWindow.height) : 0
    readonly property real anchorOffset: {
      if (!root.opened || !root.anchorItem || !anchorWindow) return 0
      var p = root.anchorItem.mapToItem(anchorWindow.contentItem, 0, 0)
      return sideBar
        ? p.y + root.anchorItem.height / 2 - implicitHeight / 2
        : p.x + root.anchorItem.width / 2 - implicitWidth / 2
    }
    readonly property real screenLength: screen ? (sideBar ? screen.height : screen.width) : 0
    readonly property real alongMargin: Math.max(gap, Math.min(anchorOffset, screenLength - (sideBar ? implicitHeight : implicitWidth) - gap))
    readonly property real awayMargin: barThickness + gap

    screen: anchorWindow ? anchorWindow.screen : null
    visible: root.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Style.space(360)
    implicitHeight: card.implicitHeight

    anchors {
      top: win.barPos !== "bottom"
      bottom: win.barPos === "bottom"
      left: win.barPos !== "right"
      right: win.barPos === "right"
    }
    margins {
      top: win.barPos === "top" ? win.awayMargin : win.sideBar ? win.alongMargin : 0
      bottom: win.barPos === "bottom" ? win.awayMargin : 0
      left: win.barPos === "left" ? win.awayMargin : win.sideBar ? 0 : win.alongMargin
      right: win.barPos === "right" ? win.awayMargin : 0
    }

    WlrLayershell.namespace: "oma.timer"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    BorderSurface {
      id: card
      anchors.fill: parent
      implicitHeight: column.implicitHeight + contentTopInset + contentBottomInset
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.popupPadding
      radius: Style.cornerRadius

      PanelKeyCatcher {
        id: keyCatcher
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        blocked: input.activeFocus
        onCloseRequested: root.close()
        onActivateRequested: if (root.timer) root.timer.toggle()
        onDeleteRequested: if (root.timer) root.timer.reset()
        onMoveRequested: function(dx, dy) {
          if (!root.timer) return
          if (dx !== 0) root.timer.adjust(dx * 10)   // h/l: ±10 s
          else root.timer.adjust(-dy * 60)           // j/k: ±1 min
        }
        onTextKey: function(text) {
          if (!root.timer) return
          if (text === "r") root.timer.reset()
          else if (text === "e" || text === "i") input.forceActiveFocus()
        }

        Column {
          id: column
          width: parent.width
          spacing: Style.space(14)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.PlainText
            text: root.finished ? "Tiden är ute!" : root.running ? "Räknar ner" : root.active ? "Pausad" : "Nedräkningstimer"
            color: root.finished ? (root.bar ? root.bar.urgent : Color.urgent) : root.dim
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            id: readout
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.PlainText
            text: root.timer ? Format.remaining(root.timer.remaining) : ""
            color: root.finished ? (root.bar ? root.bar.urgent : Color.urgent) : root.fg
            opacity: root.active && !root.running && !root.finished ? 0.55 : 1
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: 56
            font.bold: true
            font.features: { "tnum": 1 }

            SequentialAnimation on scale {
              running: root.finished
              loops: Animation.Infinite
              NumberAnimation { to: 1.08; duration: 400 }
              NumberAnimation { to: 1.0; duration: 400 }
            }

            WheelHandler {
              onWheel: function(event) {
                if (root.timer) root.timer.adjust(event.angleDelta.y > 0 ? 60 : -60)
              }
            }
          }

          // Justera tiden: −/+ minuter och sekunder.
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(4)
            enabled: root.timer ? !root.timer.active : false
            opacity: enabled ? 1 : 0.4

            Button { text: "−1m";  foreground: root.fg; fontSize: Style.font.bodySmall; onClicked: root.timer.adjust(-60) }
            Button { text: "−10s"; foreground: root.fg; fontSize: Style.font.bodySmall; onClicked: root.timer.adjust(-10) }
            Button { text: "+10s"; foreground: root.fg; fontSize: Style.font.bodySmall; onClicked: root.timer.adjust(10) }
            Button { text: "+1m";  foreground: root.fg; fontSize: Style.font.bodySmall; onClicked: root.timer.adjust(60) }
          }

          // Snabbval i minuter.
          Flow {
            width: parent.width
            spacing: Style.space(4)
            enabled: root.timer ? !root.timer.active : false
            opacity: enabled ? 1 : 0.4

            Repeater {
              model: root.presets
              Button {
                required property int modelData
                text: modelData + "m"
                selected: root.timer ? Math.round(root.timer.duration / 1000) === modelData * 60 : false
                foreground: root.fg
                fontSize: Style.font.bodySmall
                onClicked: if (root.timer) root.timer.setSeconds(modelData * 60)
              }
            }
          }

          // Egen tid: 25, 7:30, 1:15:00, 1h30m, 90s
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: input.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: "transparent"
            border.width: 1
            border.color: input.invalid ? (root.bar ? root.bar.urgent : Color.urgent) : input.activeFocus ? root.fg : root.dim
            opacity: root.timer && root.timer.active ? 0.4 : 1

            TextInput {
              id: input
              property bool invalid: false
              anchors.fill: parent
              anchors.margins: Style.space(6)
              verticalAlignment: TextInput.AlignVCenter
              enabled: root.timer ? !root.timer.active : false
              color: root.fg
              selectionColor: root.dim
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              clip: true
              onTextChanged: invalid = false
              onAccepted: root.applyInput()
              Keys.onEscapePressed: { text = ""; keyCatcher.forceActiveFocus() }

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: input.text === "" && !input.activeFocus
                text: "Egen tid… (25, 7:30, 1:15:00, 1h30m) + Enter"
                color: root.dim
                font: input.font
              }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(8)

            Button {
              width: Style.space(110)
              bordered: true
              text: root.finished ? "Kvittera" : root.running ? "Paus" : root.active ? "Fortsätt" : "Starta"
              foreground: root.fg
              onClicked: {
                if (!root.timer) return
                if (input.text !== "" && !root.timer.active) root.applyInput()
                root.timer.toggle()
              }
            }
            Button {
              width: Style.space(110)
              bordered: true
              text: "Nollställ"
              enabled: root.active
              opacity: enabled ? 1 : 0.4
              foreground: root.fg
              onClicked: if (root.timer) root.timer.reset()
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.PlainText
            text: "mellanslag start/paus · r nollställ · j/k ±1m · h/l ±10s · e egen tid · esc"
            color: root.dim
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
