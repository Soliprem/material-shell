import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property color fg: "#ffffff"
    readonly property color bg: Qt.rgba(rawBg.r, rawBg.g, rawBg.b, 0.6)
    property color rawBg: "#000000"
    property color accent: "#ffffff"
    property color second: "#ffffff"
    property color warm: "#ffffff"
    property color fresh: "#ffffff"

    function colorFilePath() {
        const cacheHome = Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"
        return cacheHome + "/quickshell/colors.json"
    }

    function reload() {
        colorFile.reload()
    }

    function apply(rawColors) {
        try {
            const c = JSON.parse(rawColors)
            const keys = ["rawBg", "fg", "warm", "fresh", "accent", "second"]
            if (!keys.every(key => /^#[0-9a-f]{6}$/i.test(c?.[key])))
                return

            for (const key of keys)
                root[key] = c[key]
        } catch (e) {}
    }

    FileView {
        id: colorFile

        path: root.colorFilePath()
        watchChanges: true
        preload: true
        printErrors: false

        onLoaded: root.apply(text())
        onFileChanged: reload()
    }
}
