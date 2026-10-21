import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property var players: Mpris.players.values
    property var selectedPlayer: null
    readonly property var activePlayer: players.includes(selectedPlayer) ? selectedPlayer : (players[0] ?? null)
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    required property Colors theme

    Layout.preferredHeight: playerLayout.implicitHeight + 40
    radius: 24
    color: "#12ffffff"
    border {
        width: 1
        color: "#0effffff"
    }
    visible: root.hasPlayer

    ColumnLayout {
        id: playerLayout

        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Controls.ComboBox {
            id: sourcePicker

            Layout.fillWidth: true
            visible: root.players.length > 1
            model: root.players
            textRole: "identity"
            currentIndex: root.players.indexOf(root.activePlayer)
            onActivated: root.selectedPlayer = root.players[currentIndex]
            Accessible.name: "Media source"
            implicitHeight: 38
            leftPadding: 14
            rightPadding: 38
            hoverEnabled: true

            contentItem: Text {
                text: sourcePicker.displayText
                color: root.theme.second
                font { pixelSize: 12; weight: Font.Medium; letterSpacing: 0.3 }
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: Text {
                x: sourcePicker.width - width - 14
                anchors.verticalCenter: parent.verticalCenter
                text: "⌄"
                font.pixelSize: 18
                color: root.theme.accent
                rotation: sourcePicker.popup.visible ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 160 } }
            }

            background: Rectangle {
                radius: 12
                color: sourcePicker.down ? "#20ffffff" : sourcePicker.hovered ? "#18ffffff" : "#0cffffff"
                border.width: 1
                border.color: sourcePicker.visualFocus ? root.theme.accent : "#0effffff"
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            delegate: Controls.ItemDelegate {
                id: sourceOption
                required property var modelData
                required property int index
                width: sourcePicker.popup.availableWidth
                implicitHeight: 38
                leftPadding: 12
                rightPadding: 12
                text: modelData.identity
                highlighted: sourcePicker.highlightedIndex === index
                hoverEnabled: true

                contentItem: Text {
                    text: sourceOption.text
                    color: sourceOption.index === sourcePicker.currentIndex ? root.theme.accent : root.theme.fg
                    font { pixelSize: 12; weight: Font.Medium }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 9
                    color: sourceOption.highlighted || sourceOption.hovered ? "#18ffffff" : "transparent"
                }
            }

            popup: Controls.Popup {
                y: sourcePicker.height + 6
                width: sourcePicker.width
                padding: 6
                implicitHeight: Math.min(contentItem.implicitHeight + 12, 240)
                margins: 8
                background: Rectangle {
                    radius: 16
                    color: root.theme.rawBg
                    border { width: 1; color: "#20ffffff" }
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sourcePicker.delegateModel
                    currentIndex: sourcePicker.highlightedIndex
                    highlightMoveDuration: 0
                    Controls.ScrollIndicator.vertical: Controls.ScrollIndicator { }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Rectangle {
                id: artContainer

                width: 85
                height: 85
                radius: 20
                color: "#2affffff"
                clip: true
                layer.enabled: true
                layer.samples: 8
                layer.smooth: true

                readonly property int renderScale: 4
                readonly property int renderSize: Math.round(width * renderScale)

                Item {
                    id: artMask

                    width: artContainer.renderSize
                    height: artContainer.renderSize
                    layer.enabled: true
                    layer.samples: 8
                    layer.smooth: true
                    layer.mipmap: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: artContainer.radius * artContainer.renderScale
                        color: "white"
                        antialiasing: true
                    }
                }

                Item {
                    id: artwork

                    width: artContainer.renderSize
                    height: artContainer.renderSize
                    visible: false
                    property Image current: firstCover
                    readonly property string artUrl: root.activePlayer?.trackArtUrl ?? ""
                    readonly property bool hasCover: artUrl !== "" && current.status === Image.Ready

                    onArtUrlChanged: {
                        if (artUrl === "") {
                            firstCover.source = ""
                            secondCover.source = ""
                            return
                        }
                        const next = current === firstCover ? secondCover : firstCover
                        next.source = artUrl
                        if (next.status === Image.Ready)
                            current = next
                    }

                    component CoverImage: Image {
                        anchors.fill: parent
                        sourceSize.width: artContainer.renderSize
                        sourceSize.height: artContainer.renderSize
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        opacity: artwork.current === this ? 1 : 0
                        onStatusChanged: if (status === Image.Ready) artwork.current = this
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }

                    CoverImage { id: firstCover }
                    CoverImage { id: secondCover }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: artwork
                    maskEnabled: true
                    maskSource: artMask
                    maskThresholdMin: 0.35
                    maskThresholdMax: 1.0
                    maskSpreadAtMin: 0.08
                    maskSpreadAtMax: 0.04
                    visible: artwork.hasCover
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎇"
                    color: root.theme.accent
                    opacity: 0.7
                    font.pixelSize: 32
                    visible: !artwork.hasCover
                }

                Rectangle {
                    anchors.fill: parent
                    radius: artContainer.radius
                    color: "transparent"
                    antialiasing: true
                    border {
                        width: 1
                        color: "#33ffffff"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                clip: true

                Text {
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackTitle || "Now playing"
                    color: root.theme.fg
                    elide: Text.ElideRight
                    font {
                        pixelSize: 17
                        weight: Font.Medium
                        letterSpacing: 0.2
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackArtist || "Unknown artist"
                    color: root.theme.second
                    opacity: 0.65
                    elide: Text.ElideRight
                    font {
                        pixelSize: 12
                        letterSpacing: 0.3
                    }
                }
            }
        }

        Rectangle {
            id: progressBar

            Layout.fillWidth: true
            height: progressMouse.containsMouse ? 7 : 4
            radius: 3
            color: progressMouse.containsMouse ? "#2effffff" : "#1cffffff"

            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 160 } }

            Timer {
                interval: 500
                repeat: true
                running: root.isPlaying && root.visible
                onTriggered: root.activePlayer.positionChanged()
            }

            Rectangle {
                width: parent.width * Math.min(1.0, (root.activePlayer && root.activePlayer.length > 0
                    ? root.activePlayer.position / root.activePlayer.length
                    : 0))
                height: parent.height
                radius: parent.radius
                color: root.theme.accent

                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: progressMouse

                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                enabled: root.hasPlayer && root.activePlayer.canSeek && root.activePlayer.positionSupported && root.activePlayer.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: (mouse) => {
                    root.activePlayer.position = Math.max(0, Math.min(1, mouse.x / width)) * root.activePlayer.length
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 48
            spacing: 38

            PlayerIconButton {
                icon: "󰒮"
                theme: root.theme
                onClicked: root.activePlayer?.previous()
            }

            Rectangle {
                width: 48
                height: 48
                radius: 14
                color: root.theme.accent
                scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.06 : 1.0)

                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.38 } }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.isPlaying ? 0 : 2
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    color: root.theme.rawBg
                    opacity: 0.9
                    font.pixelSize: 20
                }

                MouseArea {
                    id: playMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.activePlayer?.togglePlaying()
                }
            }

            PlayerIconButton {
                icon: "󰒭"
                theme: root.theme
                onClicked: root.activePlayer?.next()
            }
        }
    }
}
