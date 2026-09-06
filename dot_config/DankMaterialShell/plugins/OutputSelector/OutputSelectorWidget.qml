import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "output-selector"
    popoutWidth: 400

    readonly property var snapshotData: snapshot.value || ({})
    readonly property var outputs: snapshotData.outputs || []
    readonly property bool singleMode: snapshotData.mode === "single"
    readonly property bool busy: snapshotData.busy === true
    readonly property int activeCount: outputs.filter(output => output.enabled).length
    readonly property bool showSelector: CompositorService.isNiri && outputs.length > 1
    readonly property var daemon: pluginService?.pluginDaemonInstances[pluginId] ?? null

    visible: showSelector
    // Side sections use the size; the center section also checks root visibility.
    states: State {
        name: "hidden"
        when: !root.showSelector
        PropertyChanges {
            target: root
            width: 0
            height: 0
        }
    }
    onShowSelectorChanged: {
        if (!showSelector)
            closePopout();
    }

    PluginGlobalVar {
        id: snapshot
        varName: "snapshot"
        defaultValue: ({mode: "multiple", outputs: [], busy: false, error: ""})
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.snapshotData.error ? "error" : "desktop_windows"
                size: root.iconSize
                color: root.snapshotData.error ? Theme.error : Theme.widgetIconColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.activeCount + "/" + root.outputs.length
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.snapshotData.error ? "error" : "desktop_windows"
                size: root.iconSize
                color: root.snapshotData.error ? Theme.error : Theme.widgetIconColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.activeCount + "/" + root.outputs.length
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Outputs"
            detailsText: root.busy ? "Switching monitors..."
                    : root.activeCount + " of " + root.outputs.length + " connected monitors on"
            showCloseButton: true
            headerActions: Component {
                DankActionButton {
                    iconName: "refresh"
                    tooltipText: "Refresh outputs"
                    enabled: !root.busy && root.daemon !== null
                    onClicked: root.daemon.refresh()
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: [{label: "Single", value: "single"}, {label: "Multiple", value: "multiple"}]

                        delegate: DankButton {
                            required property var modelData
                            readonly property bool selected: root.snapshotData.mode === modelData.value

                            width: (parent.width - Theme.spacingS) / 2
                            text: modelData.label
                            backgroundColor: selected ? Theme.primary : Theme.surfaceContainerHigh
                            textColor: selected ? Theme.primaryText : Theme.surfaceText
                            enabled: !root.busy && root.daemon !== null
                            onClicked: root.daemon.setMode(modelData.value, String(root.parentScreen?.name || ""))
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    text: root.singleMode ? "Select the monitor to use. New monitors stay off until selected."
                            : "Toggle monitors independently. At least one must stay on."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    width: parent.width
                    visible: !!root.snapshotData.error
                    text: String(root.snapshotData.error || "")
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                Item {
                    width: parent.width
                    implicitHeight: Math.min(outputColumn.implicitHeight, 360)

                    DankFlickable {
                        id: outputList
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: outputColumn.implicitHeight
                        clip: true

                        Column {
                            id: outputColumn
                            width: outputList.width - Theme.spacingS
                            spacing: Theme.spacingS

                            Repeater {
                                model: root.outputs

                                delegate: StyledRect {
                                    id: outputRow
                                    required property var modelData
                                    readonly property bool canToggle: !root.busy && root.daemon !== null
                                            && (!modelData.enabled || root.activeCount > 1)

                                    width: outputColumn.width
                                    height: 76
                                    radius: Theme.cornerRadius
                                    color: modelData.enabled ? Theme.withAlpha(Theme.primary, 0.10) : Theme.nestedSurface

                                    DankIcon {
                                        id: monitorIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.spacingM
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: outputRow.modelData.internal ? "laptop" : "desktop_windows"
                                        size: Theme.iconSize
                                        color: outputRow.modelData.enabled ? Theme.primary : Theme.surfaceVariantText
                                    }

                                    Column {
                                        anchors.left: monitorIcon.right
                                        anchors.right: outputControl.left
                                        anchors.margins: Theme.spacingM
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.spacingXXS

                                        StyledText {
                                            width: parent.width
                                            text: String(outputRow.modelData.label)
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: outputRow.modelData.name + " | " + outputRow.modelData.detail
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: outputRow.canToggle
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.daemon.selectOutput(outputRow.modelData.name)
                                    }

                                    Item {
                                        id: outputControl
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.spacingM
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 52
                                        height: 30

                                        DankIcon {
                                            anchors.centerIn: parent
                                            visible: root.singleMode
                                            name: outputRow.modelData.enabled ? "radio_button_checked" : "radio_button_unchecked"
                                            size: Theme.iconSize
                                            color: outputRow.modelData.enabled ? Theme.primary : Theme.surfaceVariantText
                                        }

                                        DankToggle {
                                            anchors.fill: parent
                                            visible: !root.singleMode
                                            checked: outputRow.modelData.enabled
                                            enabled: outputRow.canToggle
                                            toggling: root.busy
                                            onToggled: root.daemon.selectOutput(outputRow.modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
