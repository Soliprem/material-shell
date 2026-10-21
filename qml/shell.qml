import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    Colors { id: colors }

    NotificationDaemon {
        id: notificationDaemon
    }

    // ── IPC ──

    IpcHandler {
        target: "sidebar"
        function toggle() { sidebarWindow.visible = !sidebarWindow.visible }
    }

    IpcHandler {
        target: "theme_manager"
        function update() { colors.reload() }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd() { notificationDaemon.toggleDoNotDisturb() }
        function clear() { notificationDaemon.clearNotifications() }
    }

    // ── sidebar buttons ──

    readonly property var actions: [
        { icon: "󰍜", colorRole: "second", command: ["fuzzel"] },
        { icon: "󱙓", colorRole: "second", command: ["nixrice"] },
        { icon: "󰌁", colorRole: "warm", command: ["rice-style", "cyberpunk"] },
        { icon: "󰂯", colorRole: "second", command: ["foot", "bluetui"] },
        { icon: "󰖩", colorRole: "accent", command: ["foot", "nmtui"] },
        { icon: "󰏘", colorRole: "accent", command: ["color-mode"] },
        { icon: "󰂚", colorRole: "second", action: "dnd" },
        { icon: "󰤆", colorRole: "second", command: ["wlogout"] },
        { icon: "󰄨", colorRole: "second", command: ["foot", "btop"] },
        { icon: "󰕾", colorRole: "accent", command: ["foot", "wiremix"] },
        { icon: "󰔎", colorRole: "accent", command: ["toggle-polarity"] }
    ]

    // ── sidebar window ──

    PanelWindow {
        id: sidebarWindow
        WlrLayershell.namespace: "quickshell-sidebar"
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; bottom: true; right: true }
        margins { top: 10; bottom: 10; right: 10 }
        implicitWidth: 360
        visible: false
        color: "transparent"

        BackgroundEffect.blurRegion: Region {
            item: sidebarWindow.contentItem
            radius: 15
        }

        Rectangle {
            anchors.fill: parent
            radius: 15
            color:  colors.bg
            clip:   true

            SidebarContent {
                anchors.fill: parent
                visible: sidebarWindow.visible

                theme: colors

                buttonModel: root.actions
                doNotDisturb: notificationDaemon.doNotDisturb
                notificationModel: notificationDaemon.trackedNotifications

                onRequestCmd: (cmd) => Quickshell.execDetached(cmd)
                onRequestHide:       sidebarWindow.visible = false
                onRequestDismissNotification: (notification) => notificationDaemon.dismissNotification(notification)
                onRequestClearNotifications: notificationDaemon.clearNotifications()
                onRequestToggleDnd: notificationDaemon.toggleDoNotDisturb()
            }
        }
    }

    NotificationPopupStack {
        notificationModel: notificationDaemon.popupNotifications
        theme: colors

        onDismissNotification: (notification) => notificationDaemon.dismissNotification(notification)
        onHidePopup: (notification) => notificationDaemon.hidePopup(notification)
    }

}
