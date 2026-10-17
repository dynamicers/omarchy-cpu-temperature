import QtQuick
import QtQml.Models
import Quickshell.Io
import qs.Ui
import qs.Commons
import "TemperatureUtils.js" as TemperatureUtils

BarWidget {
  id: root
  moduleName: "omarchy-cpu-temperature"

  property var sensorPaths: []
  property var reading: ({temperature: null, sensors: []})
  readonly property int pollInterval: TemperatureUtils.boundedInteger(root.setting("pollInterval", 15000), 15000, 1000, 60000)
  readonly property int warningTemperature: TemperatureUtils.boundedInteger(root.setting("warningTemperature", 85), 85, 50, 110)
  readonly property bool available: typeof reading.temperature === "number" && isFinite(reading.temperature)
  readonly property string statusTooltip: {
    if (!available) return "CPU 温度暂不可用"
    var lines = ["CPU 当前最高温度：" + reading.temperature.toFixed(1) + "°C"]
    for (var sensor of reading.sensors)
      lines.push(sensor.label + "：" + sensor.temperature.toFixed(1) + "°C")
    lines.push("每 " + (poll.interval / 1000) + " 秒更新；点击立即刷新")
    return lines.join("\n")
  }

  function updateReading() {
    var sensors = []
    var highest = null
    for (var i = 0; i < readers.count; ++i) {
      var sensor = readers.objectAt(i)
      if (!sensor || !isFinite(sensor.temperature) || sensor.temperature < 0 || sensor.temperature > 150) continue
      sensors.push({label: sensor.label, temperature: sensor.temperature})
      if (highest === null || sensor.temperature > highest) highest = sensor.temperature
    }
    reading = {temperature: highest, sensors: sensors}
  }

  function refresh() {
    if (readers.count === 0) {
      rediscover()
      return
    }
    for (var i = 0; i < readers.count; ++i) {
      var sensor = readers.objectAt(i)
      if (sensor) sensor.valueFile.reload()
    }
  }

  function rediscover() {
    if (!discovery.running) discovery.running = true
  }

  // Normal polling spawns no processes. Retry discovery at most once per minute
  // while unavailable, including when drivers appear late or hwmon paths change.
  Timer {
    interval: 60000
    running: !root.available
    repeat: true
    onTriggered: root.rediscover()
  }
  Process {
    id: discovery
    running: true
    command: ["sh", decodeURIComponent(Qt.resolvedUrl("discover-sensors.sh").toString().replace(/^file:\/\//, ""))]
    stdout: StdioCollector {
      onStreamFinished: {
        var entries = []
        var lines = text.trim() ? text.trim().split("\n") : []
        for (var i = 0; i < lines.length; ++i) {
          var parts = lines[i].split("\t")
          if (parts.length < 3) continue
          entries.push({driver: parts[0], label: parts[1], path: parts[2]})
        }
        // Keep existing readers when paths are unchanged; their next poll retries
        // failed reads without discarding successful readings unnecessarily.
        if (JSON.stringify(entries) !== JSON.stringify(root.sensorPaths)) {
          root.reading = {temperature: null, sensors: []}
          root.sensorPaths = entries
        }
      }
    }
  }

  Instantiator {
    id: readers
    model: root.sensorPaths
    delegate: QtObject {
      id: sensor
      required property var modelData
      property real temperature: NaN
      property string label: modelData.driver + ": " + modelData.label
      property FileView valueFile: FileView {
        path: sensor.modelData.path
        watchChanges: false
        printErrors: false
        onLoaded: {
          sensor.temperature = TemperatureUtils.parseTemperature(text())
          Qt.callLater(root.updateReading)
        }
        onLoadFailed: {
          sensor.temperature = NaN
          Qt.callLater(root.updateReading)
        }
      }
    }
  }

  Timer {
    id: poll
    interval: root.pollInterval
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "cpuTemperature"
    function status(): string {
      return JSON.stringify({interval: poll.interval, reading: root.reading, sensors: readers.count})
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.available ? Math.round(root.reading.temperature) + (vertical ? "\n°C" : "°C") : "—"
    fontSize: Style.font.caption
    horizontalMargin: 6
    dimmed: !root.available
    active: root.available && root.reading.temperature >= root.warningTemperature
    tooltipText: root.statusTooltip
    onPressed: function(button) { if (button === Qt.LeftButton) root.refresh() }
  }
}
