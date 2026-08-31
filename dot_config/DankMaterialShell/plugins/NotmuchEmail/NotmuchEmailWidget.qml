import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "notmuch-email"

    readonly property var snapshotData: snapshot.value || ({})
    readonly property int unreadCount: Number(snapshotData.unread || 0)
    readonly property int inboxCount: Number(snapshotData.inbox || 0)
    readonly property var messages: snapshotData.messages || []
    readonly property bool hasError: String(snapshotData.error || "") !== ""
    readonly property bool isRefreshing: snapshotData.refreshing === true
    readonly property string helperUrl: Qt.resolvedUrl("./notmuch-email.py").toString()
    readonly property string helperPath: decodeURIComponent(helperUrl.replace(/^file:\/\//, ""))

    function openMailClient() {
        Quickshell.execDetached(["email"]);
    }

    function refreshInbox() {
        Quickshell.execDetached(["dms", "ipc", "call", "notmuch-email", "refresh"]);
    }

    function syncInbox() {
        Quickshell.execDetached(["dms", "ipc", "call", "notmuch-email", "sync"]);
    }

    function openMessage(message) {
        const messageId = String(message?.id || "");
        if (messageId)
            Quickshell.execDetached([helperPath, "open", messageId]);
    }

    function updateMessage(action, message) {
        const messageId = String(message?.id || "");
        if (!messageId)
            return;

        Proc.runCommand(
            null,
            [helperPath, action, messageId],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    root.refreshInbox();
                    return;
                }
                const fallback = action === "archive"
                    ? "Could not archive this message"
                    : "Could not mark this message as read";
                ToastService.showError("Email action failed", stdout.trim() || fallback);
            },
            0,
            10000
        );
    }

    function inboxSummary() {
        if (hasError && snapshotData.updatedAt === 0)
            return "Inbox unavailable";
        if (unreadCount > 0)
            return unreadCount + " unread / " + inboxCount + " in inbox";
        return inboxCount + (inboxCount === 1 ? " message in inbox" : " messages in inbox");
    }

    pillRightClickAction: () => root.openMailClient()
    popoutWidth: 520

    PluginGlobalVar {
        id: snapshot

        varName: "snapshot"
        defaultValue: ({
            "unread": 0,
            "inbox": 0,
            "messages": [],
            "updatedAt": 0,
            "error": "",
            "refreshing": true
        })
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.hasError ? "error" : "mail"
                size: root.iconSize
                color: root.hasError ? Theme.error : Theme.widgetIconColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.unreadCount > 0
                text: root.unreadCount + "/" + root.inboxCount
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                font.weight: Font.Medium
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.hasError ? "error" : "mail"
                size: root.iconSize
                color: root.hasError ? Theme.error : Theme.widgetIconColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.unreadCount > 0
                text: root.unreadCount
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                font.weight: Font.Medium
                color: Theme.widgetTextColor
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: panel

            readonly property var messages: root.messages

            function activateMessage(message) {
                root.openMessage(message);
                if (closePopout)
                    closePopout();
            }

            headerText: "Inbox"
            detailsText: root.isRefreshing ? "Refreshing inbox..." : root.inboxSummary()
            showCloseButton: true
            headerActions: Component {
                Row {
                    spacing: Theme.spacingXS

                    DankActionButton {
                        id: refreshButton

                        iconName: "refresh"
                        tooltipText: root.isRefreshing ? "Syncing inbox" : "Sync inbox"
                        enabled: !root.isRefreshing
                        onClicked: root.syncInbox()

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.isRefreshing

                            onRunningChanged: {
                                if (!running)
                                    refreshButton.rotation = 0;
                            }
                        }
                    }

                    DankActionButton {
                        iconName: "mail"
                        tooltipText: "Open NeoMutt"
                        onClicked: {
                            root.openMailClient();
                            if (panel.closePopout)
                                panel.closePopout();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: Math.min(Math.max(messageColumn.implicitHeight, 112), 560)

                DankFlickable {
                    id: messageFlickable

                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: messageColumn.implicitHeight
                    clip: true

                    Column {
                        id: messageColumn

                        width: messageFlickable.width - Theme.spacingS
                        spacing: Theme.spacingS

                        StyledRect {
                            width: parent.width
                            height: 64
                            visible: root.hasError
                            radius: Theme.cornerRadius
                            color: Theme.withAlpha(Theme.error, 0.10)
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.error, 0.35)

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingS

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "error"
                                    size: Theme.iconSize
                                    color: Theme.error
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Theme.iconSize - Theme.spacingS
                                    text: String(root.snapshotData.error || "Unable to refresh the inbox")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 112
                            visible: panel.messages.length === 0 && !root.hasError

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DankIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: root.isRefreshing ? "refresh" : "inbox"
                                    size: Theme.iconSize + 8
                                    color: Theme.surfaceVariantText
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.isRefreshing ? "Loading inbox..." : "Inbox is empty"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        Repeater {
                            model: panel.messages

                            delegate: StyledRect {
                                id: messageRow

                                required property var modelData

                                readonly property bool unread: modelData.unread === true

                                width: messageColumn.width
                                height: 72
                                radius: Theme.cornerRadius
                                color: rowMouse.containsMouse
                                    ? Theme.surfaceContainerHighest
                                    : (unread ? Theme.withAlpha(Theme.primary, 0.10) : Theme.nestedSurface)
                                border.width: 0

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Theme.spacingS
                                    width: 6
                                    height: 6
                                    radius: 3
                                    visible: messageRow.unread
                                    color: Theme.primary
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: messageActions.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Theme.spacingL
                                    anchors.rightMargin: Theme.spacingS
                                    spacing: Theme.spacingXXS

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingS

                                        StyledText {
                                            width: Math.max(0, parent.width - dateText.implicitWidth - Theme.spacingS)
                                            text: String(messageRow.modelData.sender || "Unknown sender")
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: messageRow.unread ? Font.Bold : Font.Medium
                                            color: Theme.surfaceText
                                            wrapMode: Text.NoWrap
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            id: dateText

                                            text: String(messageRow.modelData.date || "")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            wrapMode: Text.NoWrap
                                        }
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: String(messageRow.modelData.subject || "(no subject)")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: messageRow.unread ? Font.Medium : Font.Normal
                                        color: messageRow.unread ? Theme.surfaceText : Theme.surfaceVariantText
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    id: messageActions

                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingXXS

                                    DankActionButton {
                                        visible: messageRow.unread
                                        buttonSize: 28
                                        iconSize: Theme.iconSize - 7
                                        iconName: "mark_email_read"
                                        iconColor: Theme.primary
                                        tooltipText: "Mark as read"
                                        tooltipSide: "left"
                                        onClicked: root.updateMessage("mark-read", messageRow.modelData)
                                    }

                                    DankActionButton {
                                        buttonSize: 28
                                        iconSize: Theme.iconSize - 7
                                        iconName: "archive"
                                        iconColor: Theme.surfaceVariantText
                                        tooltipText: "Archive"
                                        tooltipSide: "left"
                                        onClicked: root.updateMessage("archive", messageRow.modelData)
                                    }
                                }

                                MouseArea {
                                    id: rowMouse

                                    anchors.left: parent.left
                                    anchors.right: messageActions.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.activateMessage(messageRow.modelData)
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: Theme.spacingXS
                            visible: panel.messages.length > 0
                        }
                    }
                }
            }
        }
    }
}
