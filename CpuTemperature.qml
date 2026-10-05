import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "omarchy-cpu-temperature"

  property var reading: ({temperature: null, sensors: []})
  readonly property bool available: typeof reading.temperature === "number" && isFinite(reading.temperature)
  readonly property string statusTooltip: {
    if (!available) return "CPU 温度暂不可用"
    var lines = ["CPU 当前最高温度：" + reading.temperature.toFixed(1) + "°C"]
    for (var sensor of reading.sensors)
      lines.push(sensor.label + "：" + sensor.temperature.toFixed(1) + "°C")
    lines.push("每 " + (poll.interval / 1000) + " 秒更新；点击立即刷新")
    return lines.join("\n")
  }

  function refresh() {
    if (!reader.running) reader.running = true
  }

  Component.onCompleted: refresh()
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: reader
    command: ["python3", decodeURIComponent(Qt.resolvedUrl("read-temperature.py").toString().replace(/^file:\/\//, ""))]
    onRunningChanged: {
      if (running) watchdog.restart()
      else watchdog.stop()
    }
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) root.reading = {temperature: null, sensors: []}
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var result = JSON.parse(text)
          root.reading = Array.isArray(result.sensors) ? result : {temperature: null, sensors: []}
        } catch (error) {
          root.reading = {temperature: null, sensors: []}
        }
      }
    }
  }

  Timer {
    id: poll
    interval: Math.max(1000, Number(root.setting("pollInterval", 3000)) || 3000)
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: watchdog
    interval: 5000
    onTriggered: {
      reader.running = false
      root.reading = {temperature: null, sensors: []}
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Stack the unit underneath on narrow vertical bars, including 100°C.
    text: root.available ? Math.round(root.reading.temperature) + (vertical ? "\n°C" : "°C") : "—"
    fontSize: Style.font.caption
    horizontalMargin: 6
    dimmed: !root.available
    active: root.available && root.reading.temperature >= Number(root.setting("warningTemperature", 85))
    tooltipText: root.statusTooltip
    onPressed: function(button) { if (button === Qt.LeftButton) root.refresh() }
  }
}
