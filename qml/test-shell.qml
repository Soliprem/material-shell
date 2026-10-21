import QtQuick
import Quickshell
import Quickshell.Services.Mpris

ShellRoot {
    Colors { id: palette }
    SidebarHeader { theme: palette }
    MediaPlayerCard { id: media; theme: palette; players: [] }
    NotificationCenter { theme: palette; notificationModel: ({ values: [] }) }

    SidebarActions {
        id: actions
        width: 304
        height: 112
        theme: palette
        buttonModel: []
        property int toggles: 0
        property int hides: 0
        property var command: []
        onRequestToggleDnd: toggles++
        onRequestHide: hides++
        onRequestCmd: cmd => command = cmd
    }

    Timer {
        interval: 1
        running: true
        onTriggered: {
            function check(ok, message) {
                if (!ok)
                    throw new Error(message)
            }
            const colors = { rawBg: "#102030", fg: "#ffffff", warm: "#ff0000", fresh: "#00ff00", accent: "#0000ff", second: "#888888" }
            palette.apply(JSON.stringify(colors))
            check(palette.rawBg.toString() === colors.rawBg && palette.accent.b === 1, "Palette colors must remain QColor values")
            check(Math.abs(palette.bg.a - 0.6) < 0.01, "Background alpha")
            for (const invalid of ["", "{", "null", "{}", JSON.stringify(Object.assign({}, colors, { rawBg: "#abcdef", fg: "invalid" }))]) {
                palette.apply(invalid)
                check(palette.rawBg.toString() === colors.rawBg && palette.fg.toString() === colors.fg, "Invalid palettes must preserve every color")
            }

            const first = { playbackState: MprisPlaybackState.Paused, trackArtUrl: "", trackTitle: "", trackArtist: "", position: 0, length: 0, canSeek: false, positionSupported: false }
            const second = Object.assign({}, first, { playbackState: MprisPlaybackState.Playing })
            check(media.activePlayer === null, "No media players")
            media.players = [first, second]
            check(media.activePlayer === first, "First player is the default")
            media.selectedPlayer = second
            check(media.activePlayer === second && media.isPlaying, "Selected player and playback binding")
            media.players = [second, first]
            check(media.activePlayer === second, "Selection survives reordering")
            media.players = [first]
            check(media.activePlayer === first && !media.isPlaying, "Removed player falls back")
            media.players = []
            check(media.activePlayer === null, "Last player removed")

            const command = { icon: "x", colorRole: "accent", command: ["echo", "one argument with spaces"] }
            for (const count of [0, 1, 5, 10, 11]) {
                actions.buttonModel = Array(count).fill(command)
                check(actions.canScroll === (count > 10), "Action scrolling threshold")
                for (let i = 0; i < count; i++) {
                    const x = actions.buttonX(i)
                    check(x >= 0, "Action starts within its row")
                    if (!actions.canScroll)
                        check(x + 50 <= actions.width, "Static actions fit")
                }
            }
            const repeater = actions.children[0].contentItem.children.find(child => typeof child.itemAt === "function")
            check(repeater.count === 11 && repeater.itemAt(1).y === 72, "One delegate per action in scrolling columns")
            actions.buttonModel = Array(5).fill(command)
            check(actions.buttonX(0) === 65 && actions.buttonX(3) === 96, "Unequal static rows stay centered")
            actions.buttonModel = [{ icon: "󰂚", colorRole: "second", action: "dnd" }]
            actions.doNotDisturb = true
            check(repeater.itemAt(0).icon === "󰂛" && repeater.itemAt(0).roleColor.toString() === palette.warm.toString(), "DND appearance follows state")
            actions.doNotDisturb = false
            check(repeater.itemAt(0).icon === "󰂚", "DND appearance resets")
            actions.activateButton(command)
            check(actions.hides === 1 && actions.command.join("|") === command.command.join("|"), "Commands preserve argument boundaries")
            actions.activateButton({ action: "dnd" })
            check(actions.toggles === 1 && actions.hides === 1, "DND does not hide the sidebar or launch commands")
            function findArtwork(item) {
                if (item.artUrl !== undefined)
                    return item
                for (const child of item.children) {
                    const found = findArtwork(child)
                    if (found)
                        return found
                }
                return null
            }
            coverCheck.artwork = findArtwork(media)
            media.players = [Object.assign({}, first, { trackArtUrl: coverCheck.red })]
            coverCheck.start()
        }
    }

    Timer {
        id: coverCheck
        interval: 30
        repeat: true
        property var artwork
        property Image previous
        property int step: 0
        readonly property string red: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"><path fill="red" d="M0 0h1v1H0z"/></svg>')
        readonly property string blue: red.replace("red", "blue")

        onTriggered: {
            if (step === 0 && artwork.hasCover && artwork.current.opacity === 1) {
                previous = artwork.current
                media.players = [Object.assign({}, media.activePlayer, { trackArtUrl: blue })]
                step = 1
            } else if (step === 1 && artwork.current !== previous) {
                if (!(artwork.current.opacity < 1 && previous.opacity > 0))
                    throw new Error("Covers must overlap during the crossfade")
                step = 2
            } else if (step === 2 && artwork.current.opacity === 1) {
                if (previous.opacity !== 0)
                    throw new Error("Previous cover must finish fading out")
                for (const url of [red, blue, red])
                    media.players = [Object.assign({}, media.activePlayer, { trackArtUrl: url })]
                step = 3
            } else if (step === 3 && artwork.hasCover && decodeURIComponent(artwork.current.source.toString()) === decodeURIComponent(red)) {
                media.players = []
                if (artwork.hasCover || artwork.children.some(image => image.source.toString() !== ""))
                    throw new Error("Missing artwork must clear both buffers")
                console.log("Shell checks passed")
                Qt.quit()
            }
        }
    }
}
