pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Column {
    id: root

    required property ShellScreen screen
    required property HyprlandMonitor monitor
    required property real tileWidth
    required property real tileHeight
    required property real spacing

    property bool previewsActive: true

    signal specialClicked(string name)

    readonly property string activeSpecialName: {
        const name = `${monitor?.lastIpcObject?.specialWorkspace?.name ?? ""}`;
        return name.startsWith("special:") ? name : "";
    }

    readonly property var names: {
        const out = [];

        const push = value => {
            let name = `${value ?? ""}`.trim();
            if (name.startsWith("special:"))
                name = name.slice("special:".length);
            if (name.length > 0 && !out.includes(name))
                out.push(name);
        };

        // Configured special workspaces are shown even when they are empty.
        const configured = GlobalConfig.bar.workspaces.specialWorkspaceIcons?.values ?? [];
        for (const entry of configured)
            push(typeof entry === "string" ? entry : entry?.name);

        // Also include special workspaces that currently exist on this monitor.
        for (const ws of Hypr.workspaces.values) {
            if (!ws.name.startsWith("special:"))
                continue;
            if (root.monitor && ws.monitor?.id !== root.monitor.id)
                continue;
            push(ws.name);
        }

        // And special workspaces that only have windows but are not listed.
        for (const toplevel of Hypr.toplevels.values) {
            const name = `${toplevel.workspace?.name ?? ""}`;
            if (!name.startsWith("special:"))
                continue;
            if (root.monitor && toplevel.monitor?.id !== root.monitor.id)
                continue;
            push(name);
        }

        return out;
    }

    function nextSpecialWorkspaceName(): string {
        const taken = new Set(names.map(name => name.toLowerCase()));
        if (!taken.has("stash"))
            return "stash";

        let index = 2;
        while (taken.has(`stash-${index}`))
            index += 1;
        return `stash-${index}`;
    }

    visible: names.length > 0
    spacing: Tokens.spacing.small

    StyledRect {
        width: parent.width
        implicitHeight: 1
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.45)
    }

    RowLayout {
        width: parent.width
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Special workspaces")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
        }

        Item {
            Layout.fillWidth: true
        }

        IconButton {
            type: IconButton.Text
            icon: "add"

            onClicked: root.specialClicked(root.nextSpecialWorkspaceName())
        }
    }

    Grid {
        columns: Math.max(1, Math.min(5, root.names.length))
        rowSpacing: root.spacing
        columnSpacing: root.spacing

        Repeater {
            model: root.names

            SpecialWorkspaceTile {
                required property string modelData

                screen: root.screen
                monitor: root.monitor
                specialName: modelData
                tileWidth: root.tileWidth
                tileHeight: root.tileHeight
                previewsActive: root.previewsActive
                active: root.activeSpecialName === `special:${modelData}`

                onClicked: root.specialClicked(specialName)
            }
        }
    }
}
