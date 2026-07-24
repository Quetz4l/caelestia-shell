pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    readonly property bool enabled: true
    readonly property bool safeMode: true
    readonly property bool mischiefEnabled: true
    readonly property int mischiefLevel: 2
    readonly property string homePosition: "bottom-left"
    readonly property int frameInterval: 16
    readonly property real breatheSpeed: 0.028
    readonly property real tailSpeed: 0.038
    readonly property int cursorPollInterval: 60
    readonly property int idleCursorPollInterval: 180
    readonly property int activeWindowPollInterval: 1600
    readonly property int firstAttentionDelay: 45000
    readonly property int attentionInterval: 70000
    readonly property int chewDuration: 9000
    readonly property int lickDuration: 8000
    readonly property int attentionDuration: 9000
    readonly property int chewCooldown: 600000
    readonly property int walkDuration: 4200
}
