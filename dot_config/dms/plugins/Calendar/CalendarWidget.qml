import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "calendar"

    readonly property string dateText: systemClock.date.toLocaleDateString(I18n.locale(), "ddd, MMM d")
    readonly property int barPosition: axis?.edge === "left" ? 2 : axis?.edge === "right" ? 3 : axis?.edge === "bottom" ? 1 : 0
    property var pendingTrigger: null

    function finishOpen() {
        const popout = PopoutService.dankDashPopout;
        if (!pendingTrigger || !popout)
            return;
        const trigger = pendingTrigger;
        pendingTrigger = null;
        popout.triggerScreen = trigger.screen;
        popout.setTriggerPosition(trigger.x, trigger.y, trigger.width, trigger.section, trigger.screen, barPosition, barThickness, barSpacing, barConfig);
        PopoutService.toggleDankDash("overview");
    }

    pillClickAction: (_x, _y, _width, section, screen) => {
        const position = SettingsData.getPopupTriggerPosition(root.mapToItem(null, 0, 0), screen, root.barThickness, root.width, root.barSpacing, root.barPosition, root.barConfig);
        root.pendingTrigger = {x: position.x, y: position.y, width: position.width, section: section, screen: screen};
        // DankDash may not have been loaded yet in this shell session.
        if (PopoutService.dankDashPopoutLoader)
            PopoutService.dankDashPopoutLoader.active = true;
        root.finishOpen();
    }

    Connections {
        target: PopoutService
        function onDankDashPopoutChanged() {
            root.finishOpen();
        }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Connections {
        target: SessionService
        function onSessionResumed() {
            systemClock.enabled = false;
            systemClock.enabled = true;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "calendar_month"
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "calendar_month"
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: systemClock.date.toLocaleDateString(I18n.locale(), "MMM")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.widgetTextColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: systemClock.date.toLocaleDateString(I18n.locale(), "d")
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }
}
