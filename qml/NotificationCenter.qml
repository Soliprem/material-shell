import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var notificationModel
    property bool expanded: false
    property real collapsedHeight: 240
    required property Colors theme

    readonly property int notificationCount: orderedNotifications.length
    readonly property var orderedNotifications:
        [...notificationModel.values].reverse()

    signal dismissNotification(var notification)
    signal clearRequested()

    radius: 18
    color: Qt.rgba(1, 1, 1, 0.045)
    border {
        width: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }
    visible: notificationCount > 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: root.theme.fg
                font {
                    pixelSize: 13
                    weight: Font.Bold
                }
            }

            Rectangle {
                Layout.preferredWidth: Math.max(24, countText.implicitWidth + 12)
                Layout.preferredHeight: 22
                radius: 8
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.16)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.notificationCount
                    color: root.theme.accent
                    font {
                        pixelSize: 10
                        weight: Font.Bold
                    }
                }
            }

            TextButton {
                label: root.expanded ? "Show less" : "Show more"
                textColor: root.theme.accent
                onClicked: root.expanded = !root.expanded
            }

            TextButton {
                label: "Clear"
                textColor: root.theme.second
                onClicked: root.clearRequested()
            }
        }

        ListView {
            id: notificationList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: root.orderedNotifications
            cacheBuffer: 0
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: NotificationCard {
                required property var modelData

                width: ListView.view.width
                notification: modelData
                compact: !root.expanded
                theme: root.theme

                onDismissRequested: (notification) => root.dismissNotification(notification)
            }
        }
    }
}
