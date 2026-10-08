import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: cardRoot
    Layout.fillWidth: true
    
    property string groupId: ""
    property string groupName: ""
    property string groupIcon: "system-run"
    property var servicesList: []
    property int activeCount: 0
    property int totalCount: 0
    property int enabledCount: 0
    property bool allActive: false
    property bool allEnabled: false
    property bool isUngrouped: false
    property bool expanded: true
    property string searchFilter: ""

    signal serviceActionRequested(string action, string scope, string serviceId)
    signal groupActionRequested(string action, string groupId)

    // Filter services based on search text
    function getFilteredServices() {
        if (!searchFilter || searchFilter.trim() === "") {
            return servicesList || [];
        }
        var filter = searchFilter.toLowerCase().trim();
        var res = [];
        for (var i = 0; i < (servicesList ? servicesList.length : 0); i++) {
            var item = servicesList[i];
            if (item.name.toLowerCase().indexOf(filter) !== -1 || item.id.toLowerCase().indexOf(filter) !== -1) {
                res.push(item);
            }
        }
        return res;
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // Group Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Left clickable region to toggle expand/collapse
            MouseArea {
                id: headerClickArea
                Layout.fillWidth: true
                implicitHeight: 32
                cursorShape: Qt.PointingHandCursor
                onClicked: cardRoot.expanded = !cardRoot.expanded

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: cardRoot.expanded ? "go-down" : "go-next"
                        implicitWidth: 16
                        implicitHeight: 16
                        color: Kirigami.Theme.textColor
                    }

                    Kirigami.Icon {
                        source: cardRoot.groupIcon
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: width
                        color: cardRoot.activeCount > 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }

                    PlasmaComponents.Label {
                        text: cardRoot.groupName
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }

                    PlasmaComponents.Label {
                        text: "(" + cardRoot.activeCount + "/" + cardRoot.totalCount + " active)"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.75
                        color: cardRoot.activeCount > 0 ? "#2ecc71" : Kirigami.Theme.disabledTextColor
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // Right: Group Action Toolbar (Bulk Controls)
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                // Bulk Start / Stop All Toggle
                PlasmaComponents.Button {
                    implicitHeight: 26
                    implicitWidth: Math.max(76, implicitContentWidth + Kirigami.Units.mediumSpacing)
                    text: cardRoot.allActive ? "Stop All" : "Start All"
                    icon.name: cardRoot.allActive ? "media-playback-stop" : "media-playback-start"
                    highlighted: cardRoot.allActive
                    
                    QQC2.ToolTip.visible: bulkRunMouse.containsMouse
                    QQC2.ToolTip.text: (cardRoot.allActive ? "Stop all services in " : "Start all services in ") + cardRoot.groupName

                    MouseArea {
                        id: bulkRunMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            var act = cardRoot.allActive ? "stop_all" : "start_all";
                            cardRoot.groupActionRequested(act, cardRoot.groupId);
                        }
                    }
                }

                // Bulk Enable / Disable All Toggle
                PlasmaComponents.Button {
                    implicitHeight: 26
                    implicitWidth: Math.max(88, implicitContentWidth + Kirigami.Units.mediumSpacing)
                    text: cardRoot.allEnabled ? "Disable All" : "Enable All"
                    icon.name: cardRoot.allEnabled ? "cross-shape" : "pin"
                    highlighted: cardRoot.allEnabled

                    QQC2.ToolTip.visible: bulkEnableMouse.containsMouse
                    QQC2.ToolTip.text: (cardRoot.allEnabled ? "Disable autostart for all in " : "Enable autostart for all in ") + cardRoot.groupName

                    MouseArea {
                        id: bulkEnableMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            var act = cardRoot.allEnabled ? "disable_all" : "enable_all";
                            cardRoot.groupActionRequested(act, cardRoot.groupId);
                        }
                    }
                }
            }
        }

        // Expandable Services List
        ColumnLayout {
            id: servicesContainer
            Layout.fillWidth: true
            visible: cardRoot.expanded
            spacing: 2

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: cardRoot.expanded
            }

            Repeater {
                id: serviceRepeater
                model: cardRoot.getFilteredServices()

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    ServiceRow {
                        serviceId: modelData.id
                        displayId: modelData.display_id || modelData.id
                        serviceName: modelData.name
                        scope: modelData.scope
                        isAdmin: modelData.is_admin || (modelData.scope === "system")
                        isActive: modelData.is_active
                        activeState: modelData.active_state
                        subState: modelData.sub_state
                        isEnabled: modelData.is_enabled
                        unitState: modelData.unit_state
                        statusColor: modelData.color

                        onActionRequested: function(action, scope, sId) {
                            cardRoot.serviceActionRequested(action, scope, sId);
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        opacity: 0.3
                        visible: index < (serviceRepeater.count - 1)
                    }
                }
            }

            // Message if filtered list is empty
            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                text: "No matching services in this group"
                font.italic: true
                opacity: 0.6
                visible: cardRoot.getFilteredServices().length === 0
            }
        }
    }
}
