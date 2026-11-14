pragma Singleton
import QtQuick
import QtQml

QtObject {
    id: root

    property color colBg: "#121216"
    property color colBgD: "#18181f"
    property color colFg: "#cdd6f4"
    property color colFgD: Qt.rgba(0.77, 0.78, 0.79, 1.0)
    property color colSurfaceContainer: "#1e1e24"
    property color colMuted: "#6c7086"
    property color colMain: "#7aa2f7"
    property color colHover: Qt.rgba(1, 1, 1, 0.08)

    property string fontFamily: "Google Sans"
    property int fontSize: 14

    property int rounding: 16
    property int panelrounding: 20
    property real realScale: 1.0
}
