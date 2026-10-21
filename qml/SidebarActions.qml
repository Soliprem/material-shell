import QtQuick

Item {
    id: root

    required property var buttonModel
    required property Colors theme
    property bool doNotDisturb: false
    readonly property int buttonSize: 50
    readonly property int buttonSpacing: 12
    readonly property int buttonCount: buttonModel.length
    readonly property int topRowCount: Math.ceil(buttonCount / 2)
    readonly property bool canScroll: buttonCount > 10

    signal requestCmd(var cmdArray)
    signal requestHide()
    signal requestToggleDnd()

    function buttonX(index) {
        if (canScroll)
            return Math.floor(index / 2) * (buttonSize + buttonSpacing)

        const start = index < topRowCount ? 0 : topRowCount
        const count = start === 0 ? topRowCount : buttonCount - topRowCount
        const rowWidth = count * buttonSize + (count - 1) * buttonSpacing
        return (width - rowWidth) / 2 + (index - start) * (buttonSize + buttonSpacing)
    }

    function activateButton(action) {
        if (action.action === "dnd") {
            requestToggleDnd()
        } else {
            requestHide()
            requestCmd(action.command)
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: -10
        anchors.rightMargin: -4
        clip: true
        interactive: root.canScroll
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        maximumFlickVelocity: 800
        flickDeceleration: 2500
        pixelAligned: true
        contentWidth: root.canScroll
            ? root.topRowCount * (root.buttonSize + root.buttonSpacing) - root.buttonSpacing + 20
            : width
        contentHeight: height

        Repeater {
            model: root.buttonModel

            delegate: SidebarActionButton {
                required property var modelData
                required property int index
                readonly property bool isDnd: modelData.action === "dnd"

                x: 10 + root.buttonX(index)
                y: 10 + (root.canScroll ? index % 2 : (index < root.topRowCount ? 0 : 1))
                    * (root.buttonSize + root.buttonSpacing)
                icon: isDnd && root.doNotDisturb ? "󰂛" : modelData.icon
                roleColor: isDnd && root.doNotDisturb ? root.theme.warm : root.theme[modelData.colorRole]
                theme: root.theme

                onClicked: root.activateButton(modelData)
            }
        }
    }
}
