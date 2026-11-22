pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property var toplevel
    required property HyprlandMonitor monitor
    required property real tileWidth
    required property real tileHeight
    property bool previewsActive: true
    property bool fitToTile: false

    readonly property var ipc: toplevel?.lastIpcObject ?? null
    readonly property var monitorIpc: monitor?.lastIpcObject ?? null
    readonly property var reserved: monitorIpc?.reserved ?? [0, 0, 0, 0]
    readonly property real monitorWidth: Math.max(1, (monitor?.width ?? 1) / (monitor?.scale ?? 1) - reserved[0] - reserved[2])
    readonly property real monitorHeight: Math.max(1, (monitor?.height ?? 1) / (monitor?.scale ?? 1) - reserved[1] - reserved[3])
    readonly property real baseX: (monitorIpc?.x ?? 0) + reserved[0]
    readonly property real baseY: (monitorIpc?.y ?? 0) + reserved[1]
    readonly property real fitScale: Math.min(tileWidth / monitorWidth, tileHeight / monitorHeight)
    readonly property real contentWidth: monitorWidth * fitScale
    readonly property real contentHeight: monitorHeight * fitScale
    readonly property real contentX: Math.max(0, (tileWidth - contentWidth) / 2)
    readonly property real contentY: Math.max(0, (tileHeight - contentHeight) / 2)
    readonly property real scaleX: fitToTile ? fitScale : tileWidth / monitorWidth
    readonly property real scaleY: fitToTile ? fitScale : tileHeight / monitorHeight

    x: (fitToTile ? contentX : 0) + ((ipc?.at?.[0] ?? 0) - baseX) * scaleX
    y: (fitToTile ? contentY : 0) + ((ipc?.at?.[1] ?? 0) - baseY) * scaleY
    width: Math.max(1, (ipc?.size?.[0] ?? 1) * scaleX)
    height: Math.max(1, (ipc?.size?.[1] ?? 1) * scaleY)

    visible: !(ipc?.hidden ?? false)
    clip: true
    color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.95)
    radius: Math.max(2, Math.round(Tokens.rounding.small * 0.18))
    contentInsideBorder: false
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.35)

    ScreencopyView {
        anchors.fill: parent
        captureSource: root.previewsActive ? (root.toplevel?.wayland ?? null) : null
        live: root.previewsActive
    }

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.08)
        radius: root.radius
    }
}
