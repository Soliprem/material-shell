import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Colors theme
    property string batteryPercent: ""
    property string batteryIcon: ""

    Process {
        id: batteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const capacity = parseInt(lines[0])
                if (!Number.isFinite(capacity))
                    return

                root.batteryPercent = capacity + "%"
                root.batteryIcon = lines[1] === "Charging" ? "󰂄"
                    : capacity > 90 ? "󰁹" : capacity > 70 ? "󰂀"
                    : capacity > 40 ? "󰁾" : capacity > 10 ? "󰁼" : "󰂎"
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: batteryProcess.running = true
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Layout.alignment: Qt.AlignLeft
    spacing: 4

    Text {
        text: Qt.formatTime(clock.date, "hh:mm")

        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: -6
        horizontalAlignment: Text.AlignLeft
        color: root.theme.accent
        font {
            pixelSize: 72
            weight: Font.ExtraLight
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        spacing: 14

        Text {
            text: Qt.formatDate(clock.date, "dddd, d MMMM").toUpperCase()
            color: root.theme.second
            font {
                pixelSize: 11
                weight: Font.Medium
                letterSpacing: 0.2
            }
        }

        Text {
            visible: root.batteryPercent !== ""
            text: root.batteryIcon + " " + root.batteryPercent
            color: root.theme.accent
            font {
                pixelSize: 11
                weight: Font.Bold
            }
        }
    }
}
