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

    property string mode: "smart"
    property string dpmMode: "auto"
    property string clockSpeed: "--- MHz"
    property int busyPct: 0
    property string powerDraw: "0.0 W"
    property string gpuTemp: "-- °C"
    property bool isAc: true
    property string activeProfile: "---"
    property bool isBoostActive: (dpmMode === "high")

    // Data Source to execute amdgpu-boost commands
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            if (sourceName.indexOf("json") !== -1 && data["exit code"] === 0) {
                try {
                    var info = JSON.parse(data.stdout.trim());
                    root.mode = info.mode;
                    root.dpmMode = info.dpm;
                    root.clockSpeed = info.freq_mhz + " MHz";
                    root.busyPct = info.busy_pct;
                    root.powerDraw = info.power_w + " W";
                    root.gpuTemp = info.temp_c + " °C";
                    root.isAc = info.is_ac;
                    root.activeProfile = info.profile;
                } catch(e) {
                    console.log("JSON parse error: " + e);
                }
            }
        }
    }

    function refreshData() {
        execSource.connectSource("amdgpu-boost json");
    }

    function setMode(newMode) {
        execSource.connectSource("amdgpu-boost " + newMode);
        refreshTimer.restart();
    }

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshData()
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: refreshData()
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
                        root.setMode("toggle");
                    }
                }
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                source: "speedometer"
                color: root.isBoostActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }

            // Multi-State Indicator Badge
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 2
                width: 7
                height: 7
                radius: 3.5
                color: {
                    if (root.mode === "force") return "#9b59b6";       // Purple (Forced)
                    if (root.isBoostActive) return "#2ecc71";          // Green (Smart Active)
                    if (root.mode === "smart") return "#3498db";       // Cyan/Blue (Smart Standby)
                    return "#7f8c8d";                                  // Grey (Disabled)
                }
                visible: true
            }
        }
    }

    // --- Full Representation (Popup Dashboard Card) ---
    Component {
        id: fullRep
        Kirigami.AbstractCard {
            implicitWidth: 310
            implicitHeight: 310

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "speedometer"
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        color: root.isBoostActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: "AMD GPU Boost"
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                        }
                        PlasmaComponents.Label {
                            text: {
                                if (root.mode === "force") return "🚀 Forced Max (Continuous)";
                                if (root.mode === "smart") {
                                    return root.isBoostActive ? "🟢 Smart Active (Under Load)" : "🔵 Smart Standby (Idling)";
                                }
                                return "🛡️ Boost Disabled (Power Saving)";
                            }
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.9
                            color: {
                                if (root.mode === "force") return "#9b59b6";
                                if (root.isBoostActive) return "#2ecc71";
                                if (root.mode === "smart") return "#3498db";
                                return Kirigami.Theme.disabledTextColor;
                            }
                        }
                    }
                }

                // Mode Selector (Segmented Row)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Button {
                        Layout.fillWidth: true
                        text: "Smart"
                        icon.name: "system-run"
                        checked: (root.mode === "smart")
                        checkable: true
                        onClicked: root.setMode("smart")
                    }

                    PlasmaComponents.Button {
                        Layout.fillWidth: true
                        text: "Force"
                        icon.name: "media-playback-start"
                        checked: (root.mode === "force")
                        checkable: true
                        onClicked: root.setMode("force")
                    }

                    PlasmaComponents.Button {
                        Layout.fillWidth: true
                        text: "Off"
                        icon.name: "process-stop"
                        checked: (root.mode === "disabled")
                        checkable: true
                        onClicked: root.setMode("off")
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                // Live Telemetry Grid
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    // Metric 1: Core Frequency
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "GPU Clock"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { 
                            text: root.clockSpeed
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                            color: root.isBoostActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }
                    }

                    // Metric 2: GPU Load %
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "GPU Load"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { 
                            text: root.busyPct + " %"
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                            color: root.busyPct >= 20 ? "#2ecc71" : Kirigami.Theme.textColor
                        }
                    }

                    // Metric 3: Power Draw
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "Power Draw"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { text: root.powerDraw; font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize }
                    }

                    // Metric 4: Temperature
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "GPU Temp"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { 
                            text: root.gpuTemp
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            color: parseInt(root.gpuTemp) > 80 ? "#e74c3c" : (parseInt(root.gpuTemp) > 68 ? "#f39c12" : "#2ecc71")
                        }
                    }

                    // Metric 5: Power Source
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "Power Source"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { 
                            text: root.isAc ? "🔌 AC / USB-PD" : "🔋 Battery"
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        }
                    }

                    // Metric 6: Active Profile
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "Power Profile"; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.7 }
                        PlasmaComponents.Label { 
                            text: "⚙️ " + root.activeProfile
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        }
                    }
                }
            }
        }
    }
}
