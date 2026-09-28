import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "world-clock"
    popoutWidth: 420

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

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                visible: root.barClocks.length === 0
                name: "public"
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            Repeater {
                model: root.barClocks

                StyledText {
                    required property var modelData
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
                visible: root.barClocks.length === 0
                name: "public"
                size: root.iconSize
                color: Theme.widgetIconColor
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
