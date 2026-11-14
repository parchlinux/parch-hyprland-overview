pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "../"

Scope {
    id: overviewScope

    Variants {
        id: overviewVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id === monitor?.id)

            screen: modelData
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "parch-hyprland-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active && canBeActive && GlobalStates.overviewOpen) {
                        GlobalStates.overviewOpen = false;
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen) {
                        delayedGrabTimer.restart();
                    } else {
                        delayedGrabTimer.stop();
                        grab.active = false;
                    }
                }
            }

            Connections {
                target: Hyprland
                function onFocusedMonitorChanged() {
                    if (!GlobalStates.overviewOpen)
                        return;
                    if (root.monitorIsFocused && !grab.active) {
                        grab.active = true;
                    } else if (!root.monitorIsFocused && grab.active) {
                        grab.active = false;
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: 150
                repeat: false
                onTriggered: {
                    if (grab.canBeActive) {
                        grab.active = GlobalStates.overviewOpen;
                    }
                }
            }

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
                opacity: GlobalStates.overviewOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: {
                        GlobalStates.overviewOpen = false;
                    }
                }
            }

            Rectangle {
                id: backgroundCard
                anchors.centerIn: parent
                width: overviewWidget.implicitWidth + 24
                height: overviewWidget.implicitHeight + 24
                radius: Theme.panelrounding
                color: Theme.colBg
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                scale: GlobalStates.overviewOpen ? 1.0 : 0.95
                opacity: GlobalStates.overviewOpen ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: mouse => mouse.accepted = true
                }

                OverviewWidget {
                    id: overviewWidget
                    anchors.centerIn: parent
                    panelWindow: root
                    visible: true
                }
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                focus: GlobalStates.overviewOpen && root.monitorIsFocused

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                        return;
                    }

                    const workspacesPerGroup = 10;
                    const currentId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
                    const currentGroup = Math.floor((currentId - 1) / workspacesPerGroup);
                    const minWorkspaceId = currentGroup * workspacesPerGroup + 1;
                    const maxWorkspaceId = minWorkspaceId + workspacesPerGroup - 1;

                    const rows = 2;
                    const columns = 5;

                    const clampedIndex = Math.max(0, Math.min(workspacesPerGroup - 1, currentId - minWorkspaceId));
                    const currentNormalRow = Math.floor(clampedIndex / columns);
                    const currentNormalColumn = clampedIndex % columns;

                    let targetRow = currentNormalRow;
                    let targetColumn = currentNormalColumn;
                    let targetId = null;

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        targetColumn = (targetColumn - 1 + columns) % columns;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        targetColumn = (targetColumn + 1) % columns;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        targetRow = (targetRow - 1 + rows) % rows;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        targetRow = (targetRow + 1) % rows;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const position = event.key - Qt.Key_0;
                        if (position <= workspacesPerGroup) {
                            targetId = minWorkspaceId + position - 1;
                        }
                    } else if (event.key === Qt.Key_0) {
                        targetId = minWorkspaceId + 9;
                    }

                    if (targetId === null && (
                        event.key === Qt.Key_Left || event.key === Qt.Key_H ||
                        event.key === Qt.Key_Right || event.key === Qt.Key_L ||
                        event.key === Qt.Key_Up || event.key === Qt.Key_K ||
                        event.key === Qt.Key_Down || event.key === Qt.Key_J
                    )) {
                        targetId = minWorkspaceId + targetRow * columns + targetColumn;
                    }

                    if (targetId !== null) {
                        const clampedTarget = Math.max(minWorkspaceId, Math.min(maxWorkspaceId, targetId));
                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${clampedTarget}'})`);
                        event.accepted = true;
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                HyprlandData.updateWindowList();
                GlobalStates.overviewShown = true;
            } else {
                GlobalStates.overviewShown = false;
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
    }
}
