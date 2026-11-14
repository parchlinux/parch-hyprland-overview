pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    property bool overviewOpen: false
    property bool overviewShown: false
    property bool superReleaseMightTrigger: true
    property bool overviewOpenedByMouse: false
    property bool pointerInOverview: false
    property bool pointerInHotspot: false
}
