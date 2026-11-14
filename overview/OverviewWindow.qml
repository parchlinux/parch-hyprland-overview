import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "."
import "../"

Item {
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var widgetMonitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property real positionBaseX: (monitorData?.x ?? 0) + (monitorData?.reserved?.[0] ?? 0)
    property real positionBaseY: (monitorData?.y ?? 0) + (monitorData?.reserved?.[1] ?? 0)
    property int recaptureToken: 0
    property bool restrictToWorkspace: true
    property real widthRatio: {
        if (!widgetMonitorData || !monitorData)
            return 1;

        const widgetWidth = (widgetMonitorData.transform % 2 === 1) ? (widgetMonitorData.height ?? 1) : (widgetMonitorData.width ?? 1);
        const sourceWidth = (monitorData.transform % 2 === 1) ? (monitorData.height ?? 1) : (monitorData.width ?? 1);
        const sourceScale = monitorData.scale ?? 1;
        const widgetScale = widgetMonitorData.scale ?? 1;
        return (widgetWidth * sourceScale) / (sourceWidth * widgetScale);
    }
    property real heightRatio: {
        if (!widgetMonitorData || !monitorData)
            return 1;
        const widgetHeight = (widgetMonitorData.transform % 2 === 1) ? (widgetMonitorData.width ?? 1) : (widgetMonitorData.height ?? 1);
        const sourceHeight = (monitorData.transform % 2 === 1) ? (monitorData.width ?? 1) : (monitorData.height ?? 1);
        const sourceScale = monitorData.scale ?? 1;
        const widgetScale = widgetMonitorData.scale ?? 1;
        return (widgetHeight * sourceScale) / (sourceHeight * widgetScale);
    }
    property real workspaceMargin: 2
    property real initX: Math.min(Math.max(((windowData?.at[0] ?? 0) - positionBaseX) * root.scale * geometryScaleX, workspaceMargin),Math.max(workspaceMargin, availableWorkspaceWidth - targetWindowWidth - workspaceMargin)) + xOffset
    property real initY: Math.min(Math.max(((windowData?.at[1] ?? 0) - positionBaseY) * root.scale * geometryScaleY, workspaceMargin),Math.max(workspaceMargin, availableWorkspaceHeight - targetWindowHeight - workspaceMargin)) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    property int widgetMonitorId: 0
    property real geometryScaleX: widthRatio
    property real geometryScaleY: heightRatio

    property var targetWindowWidth: (windowData?.size[0] ?? 100) * scale * geometryScaleX
    property var targetWindowHeight: (windowData?.size[1] ?? 100) * scale * geometryScaleY
    property bool hovered: false
    property bool pressed: false

    property bool previewCaptureEnabled: true
    property bool shouldCapturePreview: {
        if (!GlobalStates.overviewShown || !previewCaptureEnabled)
            return false;
        return (windowData?.monitor ?? -1) === widgetMonitorId;
    }

    Connections {
        target: GlobalStates
        function onOverviewShownChanged() {
            if (GlobalStates.overviewShown) {
                root.previewCaptureEnabled = true;
            } else {
                recoveryTimer.stop();
                root.previewCaptureEnabled = true;
            }
        }
    }
    property var entry: {
        DesktopEntries.applications.values;
        return DesktopEntries.heuristicLookup(windowData?.class);
    }
    property string iconName: {
        const raw = `${entry?.icon ?? ""}`.trim();
        const withoutProviderPrefix = raw.replace(/^image:\/\/icon\//, "");
        const withoutQuery = withoutProviderPrefix.split("?")[0].trim();
        return withoutQuery.length > 0 ? withoutQuery : "application-x-executable";
    }
    property var iconPath: Quickshell.iconPath(iconName, "image-missing")

    property bool indicateXWayland: windowData?.xwayland ?? false
    property bool initialized: false
    property bool dragInProgress: false
    property bool suspendPositionAnimation: false
    property bool animateSize: true

    x: initX
    y: initY
    width: Math.min(targetWindowWidth, availableWorkspaceWidth)
    height: Math.min(targetWindowHeight, availableWorkspaceHeight)
    opacity: (windowData?.monitor ?? -1) == widgetMonitorId ? 1 : 0.6
    visible: {
        const thisWsId = windowData?.workspace?.id;
        const isFullscreen = (windowData?.fullscreen ?? 0) > 0;
        if (isFullscreen || thisWsId === undefined) return true;
        return !HyprlandData.windowList.some(w => w.workspace?.id === thisWsId && (w.fullscreen ?? 0) > 0);
    }

    clip: true
    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    Behavior on x {
        enabled: root.initialized && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        enabled: root.initialized && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
    Behavior on width {
        enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        visible: (root.windowData?.monitor ?? -1) === root.widgetMonitorId
        anchors.fill: parent
        radius: Theme.rounding
        color: Theme.colBg
    }

    Item {
        id: previewContainer
        readonly property real srcAspect: {
            const w = root.windowData?.size?.[0] ?? 0;
            const h = root.windowData?.size?.[1] ?? 0;
            return (w > 0 && h > 0) ? (w / h) : 1;
        }

        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height * srcAspect)
        height: Math.min(parent.height, parent.width / srcAspect)

        Behavior on width {
            enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.live: windowPreview.hasContent
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: previewMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        ScreencopyView {
            id: windowPreview
            anchors.fill: parent
            captureSource: root.shouldCapturePreview ? root.toplevel : null
            live: GlobalStates.overviewShown
            onHasContentChanged: {
                if (!hasContent && GlobalStates.overviewShown && root.previewCaptureEnabled) {
                    recoveryTimer.restart();
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding
        color: hovered ? Theme.colHover : "transparent"
        border.color: Theme.colBg
        border.width: 1

        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2
            Image {
                id: windowIcon
                property var iconSize: {
                    const renderedSize = Math.min(root.width, root.height);
                    return renderedSize * 0.25 / (root.monitorData?.scale ?? 1);
                }
                Layout.alignment: Qt.AlignHCenter
                source: root.iconPath
                width: iconSize
                height: iconSize
                sourceSize: Qt.size(Math.max(1, Math.round(iconSize)), Math.max(1, Math.round(iconSize)))
            }
        }
    }

    Item {
        id: previewMask
        width: previewContainer.width
        height: previewContainer.height
        anchors.centerIn: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        Rectangle {
            anchors.centerIn: parent
            width: root.width
            height: root.height
            radius: Theme.rounding
        }
    }

    function refreshCapture() {
        if (!GlobalStates.overviewShown)
            return;
        recoveryTimer.restart();
    }

    Timer {
        id: recoveryTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (GlobalStates.overviewShown && !windowPreview.hasContent) {
                root.previewCaptureEnabled = false;
                HyprlandData.updateWindowList();
                recoveryTimer.restart();
            }
        }
    }
}
