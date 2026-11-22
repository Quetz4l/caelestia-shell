pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandMonitor monitor
    required property int workspaceId
    required property real tileWidth
    required property real tileHeight

    property bool selected: false
    property bool active: false
    property bool previewsActive: true

    signal clicked()

    readonly property var toplevels: Hypr.toplevelsForWs(workspaceId, GlobalConfig.bar.workspaces.ignoredTags).filter(t => t.monitor?.id === monitor?.id)
    readonly property bool occupied: toplevels.length > 0

    implicitWidth: tileWidth
    implicitHeight: tileHeight

    StyledClippingRect {
        id: tile

        anchors.fill: parent
        color: root.active ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.90) : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.95)
        radius: Tokens.rounding.large
        contentInsideBorder: false
        border.width: root.selected ? 3 : root.active ? 2 : 1
        border.color: root.selected || root.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

        StyledText {
            anchors.centerIn: parent
            text: root.workspaceId
            opacity: 0.14
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font: Tokens.font.headline.builders.large.size(Math.max(18, Math.round(root.tileHeight * 0.55))).weight(Font.Bold).build()
        }

        Repeater {
            model: root.toplevels

            WindowPreview {
                required property var modelData

                toplevel: modelData
                monitor: root.monitor
                tileWidth: root.tileWidth
                tileHeight: root.tileHeight
                previewsActive: root.previewsActive
            }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Tokens.spacing.small
            z: 2

            implicitWidth: numberLabel.implicitWidth + Tokens.padding.small * 2
            implicitHeight: numberLabel.implicitHeight + Tokens.padding.extraSmall * 2

            color: Qt.alpha(Colours.palette.m3inverseSurface, 0.88)
            radius: Tokens.rounding.full

            StyledText {
                id: numberLabel

                anchors.centerIn: parent
                text: root.workspaceId
                color: Colours.palette.m3inverseOnSurface
                font: Tokens.font.body.medium
            }
        }

        StyledRect {
            visible: root.occupied
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.spacing.small
            z: 2

            implicitWidth: windowCount.implicitWidth + Tokens.padding.small * 2
            implicitHeight: windowCount.implicitHeight + Tokens.padding.extraSmall * 2

            color: Qt.alpha(Colours.palette.m3inverseSurface, 0.88)
            radius: Tokens.rounding.full

            StyledText {
                id: windowCount

                anchors.centerIn: parent
                text: root.toplevels.length
                color: Colours.palette.m3inverseOnSurface
                font: Tokens.font.body.small
            }
        }

        StyledRect {
            visible: root.active
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.spacing.small
            z: 2

            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            color: Colours.palette.m3primary
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3onSurface, mouse.containsMouse ? 0.06 : 0)
            radius: tile.radius
            z: 1
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
