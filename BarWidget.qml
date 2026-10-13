import QtQuick
import qs.Commons
import qs.Ui
import "Format.js" as Format

BarWidget {
  id: root

  readonly property string pluginId: "oma.timer"
  moduleName: pluginId

  readonly property var timer: bar && bar.shell ? bar.shell.serviceFor(pluginId) : null

  readonly property bool shown: timer ? timer.active : false
  readonly property string glyph: !timer ? "" : shown ? timer.timerGlyph : timer.idleGlyph
  readonly property string timeText: shown ? Format.remaining(timer.remaining) : ""
  readonly property bool paused: shown && !timer.running && !timer.finished
  readonly property bool finished: timer ? timer.finished : false
  readonly property bool showsTime: shown && !vertical

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  function handlePress(button) {
    if (!root.timer) return
    if (button === Qt.RightButton) root.timer.toggle()
    else if (button === Qt.MiddleButton) root.timer.reset()
    else root.togglePanel()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }

  visible: timer !== null
  implicitWidth: showsTime ? textButton.implicitWidth : iconButton.implicitWidth
  implicitHeight: showsTime ? textButton.implicitHeight : iconButton.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  // Blinkar i baren tills timern kvitteras.
  property real blinkOpacity: 1
  SequentialAnimation on blinkOpacity {
    running: root.finished
    loops: Animation.Infinite
    NumberAnimation { to: 0.2; duration: 400 }
    NumberAnimation { to: 1; duration: 400 }
    onRunningChanged: if (!running) root.blinkOpacity = 1
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: iconButton
    anchors.fill: parent
    visible: !root.showsTime
    opacity: root.blinkOpacity
    bar: root.bar
    text: root.glyph
    slotSize: Style.bar.statusSlot
    active: root.finished
    tooltipText: root.vertical && root.timeText !== "" ? root.timeText : "Timer"
    onPressed: function(b) { root.handlePress(b) }
  }

  WidgetButton {
    id: textButton
    anchors.fill: parent
    visible: root.showsTime
    opacity: root.blinkOpacity
    bar: root.bar
    text: root.glyph + " " + root.timeText
    dimmed: root.paused
    active: root.finished
    onPressed: function(b) { root.handlePress(b) }
  }
}
