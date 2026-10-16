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
    readonly property bool showWarsaw: pluginData.showWarsaw === true
    readonly property var barClocks: {
        const clocks = [];
        if (showLondon)
            clocks.push({flag: "🇬🇧", time: liveData.london?.time || "--:--"});
        if (showWarsaw)
            clocks.push({flag: "🇵🇱", time: liveData.warsaw?.time || "--:--"});
        if (showDubai)
            clocks.push({flag: "🇦🇪", time: liveData.dubai?.time || "--:--"});
        return clocks;
    }

    function setBarVisibility(city, enabled) {
        const setting = {london: "showLondon", dubai: "showDubai", warsaw: "showWarsaw"}[city];
        if (pluginService && setting)
            pluginService.savePluginData(pluginId, setting, enabled);
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
        PopoutComponent {
            id: popout

            Loader {
                id: panelLoader
                width: parent.width
                // DMS busts the widget's cache on reload, but not its QML dependencies.
                // Load the panel by a fresh URL so its properties and contents match.
                source: Qt.resolvedUrl("./WorldClockPanel.qml").toString() + "?t=" + Date.now()

                onLoaded: {
                    item.liveData = Qt.binding(() => root.liveData);
                    item.showLondon = Qt.binding(() => root.showLondon);
                    item.showDubai = Qt.binding(() => root.showDubai);
                    item.showWarsaw = Qt.binding(() => root.showWarsaw);
                    item.closePopout = Qt.binding(() => popout.closePopout);
                    item.parentPopout = Qt.binding(() => popout.parentPopout);
                }
            }

            Connections {
                target: panelLoader.item
                function onBarVisibilityChanged(city, enabled) {
                    root.setBarVisibility(city, enabled);
                }
            }
        }
    }
}
