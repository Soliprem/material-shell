import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Colors theme

    property bool doNotDisturb

    required property var buttonModel
    required property var notificationModel

    signal requestCmd(var cmdArray)
    signal requestHide()
    signal requestDismissNotification(var notification)
    signal requestClearNotifications()
    signal requestToggleDnd()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 32

        SidebarHeader {
            Layout.fillWidth: true
            theme: root.theme
        }

        SidebarActions {
            Layout.fillWidth: true
            Layout.preferredHeight: 112

            buttonModel: root.buttonModel
            doNotDisturb: root.doNotDisturb
            theme: root.theme

            onRequestCmd: (cmd) => root.requestCmd(cmd)
            onRequestHide: root.requestHide()
            onRequestToggleDnd: root.requestToggleDnd()
        }

        MediaPlayerCard {
            id: mediaCard

            Layout.fillWidth: true

            theme: root.theme
        }

        NotificationCenter {
            id: notificationCenter

            Layout.fillWidth: true
            Layout.fillHeight: expanded
            Layout.preferredHeight: expanded ? 0 : collapsedHeight

            notificationModel: root.notificationModel
            collapsedHeight: mediaCard.visible ? mediaCard.height + 24 : 220
            theme: root.theme

            onDismissNotification: (notification) => root.requestDismissNotification(notification)
            onClearRequested: root.requestClearNotifications()
        }

        Item { Layout.fillHeight: !notificationCenter.expanded }
    }
}
