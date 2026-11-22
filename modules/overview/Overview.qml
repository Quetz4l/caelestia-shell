pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services

Scope {
    id: root

    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int workspaceCount: columns * rows

    readonly property HyprlandMonitor monitor: Hypr.focusedMonitor
    readonly property int activeWorkspaceId: Math.max(1, monitor?.activeWorkspace?.id ?? 1)
    readonly property int firstWorkspaceId: groupStart(selectedWorkspaceId > 0 ? selectedWorkspaceId : activeWorkspaceId)

    property bool opened: false
    // True while the overview was opened through the Super+Tab flow. In that
    // flow releasing Super commits the selection (Alt-Tab style).
    property bool superHeld: false
    // Workspace highlighted by keyboard navigation. -1 follows the active one.
    property int selectedWorkspaceId: -1

    // The overview is modal: while it is open a dedicated Hyprland submap is
    // active, so SUPER+mouse binds (drag/resize) do not steal clicks from the
    // workspace tiles. Escape is also handled by that submap and resets it.
    onOpenedChanged: Hypr.setSubmap(opened ? "overview" : "reset")
    Component.onDestruction: Hypr.setSubmap("reset")

    function groupStart(id: int): int {
        if (id < 1)
            return 1;
        return Math.floor((id - 1) / workspaceCount) * workspaceCount + 1;
    }

    function show(): void {
        opened = true;
        superHeld = false;
        selectedWorkspaceId = -1;
    }

    function hide(): void {
        opened = false;
        superHeld = false;
        selectedWorkspaceId = -1;
    }

    function toggle(): void {
        if (opened)
            hide();
        else
            show();
    }

    function goToWorkspace(id: int): void {
        hide();
        if (id > 0)
            Hypr.focusWorkspace(id);
    }

    function commitSelection(): void {
        const id = selectedWorkspaceId;
        hide();
        if (id > 0)
            Hypr.focusWorkspace(id);
    }

    // Alt-Tab style cycling: the first call opens the overview and selects the
    // next workspace, every following call advances the selection.
    function cycle(direction: int): void {
        if (!opened) {
            opened = true;
            selectedWorkspaceId = activeWorkspaceId;
        }

        superHeld = true;

        const current = selectedWorkspaceId > 0 ? selectedWorkspaceId : activeWorkspaceId;
        const base = groupStart(current);
        const index = Math.max(0, Math.min(workspaceCount - 1, current - base));
        selectedWorkspaceId = base + (index + direction + workspaceCount) % workspaceCount;
    }

    function moveSelection(key: int, shift: bool): void {
        const current = selectedWorkspaceId > 0 ? selectedWorkspaceId : activeWorkspaceId;
        const base = groupStart(current);
        let index = Math.max(0, Math.min(workspaceCount - 1, current - base));
        let row = Math.floor(index / columns);
        let column = index % columns;

        // Tab / Shift+Tab behave like the compositor bind would.
        if (key === Qt.Key_Tab || key === Qt.Key_Backtab) {
            const direction = key === Qt.Key_Backtab || shift ? -1 : 1;
            index = (index + direction + workspaceCount) % workspaceCount;
        } else if (key === Qt.Key_Left || key === Qt.Key_H) {
            column = (column - 1 + columns) % columns;
            index = row * columns + column;
        } else if (key === Qt.Key_Right || key === Qt.Key_L) {
            column = (column + 1) % columns;
            index = row * columns + column;
        } else if (key === Qt.Key_Up || key === Qt.Key_K) {
            row = (row - 1 + rows) % rows;
            index = row * columns + column;
        } else if (key === Qt.Key_Down || key === Qt.Key_J) {
            row = (row + 1) % rows;
            index = row * columns + column;
        } else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
            index = Math.min(workspaceCount - 1, key - Qt.Key_1);
        } else if (key === Qt.Key_0 && workspaceCount >= 10) {
            index = 9;
        } else {
            return;
        }

        const target = base + index;
        selectedWorkspaceId = target;

        // If the overview was opened without holding Super, navigating should
        // switch immediately instead of waiting for a Super release that will
        // never arrive.
        if (!superHeld)
            goToWorkspace(target);
    }

    Variants {
        model: Screens.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property HyprlandMonitor monitor: Hypr.monitorFor(modelData)
            readonly property bool focused: !!monitor && monitor.id === root.monitor?.id

            screen: modelData
            visible: root.opened && focused

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            WlrLayershell.namespace: "caelestia-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                windows: [win]
                active: win.visible

                onCleared: {
                    if (root.opened)
                        root.hide();
                }
            }

            Connections {
                target: root

                function onOpenedChanged(): void {
                    if (root.opened && win.focused)
                        Qt.callLater(() => keyHandler.forceActiveFocus());
                }
            }

            FocusScope {
                id: keyHandler

                anchors.fill: parent
                focus: true
                z: 3

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                        root.superHeld = true;
                        event.accepted = true;
                        return;
                    }

                    if (event.key === Qt.Key_Escape) {
                        root.hide();
                        event.accepted = true;
                        return;
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.commitSelection();
                        event.accepted = true;
                        return;
                    }

                    const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_H || event.key === Qt.Key_J || event.key === Qt.Key_K || event.key === Qt.Key_L || (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)) {
                        root.moveSelection(event.key, shift);
                        event.accepted = true;
                    }
                }

                Keys.onReleased: event => {
                    // Releasing Super jumps to the highlighted workspace, just
                    // like Alt-Tab commits the selected window.
                    if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                        root.superHeld = false;
                        if (root.selectedWorkspaceId > 0)
                            root.commitSelection();
                        event.accepted = true;
                    }
                }

                Component.onCompleted: {
                    if (win.visible)
                        forceActiveFocus();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Colours.palette.m3scrim
                opacity: 0.55
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: root.hide()
            }

            StyledRect {
                id: panel

                readonly property real tileSpacing: Tokens.spacing.medium
                readonly property real sideMargin: Math.max(Tokens.padding.extraLargeIncreased * 2, win.width * 0.06)
                readonly property real tileWidth: Math.floor(Math.min(300, (win.width - sideMargin * 2 - tileSpacing * (root.columns - 1)) / root.columns))
                readonly property real tileHeight: Math.round(tileWidth * Math.min(1.2, win.height / Math.max(1, win.width)))
                readonly property real specialTileHeight: Math.max(90, Math.round(tileHeight * 0.8))

                anchors.centerIn: parent
                implicitWidth: content.implicitWidth + Tokens.padding.extraLargeIncreased * 2
                implicitHeight: content.implicitHeight + Tokens.padding.extraLargeIncreased * 2

                color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.97)
                radius: Tokens.rounding.extraLarge
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: {}
                }

                Column {
                    id: content

                    anchors.centerIn: parent
                    width: grid.width
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        width: parent.width
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: Tr.tr("Workspaces")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.headline.small
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: `${root.firstWorkspaceId} – ${root.firstWorkspaceId + root.workspaceCount - 1}`
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.medium
                        }
                    }

                    Grid {
                        id: grid

                        columns: root.columns
                        rowSpacing: panel.tileSpacing
                        columnSpacing: panel.tileSpacing

                        Repeater {
                            model: root.workspaceCount

                            WorkspaceTile {
                                required property int index

                                screen: win.modelData
                                monitor: win.monitor
                                workspaceId: root.firstWorkspaceId + index
                                tileWidth: panel.tileWidth
                                tileHeight: panel.tileHeight
                                selected: root.selectedWorkspaceId === workspaceId
                                active: root.activeWorkspaceId === workspaceId
                                previewsActive: win.visible

                                onClicked: root.goToWorkspace(workspaceId)
                            }
                        }
                    }

                    SpecialWorkspaceSection {
                        width: parent.width

                        screen: win.modelData
                        monitor: win.monitor
                        tileWidth: panel.tileWidth
                        tileHeight: panel.specialTileHeight
                        spacing: panel.tileSpacing
                        previewsActive: win.visible

                        onSpecialClicked: name => {
                            root.hide();
                            Hypr.toggleSpecial(name);
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: Tr.tr("Tab / Shift+Tab to cycle")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: root.superHeld ? Tr.tr("Release Super to switch") : Tr.tr("Enter to switch · Esc to close")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }
                }
            }
        }
    }

    // Compositor binds (Super+Tab / Super+Shift+Tab) use these, so repeated
    // Tab presses advance the selection while Super is held.
    CustomShortcut {
        name: "overviewCycle"
        description: "Cycle workspace overview selection"
        onPressed: root.cycle(1)
    }

    CustomShortcut {
        name: "overviewCycleBack"
        description: "Cycle workspace overview selection backwards"
        onPressed: root.cycle(-1)
    }

    CustomShortcut {
        name: "overview"
        description: "Toggle workspace overview"
        onPressed: root.toggle()
    }

    CustomShortcut {
        name: "overviewCancel"
        description: "Cancel workspace overview"
        onPressed: root.hide()
    }

    IpcHandler {
        target: "overview"

        function open(): void {
            root.show();
        }

        function close(): void {
            root.hide();
        }

        function toggle(): void {
            root.toggle();
        }

        function cycle(): void {
            root.cycle(1);
        }

        function cycleBack(): void {
            root.cycle(-1);
        }

        function isOpen(): string {
            return root.opened ? "1" : "0";
        }
    }
}
