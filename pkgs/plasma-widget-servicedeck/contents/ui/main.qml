import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    fullRepresentation: fullRep
    compactRepresentation: compactRep

    property var groupsData: []
    property int totalActive: 0
    property int totalServices: 0
    property string searchText: ""
    property bool isRefreshing: false

    // Data Source to execute service-deck-helper commands
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            root.isRefreshing = false;

            if (sourceName.indexOf("status") !== -1 || sourceName.indexOf("json") !== -1) {
                if (data["exit code"] === 0) {
                    try {
                        var json = JSON.parse(data.stdout.trim());
                        root.groupsData = json.groups || [];
                        root.totalActive = json.total_active || 0;
                        root.totalServices = json.total_services || 0;
                    } catch(e) {
                        console.log("[ServiceDeck] JSON parse error: " + e);
                    }
                }
            }
        }
    }

    function refreshStatus() {
        root.isRefreshing = true;
        execSource.connectSource("service-deck-helper status");
    }

    function runServiceAction(action, scope, serviceId) {
        var cmd = "service-deck-helper service " + action + " " + scope + " " + serviceId;
        execSource.connectSource(cmd);
        refreshTimer.restart();
    }

    function runGroupAction(action, groupId) {
        var cmd = "service-deck-helper group " + action + " " + groupId;
        execSource.connectSource(cmd);
        refreshTimer.restart();
    }

    // Auto-refresh poll timer (every 2.5 seconds)
    Timer {
        id: pollTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshStatus()
    }

    // Fast reaction timer after a user click
    Timer {
        id: refreshTimer
        interval: 200
        repeat: false
        onTriggered: refreshStatus()
    }

    // --- Compact Representation (Panel / System Tray) ---
    Component {
        id: compactRep
        Item {
            id: compactItem
            implicitWidth: Kirigami.Units.gridUnit * 2
            implicitHeight: Kirigami.Units.gridUnit * 2

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        root.expanded = !root.expanded;
                    } else {
                        root.refreshStatus();
                    }
                }
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                source: "preferences-system-services"
                color: root.totalActive > 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }

            // Badge Counter showing Active Services
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: Math.max(14, badgeText.width + 6)
                height: 14
                radius: 7
                color: root.totalActive > 0 ? "#2ecc71" : "#7f8c8d"
                visible: true

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.totalActive.toString()
                    font.bold: true
                    font.pixelSize: 9
                    color: "#ffffff"
                }
            }
        }
    }

    // --- Full Representation (Popup Service Deck Dashboard) ---
    Component {
        id: fullRep

        Kirigami.AbstractCard {
            id: popupCard
            implicitWidth: 490
            implicitHeight: 540

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                // 1. Header Toolbar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "preferences-system-services"
                        implicitWidth: Kirigami.Units.iconSizes.medium
                        implicitHeight: width
                        color: Kirigami.Theme.highlightColor
                    }

                    ColumnLayout {
                        spacing: 0
                        PlasmaComponents.Label {
                            text: "Service Deck"
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                        }
                        PlasmaComponents.Label {
                            text: root.totalActive + " of " + root.totalServices + " services active"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.8
                            color: root.totalActive > 0 ? "#2ecc71" : Kirigami.Theme.disabledTextColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Search Field
                    QQC2.TextField {
                        id: searchBox
                        placeholderText: "Search services..."
                        implicitWidth: 170
                        implicitHeight: 28
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        onTextChanged: root.searchText = text
                    }

                    // Refresh Button
                    PlasmaComponents.Button {
                        implicitHeight: 28
                        implicitWidth: 28
                        icon.name: "view-refresh"
                        QQC2.ToolTip.text: "Refresh states"
                        QQC2.ToolTip.visible: refreshMouse.containsMouse

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.refreshStatus()
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                // 2. Scrollable Groups List (with proper availableWidth scrollbar spacing)
                QQC2.ScrollView {
                    id: scrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                    QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

                    ColumnLayout {
                        width: scrollView.availableWidth
                        spacing: Kirigami.Units.mediumSpacing

                        Repeater {
                            id: groupRepeater
                            model: root.groupsData

                            delegate: GroupCard {
                                groupId: modelData.id
                                groupName: modelData.name
                                groupIcon: modelData.icon || "system-run"
                                servicesList: modelData.services || []
                                activeCount: modelData.active_count || 0
                                totalCount: modelData.total_count || 0
                                enabledCount: modelData.enabled_count || 0
                                allActive: modelData.all_active || false
                                allEnabled: modelData.all_enabled || false
                                isUngrouped: modelData.is_ungrouped || false
                                searchFilter: root.searchText

                                onServiceActionRequested: function(action, scope, sId) {
                                    root.runServiceAction(action, scope, sId);
                                }

                                onGroupActionRequested: function(action, gId) {
                                    root.runGroupAction(action, gId);
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
