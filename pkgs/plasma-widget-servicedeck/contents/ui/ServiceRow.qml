import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: rowRoot
    Layout.fillWidth: true
    implicitHeight: contentRow.implicitHeight + Kirigami.Units.smallSpacing * 2
    color: mouseArea.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
    radius: Kirigami.Units.cornerRadius

    property string serviceId: ""
    property string displayId: ""
    property string serviceName: ""
    property string scope: "user"
    property bool isAdmin: (scope === "system")
    property bool isActive: false
    property string activeState: "inactive"
    property string subState: "dead"
    property bool isEnabled: false
    property string unitState: "disabled"
    property string statusColor: "#7f8c8d"

    signal actionRequested(string action, string scope, string serviceId)

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing / 2
        anchors.bottomMargin: Kirigami.Units.smallSpacing / 2
        spacing: Kirigami.Units.mediumSpacing

        // 1. Color Status Dot
        Rectangle {
            id: statusDot
            width: 10
            height: 10
            radius: 5
            color: rowRoot.statusColor
            Layout.alignment: Qt.AlignVCenter
            
            border.color: Qt.darker(rowRoot.statusColor, 1.2)
            border.width: 1
        }

        // 2. Service Identity (Title + Admin Indicator & Filename/State Subtitle)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: rowRoot.serviceName
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    elide: Text.ElideRight
                    Layout.maximumWidth: rowRoot.width - (rowRoot.isAdmin ? 220 : 170)
                }

                // Admin / Root Permission Indicator
                Rectangle {
                    visible: rowRoot.isAdmin
                    implicitWidth: adminRow.implicitWidth + 8
                    implicitHeight: 18
                    radius: 4
                    color: Kirigami.Theme.highlightColor
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: adminRow
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text {
                            text: "🛡️"
                            font.pixelSize: 9
                        }
                        Text {
                            text: "admin"
                            font.bold: true
                            font.pixelSize: 8
                            color: "#ffffff"
                        }
                    }

                    QQC2.ToolTip.visible: adminMouse.containsMouse
                    QQC2.ToolTip.text: "System-level service (requires administrator privileges)"

                    MouseArea {
                        id: adminMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                Item { Layout.fillWidth: true }
            }

            PlasmaComponents.Label {
                text: (rowRoot.displayId && rowRoot.displayId !== "" ? rowRoot.displayId : rowRoot.serviceId) + " (" + (rowRoot.isEnabled ? "enabled" : "disabled") + ")"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.75
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // 3. Dual Toggle Action Buttons
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            // Toggle 1: Power/Run State (Start / Stop)
            PlasmaComponents.Button {
                id: runBtn
                implicitHeight: 28
                implicitWidth: Math.max(68, implicitContentWidth + Kirigami.Units.mediumSpacing)
                text: rowRoot.isActive ? "Stop" : "Start"
                icon.name: rowRoot.isActive ? "media-playback-stop" : "media-playback-start"
                checkable: false
                highlighted: rowRoot.isActive
                
                QQC2.ToolTip.visible: runMouse.containsMouse
                QQC2.ToolTip.text: (rowRoot.isActive ? "Stop " : "Start ") + rowRoot.serviceId + (rowRoot.isAdmin ? " (Admin)" : "")

                MouseArea {
                    id: runMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        rowRoot.actionRequested("toggle_run", rowRoot.scope, rowRoot.serviceId)
                    }
                }
            }

            // Toggle 2: Autostart/Boot State (Enable / Disable)
            PlasmaComponents.Button {
                id: enableBtn
                implicitHeight: 28
                implicitWidth: Math.max(58, implicitContentWidth + Kirigami.Units.mediumSpacing)
                text: rowRoot.isEnabled ? "On" : "Off"
                icon.name: rowRoot.isEnabled ? "pin" : "cross-shape"
                highlighted: rowRoot.isEnabled
                
                QQC2.ToolTip.visible: enableMouse.containsMouse
                QQC2.ToolTip.text: (rowRoot.isEnabled ? "Disable autostart for " : "Enable autostart for ") + rowRoot.serviceId + (rowRoot.isAdmin ? " (Admin)" : "")

                MouseArea {
                    id: enableMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        rowRoot.actionRequested("toggle_enable", rowRoot.scope, rowRoot.serviceId)
                    }
                }
            }
        }
    }
}
