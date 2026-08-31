import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "herdr-agents"

    readonly property var statusData: status.value || ({})
    readonly property int agentCount: statusData.count || 0
    readonly property bool hasAgents: agentCount > 0
    readonly property var barStatuses: {
        const counts = statusData.counts || {};
        const order = ["idle", "done", "working", "blocked", "unknown"];
        const result = [];
        for (const name of order) {
            if (counts[name] > 0)
                result.push({
                    "status": name,
                    "count": counts[name]
                });
        }
        return result;
    }

    function statusColor(name) {
        switch (name) {
        case "blocked":
            return Theme.error;
        case "working":
            return Theme.warning;
        case "done":
            return Theme.info;
        case "idle":
            return Theme.success;
        default:
            return Theme.surfaceVariantText;
        }
    }

    function statusGlyph(name) {
        if (name === "idle")
            return "\u25cb";
        if (name === "unknown")
            return "?";
        return "\u25cf";
    }

    function openHerdr() {
        Quickshell.execDetached(["focus-or-exec", "Alacritty.herdr", "terminal", "-c", "herdr", "-e", "herdr"]);
    }

    function focusAgent(agent) {
        const paneId = agent?.pane_id || "";
        if (!paneId) {
            openHerdr();
            return;
        }
        Quickshell.execDetached([
            "sh",
            "-c",
            "herdr agent focus \"$1\" >/dev/null 2>&1; exec focus-or-exec Alacritty.herdr terminal -c herdr -e herdr",
            "herdr-agents",
            paneId
        ]);
    }

    function quotaResetText(row) {
        const resetAt = row?.resetAt || 0;
        if (resetAt <= 0)
            return "";
        const ms = resetAt * 1000 - Date.now();
        if (ms <= 0)
            return "resets now";
        const minutes = Math.floor(ms / 60000);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return "resets in " + days + "d " + (hours % 24) + "h";
        if (hours > 0)
            return "resets in " + hours + "h " + (minutes % 60) + "m";
        return "resets in " + Math.max(1, minutes) + "m";
    }

    function quotaAgeText() {
        const updatedAt = quotaData?.updatedAt || 0;
        if (updatedAt <= 0)
            return "";
        const age = Math.max(0, Math.floor(Date.now() / 1000) - updatedAt);
        if (age < 60)
            return "just now";
        const minutes = Math.floor(age / 60);
        if (minutes < 60)
            return minutes + "m ago";
        return Math.floor(minutes / 60) + "h ago";
    }

    pillRightClickAction: () => root.openHerdr()
    popoutWidth: 520

    PluginGlobalVar {
        id: status

        varName: "status"
        defaultValue: ({
            "count": 0,
            "dominant_status": "empty",
            "counts": ({}),
            "groups": []
        })
    }

    PluginGlobalVar {
        id: quota

        varName: "quota"
        defaultValue: ({
            "updatedAt": 0,
            "cacheAgeSeconds": 0,
            "rows": []
        })
    }

    readonly property var quotaData: quota.value || ({})
    readonly property var quotaRows: quotaData.rows || []

    onHasAgentsChanged: setVisibilityOverride(hasAgents)
    Component.onCompleted: setVisibilityOverride(hasAgents)

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uee0d"
                isMonospace: true
                font.pixelSize: root.iconSize
                color: Theme.widgetIconColor
            }

            Repeater {
                model: root.barStatuses

                delegate: Row {
                    id: statusCount

                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXXS

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusGlyph(statusCount.modelData.status)
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: root.statusColor(statusCount.modelData.status)
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: statusCount.modelData.count
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Theme.widgetTextColor
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\uee0d"
                isMonospace: true
                font.pixelSize: root.iconSize
                color: Theme.widgetIconColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.agentCount
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: panel

            readonly property var statusData: root.statusData
            readonly property var groups: statusData.groups || []
            readonly property int agentCount: statusData.count || 0
            readonly property string dominantStatus: statusData.dominant_status || "unknown"

            function labelFor(statusName) {
                if (!statusName)
                    return "Unknown";
                return statusName.charAt(0).toUpperCase() + statusName.slice(1);
            }

            function heroSummary() {
                const counts = statusData.counts || {};
                const total = agentCount + (agentCount === 1 ? " agent" : " agents");
                if (counts.blocked > 0)
                    return total + " | " + counts.blocked + " blocked";
                if (counts.working > 0)
                    return total + " | " + counts.working + " working";
                if (counts.done > 0)
                    return total + " | " + counts.done + " done";
                return total + " | all idle";
            }

            function agentMeta(agent) {
                const parts = [String(agent.agent || "agent")];
                let project = String(agent.project || agent.workspace || "");
                const feature = String(agent.feature || "");
                if (feature)
                    project = project ? project + " @ " + feature : feature;
                if (project)
                    parts.push(project);
                if (agent.tab)
                    parts.push(String(agent.tab));
                return parts.join("  /  ");
            }

            function activateAgent(agent) {
                root.focusAgent(agent);
                if (closePopout)
                    closePopout();
            }

            headerText: "Herdr agents"
            showCloseButton: true
            headerActions: Component {
                DankActionButton {
                    iconName: "terminal"
                    tooltipText: "Open Herdr"
                    onClicked: {
                        root.openHerdr();
                        if (panel.closePopout)
                            panel.closePopout();
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: Math.min(panelColumn.implicitHeight, 560)

                DankFlickable {
                    id: panelFlickable

                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: panelColumn.implicitHeight
                    clip: true

                    Column {
                        id: panelColumn

                        width: panelFlickable.width - Theme.spacingS
                        spacing: Theme.spacingM

                        StyledRect {
                            width: parent.width
                            height: 92
                            radius: Theme.cornerRadius
                            color: Theme.nestedSurface
                            border.width: 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingL
                                spacing: Theme.spacingM

                                StyledRect {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 52
                                    height: 52
                                    radius: 26
                                    color: Theme.withAlpha(Theme.primary, 0.16)
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.primary, 0.38)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "\uee0d"
                                        isMonospace: true
                                        font.pixelSize: Theme.fontSizeXLarge + 4
                                        color: Theme.primary
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 52 - Theme.spacingM
                                    spacing: Theme.spacingXXS

                                    StyledText {
                                        width: parent.width
                                        text: "Herdr"
                                        font.pixelSize: Theme.fontSizeXLarge
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: panel.heroSummary()
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingS

                            Repeater {
                                model: panel.groups

                                delegate: StyledRect {
                                    id: summaryChip

                                    required property var modelData

                                    width: chipRow.implicitWidth + Theme.spacingM * 2
                                    height: 30
                                    radius: 15
                                    color: Theme.nestedSurface
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.primary, 0.38)

                                    Row {
                                        id: chipRow

                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        StyledText {
                                            text: root.statusGlyph(summaryChip.modelData.status)
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: root.statusColor(summaryChip.modelData.status)
                                        }

                                        StyledText {
                                            text: panel.labelFor(summaryChip.modelData.status) + " " + summaryChip.modelData.count
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            width: panelColumn.width
                            spacing: Theme.spacingS
                            visible: root.quotaRows.length > 0

                            Row {
                                width: parent.width - Theme.spacingM
                                spacing: Theme.spacingS

                                StyledText {
                                    id: quotaHeaderLabel

                                    text: "QUOTA"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - quotaHeaderLabel.implicitWidth - quotaAgeLabel.implicitWidth - Theme.spacingS * 2
                                    height: 1
                                    color: Theme.withAlpha(Theme.surfaceVariantText, 0.24)
                                }

                                StyledText {
                                    id: quotaAgeLabel

                                    text: root.quotaAgeText()
                                    visible: text !== ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }

                            Repeater {
                                model: root.quotaRows

                                delegate: Column {
                                    id: quotaRow

                                    required property var modelData

                                    width: panelColumn.width
                                    spacing: Theme.spacingXXS

                                    readonly property real remaining: modelData.percentRemaining || 0
                                    readonly property bool alarming: remaining < 10

                                    Row {
                                        width: parent.width

                                        StyledText {
                                            width: parent.width - quotaPercent.implicitWidth
                                            text: quotaRow.modelData.label
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceText
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            id: quotaPercent

                                            text: Math.round(quotaRow.remaining) + "%"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: quotaRow.alarming ? Theme.error : Theme.surfaceText
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Theme.withAlpha(Theme.surfaceText, 0.12)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: parent.height
                                            radius: parent.radius
                                            width: parent.width * (quotaRow.remaining / 100)
                                            color: quotaRow.alarming ? Theme.error : Theme.primary

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 160
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: root.quotaResetText(quotaRow.modelData)
                                        visible: text !== ""
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: panel.groups

                            delegate: Column {
                                id: groupSection

                                required property var modelData

                                width: panelColumn.width
                                spacing: Theme.spacingS

                                Row {
                                    width: parent.width - Theme.spacingM
                                    spacing: Theme.spacingS

                                    StyledText {
                                        text: panel.labelFor(groupSection.modelData.status).toUpperCase()
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Bold
                                        color: root.statusColor(groupSection.modelData.status)
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - parent.children[0].implicitWidth - countLabel.implicitWidth - Theme.spacingS * 2
                                        height: 1
                                        color: Theme.withAlpha(root.statusColor(groupSection.modelData.status), 0.24)
                                    }

                                    StyledText {
                                        id: countLabel

                                        text: groupSection.modelData.count
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }
                                }

                                Repeater {
                                    model: groupSection.modelData.agents

                                    delegate: StyledRect {
                                        id: agentCard

                                        required property var modelData

                                        width: groupSection.width
                                        height: 72
                                        radius: Theme.cornerRadius
                                        color: cardMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.nestedSurface
                                        border.width: modelData.focused ? 1 : 0
                                        border.color: Theme.withAlpha(Theme.primary, 0.28)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.margins: Theme.spacingS
                                            width: 4
                                            radius: 2
                                            color: root.statusColor(agentCard.modelData.status)
                                        }

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: statusBadge.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingL
                                            anchors.rightMargin: Theme.spacingM
                                            spacing: Theme.spacingXXS

                                            StyledText {
                                                width: parent.width
                                                text: agentCard.modelData.name
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.Medium
                                                color: Theme.surfaceText
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                width: parent.width
                                                text: panel.agentMeta(agentCard.modelData)
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                                elide: Text.ElideMiddle
                                            }
                                        }

                                        StyledRect {
                                            id: statusBadge

                                            anchors.right: parent.right
                                            anchors.rightMargin: Theme.spacingM
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: statusRow.implicitWidth + Theme.spacingS * 2
                                            height: 26
                                            radius: 13
                                            color: Theme.withAlpha(root.statusColor(agentCard.modelData.status), 0.13)
                                            border.width: 0

                                            Row {
                                                id: statusRow

                                                anchors.centerIn: parent
                                                spacing: Theme.spacingXS

                                                StyledText {
                                                    text: root.statusGlyph(agentCard.modelData.status)
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    color: root.statusColor(agentCard.modelData.status)
                                                }

                                                StyledText {
                                                    text: agentCard.modelData.focused ? "Focused" : panel.labelFor(agentCard.modelData.status)
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.Medium
                                                    color: Theme.surfaceText
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: cardMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.activateAgent(agentCard.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: Theme.spacingXS
                        }
                    }
                }
            }
        }
    }
}
