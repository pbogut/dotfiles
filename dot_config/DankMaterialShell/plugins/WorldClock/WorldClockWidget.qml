import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "world-clock"
    popoutWidth: 420

    readonly property string localTime: Qt.formatTime(localClock.date, "hh:mm:ss")
    readonly property var liveData: snapshot.value || ({})
    readonly property bool showLondon: pluginData.showLondon !== false
    readonly property bool showDubai: pluginData.showDubai === true
    readonly property var barClocks: {
        const clocks = [];
        if (showLondon)
            clocks.push({flag: "🇬🇧", time: liveData.london?.time || "--:--"});
        if (showDubai)
            clocks.push({flag: "🇦🇪", time: liveData.dubai?.time || "--:--"});
        return clocks;
    }

    function setBarVisibility(city, enabled) {
        if (pluginService)
            pluginService.savePluginData(pluginId, city === "london" ? "showLondon" : "showDubai", enabled);
    }

    PluginGlobalVar {
        id: snapshot
        varName: "snapshot"
        defaultValue: ({})
    }

    SystemClock {
        id: localClock
        precision: SystemClock.Seconds
    }

    Connections {
        target: SessionService
        function onSessionResumed() {
            localClock.enabled = false;
            localClock.enabled = true;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "schedule"
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            NumericText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.localTime
                reserveText: "00:00:00"
                width: reservedWidth
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }

            Repeater {
                model: root.barClocks

                StyledText {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.flag + " " + modelData.time
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "schedule"
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            NumericText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.localTime.replace(/:/g, "\n")
                reserveText: "00"
                width: reservedWidth
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }

            Repeater {
                model: root.barClocks

                Column {
                    required property var modelData
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.flag
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.time
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.widgetTextColor
                    }
                }
            }
        }
    }

    popoutContent: Component {
        WorldClockPanel {
            liveData: root.liveData
            showLondon: root.showLondon
            showDubai: root.showDubai
            onBarVisibilityChanged: (city, enabled) => root.setBarVisibility(city, enabled)
        }
    }
}
