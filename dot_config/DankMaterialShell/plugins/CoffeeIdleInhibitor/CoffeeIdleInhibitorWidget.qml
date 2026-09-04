import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "coffee-idle-inhibitor"

    pillClickAction: () => SessionService.toggleIdleInhibit()

    horizontalBarPill: Component {
        DankIcon {
            name: "coffee"
            size: root.iconSize
            color: SessionService.idleInhibited
                ? Theme.widgetIconColor
                : Theme.withAlpha(Theme.widgetIconColor, 0.3)
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "coffee"
            size: root.iconSize
            color: SessionService.idleInhibited
                ? Theme.widgetIconColor
                : Theme.withAlpha(Theme.widgetIconColor, 0.3)
        }
    }
}
