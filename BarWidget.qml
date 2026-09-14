import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mat.reminder-countdown"

  property var reminders: []
  property var nextReminder: null
  property var seenReminders: ({})
  property int remainingSeconds: 0
  property bool expiredPending: false
  property string expiredLabel: ""
  property bool blinkOn: true
  readonly property bool hasReminder: nextReminder !== null
  readonly property bool hideWhenEmpty: setting("hideWhenEmpty", true) === true
  readonly property bool showLabel: setting("showLabel", false) === true
  readonly property bool compactVertical: vertical
  readonly property string iconText: "󰢌"
  readonly property string notificationSound: "/usr/share/sounds/freedesktop/stereo/complete.oga"
  readonly property string countdownText: formatDuration(remainingSeconds)
  readonly property string labelText: showLabel && hasReminder && nextReminder.label ? shortLabel(nextReminder.label) + " " : ""
  readonly property string displayText: expiredPending
    ? iconText + " !" + (hasReminder ? " " + labelText + countdownText : "")
    : iconText + " " + labelText + countdownText
  readonly property string tooltipText: expiredPending
    ? "Reminder reached: " + (expiredLabel || "Reminder") + ". Click to dismiss."
    : (hasReminder ? nextReminder.label + " in " + formatDuration(remainingSeconds) + " (" + nextReminder.atTime + ")" : "Set Reminder")

  function shortLabel(value) {
    var text = String(value || "").replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "")
    if (text.length <= 18) return text
    return text.slice(0, 17) + "..."
  }

  function formatDuration(seconds) {
    seconds = Math.max(0, Number(seconds || 0))
    var hours = Math.floor(seconds / 3600)
    var minutes = Math.floor((seconds % 3600) / 60)
    var secs = seconds % 60

    if (hours > 0) return hours + ":" + pad2(minutes) + ":" + pad2(secs)
    return minutes + ":" + pad2(secs)
  }

  function pad2(value) {
    value = Math.floor(Number(value || 0))
    return value < 10 ? "0" + value : String(value)
  }

  function reminderKey(item) {
    if (!item) return ""
    if (item.unit) return String(item.unit)
    if (item.timer) return String(item.timer)
    return String(item.at || "") + "|" + String(item.label || "")
  }

  function findNext(items) {
    var best = null
    for (var i = 0; i < items.length; i++) {
      var item = items[i]
      if (!item) continue
      var remaining = Number(item.remainingSeconds || 0)
      if (remaining <= 0) continue
      if (best === null || remaining < Number(best.remainingSeconds || 0)) best = item
    }
    return best
  }

  function containsReminder(items, key) {
    if (key === "") return false
    for (var i = 0; i < items.length; i++) {
      if (reminderKey(items[i]) === key) return true
    }
    return false
  }

  function snapshotReminders(items) {
    var snapshot = {}
    for (var i = 0; i < items.length; i++) {
      var item = items[i]
      var key = reminderKey(item)
      if (key === "") continue
      snapshot[key] = {
        at: Number(item.at || 0),
        label: String(item.label || "")
      }
    }
    return snapshot
  }

  function playNotificationSound() {
    Quickshell.execDetached(["bash", "-c", "pw-play \"$1\" && pw-play \"$1\"", "bash", notificationSound])
  }

  function markExpiredFromMissing(items) {
    var now = Date.now() / 1000
    var detectedExpired = false
    for (var key in seenReminders) {
      var previous = seenReminders[key]
      if (!previous || containsReminder(items, key)) continue
      if (Number(previous.at || 0) > 0 && now >= Number(previous.at) - 2) {
        expiredPending = true
        expiredLabel = String(previous.label || "")
        detectedExpired = true
      }
    }
    if (detectedExpired) playNotificationSound()
  }

  function updateFromData(data) {
    var items = data && data.reminders && typeof data.reminders.length === "number" ? data.reminders : []
    var next = findNext(items)

    markExpiredFromMissing(items)
    reminders = items
    nextReminder = next
    seenReminders = snapshotReminders(items)

    if (next) {
      remainingSeconds = Math.max(0, Number(next.remainingSeconds || 0))
      return
    }

    remainingSeconds = 0
  }

  function update(raw) {
    try {
      updateFromData(JSON.parse(raw || "{}"))
    } catch (error) {
      reminders = []
      nextReminder = null
      remainingSeconds = 0
    }
  }

  function refresh() {
    if (!jsonProc.running) jsonProc.running = true
  }

  visible: expiredPending || hasReminder || !hideWhenEmpty
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: barSize

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: blinkTimer
    interval: 500
    repeat: true
    running: root.expiredPending
    onTriggered: root.blinkOn = !root.blinkOn
    onRunningChanged: if (running) root.blinkOn = true
  }

  Process {
    id: jsonProc
    command: ["omarchy-reminder", "show", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.update(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.reminders = []
        root.nextReminder = null
        root.remainingSeconds = 0
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.compactVertical ? root.iconText : root.displayText
    tooltipText: root.tooltipText
    fontSize: Style.font.caption
    fixedWidth: root.compactVertical ? Style.bar.statusSlot : -1
    fixedHeight: root.compactVertical ? -1 : root.barSize
    horizontalMargin: root.compactVertical ? 0 : 7
    foreground: root.bar ? root.bar.barForeground : Color.foreground
    active: root.expiredPending
    useActiveColor: root.expiredPending

    opacity: root.expiredPending ? (root.blinkOn ? 1 : 0.35) : 1

    onPressed: function() {
      if (root.expiredPending) {
        root.expiredPending = false
        return
      }

      if (root.hasReminder) Quickshell.execDetached(["omarchy-reminder", "show"])
      else Quickshell.execDetached(["omarchy-reminder", "-i"])
    }
  }
}
