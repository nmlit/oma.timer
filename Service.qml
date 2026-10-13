import QtQuick
import Quickshell.Io
import "Format.js" as Format

// En delad nedräkning för alla skärmar. Förankrad i väggklockan så att
// suspend eller en stillastående eventloop inte får den att driva.
Item {
  id: root

  property var shell: null

  readonly property string pluginId: "oma.timer"
  readonly property string timerGlyph: "\u{f051f}"
  readonly property string idleGlyph: "\u{f051b}"
  readonly property string soundFile: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

  property double now: Date.now()

  property double duration: 5 * 60000
  property bool running: false
  property double endsAt: 0
  property double pausedRemaining: -1
  property bool finished: false
  readonly property double remaining: running ? Math.max(0, endsAt - now)
    : pausedRemaining >= 0 ? pausedRemaining
    : finished ? 0
    : duration
  readonly property bool active: running || pausedRemaining >= 0 || finished

  function toggle() {
    now = Date.now()
    if (finished) {
      reset()
    } else if (running) {
      pausedRemaining = Math.max(0, endsAt - now)
      running = false
    } else {
      endsAt = now + (pausedRemaining >= 0 ? pausedRemaining : duration)
      pausedRemaining = -1
      running = true
    }
  }

  function reset() {
    running = false
    pausedRemaining = -1
    finished = false
    stopSignal()
  }

  // Stoppar ljudet och stänger väntande notis direkt.
  function stopSignal() {
    if (soundProc.running) soundProc.signal(15)
    soundProc.running = false
    if (notifyProc.running) notifyProc.signal(15)
    notifyProc.running = false
  }

  // Tid kan bara ändras när timern är stoppad; en igång timer behåller sin deadline.
  function setSeconds(seconds) {
    if (active) return
    duration = Math.max(1, Math.min(24 * 3600, Math.round(seconds))) * 1000
  }

  function adjust(deltaSeconds) {
    setSeconds(Math.round(duration / 1000) + deltaSeconds)
  }

  function setFromText(text) {
    var s = Format.parse(text)
    if (s > 0) { setSeconds(s); return true }
    return false
  }

  function start(seconds) {
    reset()
    setSeconds(seconds)
    toggle()
  }

  function finish() {
    running = false
    pausedRemaining = -1
    finished = true
    notifyProc.command = [
      "notify-send", "-a", "oma.timer", "--wait",
      "--action=default=Kvittera", "--action=dismiss=Kvittera", "-u", "critical", "-i", "alarm-symbolic",
      "⏰ Tiden är ute!", "Timern på " + Format.label(root.duration) + " är slut."
    ]
    notifyProc.running = true
    // Spelaren körs i bakgrunden och dödas via trap när processen avslutas,
    // så ljudet tystnar direkt vid Kvittera / klick på notisen.
    soundProc.command = ["sh", "-c",
      "f='" + root.soundFile + "'; p=; trap 'kill $p 2>/dev/null; exit 0' TERM INT HUP; " +
      "for i in 1 2 3 4 5 6; do if command -v pw-play >/dev/null; then pw-play \"$f\" & else paplay \"$f\" & fi; p=$!; wait $p; done"]
    soundProc.running = true
  }

  Timer {
    interval: 250
    running: root.running
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.now = Date.now()
      if (root.running && root.now >= root.endsAt) root.finish()
    }
  }

  // notify-send --wait avslutas när notisen klickas eller stängs: kvittera då.
  Process {
    id: notifyProc
    onExited: if (root.finished) root.reset()
  }
  Process { id: soundProc }

  // omarchy-shell -q oma.timer toggle     öppna / stäng panelen
  // omarchy-shell -q oma.timer start 25   starta en 25-minuters timer
  // omarchy-shell -q oma.timer set 1:30   starta med valfri tid (25, 1:30, 1h30m, 90s)
  // omarchy-shell -q oma.timer pause      start / paus
  // omarchy-shell -q oma.timer reset      nollställ
  IpcHandler {
    target: root.pluginId

    function toggle(): void { if (root.shell) root.shell.toggle(root.pluginId, "{}") }
    function open(): void { if (root.shell) root.shell.summon(root.pluginId, "{}") }
    function close(): void { if (root.shell) root.shell.hide(root.pluginId) }
    function start(minutes: int): void {
      if (minutes > 0) root.start(minutes * 60)
      else root.toggle()
    }
    function set(time: string): void {
      var s = Format.parse(time)
      if (s > 0) root.start(s)
    }
    function pause(): void { root.toggle() }
    function reset(): void { root.reset() }
  }
}
