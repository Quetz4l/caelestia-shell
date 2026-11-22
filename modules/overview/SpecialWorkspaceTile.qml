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
    required property string specialName
    required property real tileWidth
    required property real tileHeight

    property bool active: false
    property bool previewsActive: true

    signal clicked()

    readonly property string selector: `special:${specialName}`
    readonly property string displayName: specialName.replace(/[-_]+/g, " ")
    readonly property var toplevels: Hypr.toplevelsForWs(selector, GlobalConfig.bar.workspaces.ignoredTags).filter(t => t.monitor?.id === monitor?.id)
    readonly property bool occupied: toplevels.length > 0
    readonly property string iconName: {
        const configured = GlobalConfig.bar.workspaces.specialWorkspaceIcons?.values ?? [];
        for (const entry of configured) {
            const name = typeof entry === "string" ? entry : entry?.name;
            if (name === specialName)
                return `${entry?.icon ?? "star"}`;
        }
        return "star";
    }

    implicitWidth: tileWidth
    implicitHeight: tileHeight

    StyledClippingRect {
        id: tile

        anchors.fill: parent
        color: root.active ? Qt.alpha(Colours.palette.m3tertiaryContainer, 0.90) : Qt.alpha(Colours.palette.m3surfaceContainer, 0.95)
        radius: Tokens.rounding.large
        contentInsideBorder: false
        border.width: root.active ? 2 : 1
        border.color: root.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

        StyledText {
            anchors.centerIn: parent
            width: parent.width - Tokens.padding.large * 2
            text: root.displayName
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.14
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font: Tokens.font.headline.builders.small.size(Math.max(14, Math.round(root.tileHeight * (root.displayName.length > 8 ? 0.25 : 0.34)))).weight(Font.Bold).build()
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
                fitToTile: true
            }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Tokens.spacing.small
            z: 2

            implicitWidth: label.implicitWidth + Tokens.padding.small * 2
            implicitHeight: label.implicitHeight + Tokens.padding.extraSmall * 2

            color: Qt.alpha(Colours.palette.m3inverseSurface, 0.88)
            radius: Tokens.rounding.full

            Row {
                id: label

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.iconName
                    color: Colours.palette.m3inverseOnSurface
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayName
                    color: Colours.palette.m3inverseOnSurface
                    font: Tokens.font.body.small
                }
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
