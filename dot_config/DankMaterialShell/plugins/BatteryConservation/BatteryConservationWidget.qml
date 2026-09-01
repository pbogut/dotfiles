import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    layerNamespacePlugin: "battery-conservation"

    property var widgetData: null
    property real touchpadAccumulator: 0

    readonly property bool showPercentOnlyOnBattery: widgetData?.showBatteryPercentOnlyOnBattery !== undefined
        ? widgetData.showBatteryPercentOnlyOnBattery
        : SettingsData.showBatteryPercentOnlyOnBattery
    readonly property bool showPercent: {
        const base = widgetData?.showBatteryPercent !== undefined
            ? widgetData.showBatteryPercent
            : SettingsData.showBatteryPercent;
        return base && !(showPercentOnlyOnBattery && BatteryService.isPluggedIn);
    }
    readonly property bool showTime: widgetData?.showBatteryTime !== undefined
        ? widgetData.showBatteryTime
        : SettingsData.showBatteryTime
    readonly property bool showTimeOnlyOnBattery: widgetData?.showBatteryTimeOnlyOnBattery !== undefined
        ? widgetData.showBatteryTimeOnlyOnBattery
        : SettingsData.showBatteryTimeOnlyOnBattery
    readonly property bool pillStyle: widgetData?.batteryPillStyle !== undefined
        ? widgetData.batteryPillStyle
        : SettingsData.batteryPillStyle
    readonly property bool pillPercentSign: widgetData?.batteryPillPercentSign !== undefined
        ? widgetData.batteryPillPercentSign
        : SettingsData.batteryPillPercentSign

    readonly property var conservationData: conservation.value || ({})
    readonly property bool conservationKnown: conservationData.known === true
    readonly property bool conservationEnabled: conservationData.enabled === true
    readonly property bool conservationBusy: conservationData.busy === true
    readonly property string conservationText: String(
        conservationData.text || "Battery conservation mode status is unknown."
    )
    readonly property bool conservationHasError: String(conservationData.error || "") !== ""

    readonly property string batteryTimeText: {
        if (showTimeOnlyOnBattery && BatteryService.isPluggedIn)
            return "";
        const time = BatteryService.formatTimeRemaining();
        return time !== "Unknown" ? time : "";
    }

    readonly property string verticalBatteryTimeText: {
        if (!batteryTimeText)
            return "";

        let hours = 0;
        let minutes = 0;
        const hourMatch = batteryTimeText.match(/(\d+)h/);
        const minuteMatch = batteryTimeText.match(/(\d+)m/);
        if (hourMatch)
            hours = parseInt(hourMatch[1], 10);
        if (minuteMatch)
            minutes = parseInt(minuteMatch[1], 10);
        const hoursText = hours < 10 ? "0" + hours : hours.toString();
        const minutesText = minutes < 10 ? "0" + minutes : minutes.toString();
        return hoursText + "\n" + minutesText;
    }

    readonly property string horizontalDisplayText: {
        if (showPercent && showTime && batteryTimeText)
            return BatteryService.batteryLevel + "% (" + batteryTimeText + ")";
        if (showPercent)
            return BatteryService.batteryLevel + "%";
        if (showTime && batteryTimeText)
            return batteryTimeText;
        return "";
    }

    readonly property string verticalDisplayText: {
        if (showPercent && showTime && batteryTimeText)
            return BatteryService.batteryLevel + "\n" + verticalBatteryTimeText;
        if (showPercent)
            return BatteryService.batteryLevel.toString();
        if (showTime && batteryTimeText)
            return verticalBatteryTimeText;
        return "";
    }

    readonly property string horizontalSideText: {
        if (!pillStyle)
            return horizontalDisplayText;
        return showTime && batteryTimeText ? batteryTimeText : "";
    }

    function batteryColor() {
        if (!BatteryService.batteryAvailable)
            return Theme.widgetIconColor;
        if (BatteryService.isLowBattery && !BatteryService.isCharging)
            return Theme.error;
        if (BatteryService.isCharging || BatteryService.isPluggedIn)
            return Theme.primary;
        return Theme.widgetIconColor;
    }

    function refreshConservation() {
        Quickshell.execDetached(["dms", "ipc", "call", "battery-conservation", "refresh"]);
    }

    function setConservation(enabled) {
        Quickshell.execDetached([
            "dms",
            "ipc",
            "call",
            "battery-conservation",
            enabled ? "enable" : "disable"
        ]);
    }

    function toggleConservation() {
        Quickshell.execDetached(["dms", "ipc", "call", "battery-conservation", "toggle"]);
    }

    function adjustBrightness(delta) {
        if (delta === 0 || !DisplayService.brightnessAvailable)
            return;

        if (delta !== 120 && delta !== -120) {
            touchpadAccumulator += delta;
            if (Math.abs(touchpadAccumulator) < 500)
                return;
            delta = touchpadAccumulator;
            touchpadAccumulator = 0;
        }

        const change = delta > 0 ? 5 : -5;
        const level = Math.max(0, Math.min(100, DisplayService.brightnessLevel + change));
        DisplayService.setBrightness(level, "", false);
    }

    pillRightClickAction: () => root.toggleConservation()
    popoutWidth: 400

    component OfficialBolt: Shape {
        id: officialBolt

        property color fillColor: Theme.surfaceText
        property real size: 16

        implicitWidth: Math.round(size * (6 / 13))
        implicitHeight: Math.round(size)
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: officialBolt.fillColor
            strokeColor: "transparent"
            startX: officialBolt.width / 3
            startY: officialBolt.height

            PathLine {
                x: officialBolt.width / 3
                y: officialBolt.height * (7.5 / 13)
            }
            PathLine {
                x: 0
                y: officialBolt.height * (7.5 / 13)
            }
            PathLine {
                x: officialBolt.width * (2 / 3)
                y: 0
            }
            PathLine {
                x: officialBolt.width * (2 / 3)
                y: officialBolt.height * (5.5 / 13)
            }
            PathLine {
                x: officialBolt.width
                y: officialBolt.height * (5.5 / 13)
            }
            PathLine {
                x: officialBolt.width / 3
                y: officialBolt.height
            }
        }
    }

    component BatteryPill: Item {
        id: batteryPill

        property real thickness: 18
        property bool vertical: false
        property bool showNumber: true
        property bool showPercentSign: false

        readonly property int signSize: Math.max(1, Math.round(glyphSize * 0.72))
        readonly property real bodyLength: Math.round(thickness * 1.95)
        readonly property real level: Math.max(0, Math.min(100, BatteryService.batteryLevel))
        readonly property bool charging: BatteryService.isCharging
        readonly property bool lowState: BatteryService.isLowBattery && !BatteryService.isCharging
        readonly property color fillColor: {
            if (!BatteryService.batteryAvailable)
                return Theme.surfaceVariant;
            if (lowState)
                return Theme.error;
            return Theme.primary;
        }
        readonly property color onFillColor: {
            const color = fillColor;
            const luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
            return luminance > 0.5
                ? Qt.rgba(0, 0, 0, 0.9)
                : Qt.rgba(1, 1, 1, 0.95);
        }
        readonly property string numberText: Math.round(level).toString()
        readonly property int glyphSize: Math.round(thickness * 0.58)
        readonly property int boltSize: Math.round(thickness * 0.72)
        readonly property real nubBreadth: Math.round(thickness * 0.16)
        readonly property real nubSpan: Math.round(thickness * 0.46)

        implicitWidth: vertical
            ? thickness
            : Math.max(bodyLength, showNumber ? numberTrack.width + thickness * 0.7 : 0) + nubBreadth
        implicitHeight: vertical ? bodyLength + nubBreadth : thickness

        Rectangle {
            id: batteryBody

            x: 0
            y: batteryPill.vertical ? batteryPill.nubBreadth : 0
            width: batteryPill.vertical ? parent.width : parent.width - batteryPill.nubBreadth
            height: batteryPill.vertical ? parent.height - batteryPill.nubBreadth : parent.height
            radius: Math.round(Math.min(width, height) * 0.34)
            color: Theme.withAlpha(Theme.surfaceVariant, 0.9)

            Rectangle {
                id: batteryFill

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: batteryPill.vertical
                    ? parent.width
                    : Math.round(parent.width * batteryPill.level / 100)
                height: batteryPill.vertical
                    ? Math.round(parent.height * batteryPill.level / 100)
                    : parent.height
                radius: batteryBody.radius
                color: batteryPill.fillColor

                Behavior on width {
                    enabled: !batteryPill.vertical
                    NumberAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.standardEasing
                    }
                }

                Behavior on height {
                    enabled: batteryPill.vertical
                    NumberAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            Item {
                id: glyphTrack

                anchors.fill: parent
                visible: BatteryService.batteryAvailable
                    && ((batteryPill.charging && batteryPill.vertical)
                        || (!batteryPill.vertical && batteryPill.showNumber))

                Row {
                    id: numberTrack

                    anchors.centerIn: parent
                    spacing: 1
                    visible: !batteryPill.vertical && batteryPill.showNumber

                    StyledText {
                        id: trackNumber

                        anchors.verticalCenter: parent.verticalCenter
                        text: batteryPill.numberText
                        color: Theme.surfaceText
                        font.pixelSize: batteryPill.glyphSize
                        font.weight: Font.Bold
                    }

                    StyledText {
                        anchors.baseline: trackNumber.baseline
                        visible: batteryPill.showPercentSign
                        text: "%"
                        color: Theme.surfaceText
                        font.pixelSize: batteryPill.signSize
                        font.weight: Font.Bold
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    visible: batteryPill.charging && batteryPill.vertical
                    name: "bolt"
                    size: batteryPill.boltSize
                    color: Theme.surfaceText
                }
            }

            Item {
                x: batteryFill.x
                y: batteryFill.y
                width: batteryFill.width
                height: batteryFill.height
                visible: glyphTrack.visible
                clip: true

                Item {
                    x: -batteryFill.x
                    y: -batteryFill.y
                    width: batteryBody.width
                    height: batteryBody.height

                    Row {
                        anchors.centerIn: parent
                        spacing: 1
                        visible: !batteryPill.vertical && batteryPill.showNumber

                        StyledText {
                            id: fillNumber

                            anchors.verticalCenter: parent.verticalCenter
                            text: batteryPill.numberText
                            color: batteryPill.onFillColor
                            font.pixelSize: batteryPill.glyphSize
                            font.weight: Font.Bold
                        }

                        StyledText {
                            anchors.baseline: fillNumber.baseline
                            visible: batteryPill.showPercentSign
                            text: "%"
                            color: batteryPill.onFillColor
                            font.pixelSize: batteryPill.signSize
                            font.weight: Font.Bold
                        }
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        visible: batteryPill.charging && batteryPill.vertical
                        name: "bolt"
                        size: batteryPill.boltSize
                        color: batteryPill.onFillColor
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: batteryPill.nubBreadth
            height: batteryPill.nubSpan
            visible: !batteryPill.vertical
            radius: Math.round(batteryPill.nubBreadth * 0.35)
            color: Theme.withAlpha(Theme.surfaceVariant, 0.9)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: batteryPill.nubSpan
            height: batteryPill.nubBreadth
            visible: batteryPill.vertical
            radius: Math.round(batteryPill.nubBreadth * 0.35)
            color: Theme.withAlpha(Theme.surfaceVariant, 0.9)
        }
    }

    PluginGlobalVar {
        id: conservation

        varName: "conservation"
        defaultValue: ({
            "known": false,
            "enabled": false,
            "busy": true,
            "refreshing": true,
            "changing": false,
            "error": "",
            "text": "Checking battery conservation mode...",
            "updatedAt": 0
        })
    }

    horizontalBarPill: Component {
        Row {
            spacing: (root.barConfig?.noBackground ?? false) ? 1 : 2

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.pillStyle
                name: BatteryService.getBatteryIcon()
                size: root.iconSize
                color: root.batteryColor()
            }

            BatteryPill {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pillStyle
                vertical: false
                showNumber: root.showPercent
                showPercentSign: root.pillPercentSign
                thickness: root.iconSize
            }

            OfficialBolt {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pillStyle
                    && BatteryService.batteryAvailable
                    && BatteryService.isCharging
                fillColor: Theme.primary
                size: Math.round(root.iconSize * 0.85)
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: BatteryService.batteryAvailable && root.horizontalSideText !== ""
                text: root.horizontalSideText
                font.pixelSize: Theme.barTextSize(
                    root.barThickness,
                    root.barConfig?.fontScale,
                    root.barConfig?.maximizeWidgetText
                )
                color: Theme.widgetTextColor
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    root.adjustBrightness(event.angleDelta.y);
                    event.accepted = true;
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.pillStyle
                name: BatteryService.getBatteryIcon()
                size: root.iconSizeLarge
                color: root.batteryColor()
            }

            BatteryPill {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.pillStyle
                vertical: true
                showNumber: false
                thickness: root.iconSizeLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: BatteryService.batteryAvailable && root.verticalDisplayText !== ""
                text: root.verticalDisplayText
                font.pixelSize: Theme.barTextSize(
                    root.barThickness,
                    root.barConfig?.fontScale,
                    root.barConfig?.maximizeWidgetText
                )
                color: Theme.widgetTextColor
                horizontalAlignment: Text.AlignHCenter
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    root.adjustBrightness(event.angleDelta.y);
                    event.accepted = true;
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: panel

            readonly property string timeInfoText: {
                if (!BatteryService.batteryAvailable)
                    return "No battery detected";
                const time = BatteryService.formatTimeRemaining();
                if (time === "Unknown")
                    return "";
                return BatteryService.isCharging
                    ? "Time until full: " + time
                    : "Time remaining: " + time;
            }

            function individualBatteryDetails(battery) {
                const details = [];
                if (battery.healthSupported && battery.healthPercentage > 0)
                    details.push("Health " + Math.round(battery.healthPercentage) + "%");
                if (battery.energyCapacity > 0)
                    details.push("Capacity " + Number(battery.energyCapacity).toFixed(1) + " Wh");

                let seconds = 0;
                if (battery.state === UPowerDeviceState.Charging) {
                    seconds = battery.timeToFull;
                } else if (battery.state === UPowerDeviceState.Discharging
                        && BatteryService.changeRate > 0) {
                    seconds = (3600 * battery.energy) / BatteryService.changeRate;
                }
                if (seconds > 0 && seconds <= 86400) {
                    const hours = Math.floor(seconds / 3600);
                    const minutes = Math.floor((seconds % 3600) / 60);
                    details.push(hours > 0
                        ? hours + "h " + minutes + "m"
                        : minutes + "m");
                }
                return details.join(" | ");
            }

            headerText: "Battery"
            detailsText: timeInfoText
            showCloseButton: true
            headerActions: Component {
                DankActionButton {
                    id: refreshButton

                    iconName: "refresh"
                    tooltipText: root.conservationBusy
                        ? "Checking conservation mode"
                        : "Refresh conservation mode"
                    enabled: !root.conservationBusy
                    onClicked: root.refreshConservation()

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.conservationBusy

                        onRunningChanged: {
                            if (!running)
                                refreshButton.rotation = 0;
                        }
                    }
                }
            }

            Connections {
                target: panel.parentPopout
                function onShouldBeVisibleChanged() {
                    if (panel.parentPopout?.shouldBeVisible)
                        root.refreshConservation();
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledRect {
                    width: parent.width
                    height: 72
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: BatteryService.getBatteryIcon()
                            size: Theme.iconSizeLarge
                            color: {
                                if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                    return Theme.error;
                                if (BatteryService.isCharging || BatteryService.isPluggedIn)
                                    return Theme.primary;
                                return Theme.surfaceText;
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.iconSizeLarge - Theme.spacingM
                            spacing: Theme.spacingXXS

                            Row {
                                spacing: Theme.spacingS

                                StyledText {
                                    text: BatteryService.batteryAvailable
                                        ? BatteryService.batteryLevel + "%"
                                        : "Power"
                                    font.pixelSize: Theme.fontSizeXLarge
                                    font.weight: Font.Bold
                                    color: BatteryService.isLowBattery && !BatteryService.isCharging
                                        ? Theme.error
                                        : (BatteryService.isCharging ? Theme.primary : Theme.surfaceText)
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: BatteryService.batteryAvailable
                                    text: BatteryService.batteryStatus
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: BatteryService.isLowBattery && !BatteryService.isCharging
                                        ? Theme.error
                                        : (BatteryService.isCharging ? Theme.primary : Theme.surfaceText)
                                }
                            }

                            StyledText {
                                visible: BatteryService.batteryAvailable
                                    && Math.abs(BatteryService.changeRate) > 0.05
                                text: {
                                    const onAc = BatteryService.isCharging || BatteryService.isPluggedIn;
                                    const prefix = onAc ? "+" : "-";
                                    return prefix + Math.abs(BatteryService.changeRate).toFixed(1) + "W";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: BatteryService.isCharging || BatteryService.isPluggedIn
                                    ? Theme.primary
                                    : Theme.warning
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: BatteryService.batteryAvailable

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.nestedSurface
                        border.width: 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Health"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.primary
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: BatteryService.batteryHealth
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: {
                                    if (BatteryService.batteryHealth === "N/A")
                                        return Theme.surfaceText;
                                    return parseInt(BatteryService.batteryHealth, 10) < 80
                                        ? Theme.error
                                        : Theme.surfaceText;
                                }
                            }
                        }
                    }

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.nestedSurface
                        border.width: 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Capacity"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.primary
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: BatteryService.batteryCapacity > 0
                                    ? BatteryService.batteryCapacity.toFixed(1) + " Wh"
                                    : "Unknown"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: !BatteryService.usePreferred && BatteryService.batteries.length > 1

                    StyledText {
                        text: "Individual batteries"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceTextMedium
                    }

                    Repeater {
                        model: ScriptModel {
                            values: BatteryService.batteries
                        }

                        delegate: StyledRect {
                            id: batteryRow

                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 64
                            radius: Theme.cornerRadius
                            color: Theme.nestedSurface
                            border.width: 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: batteryRow.modelData.state === UPowerDeviceState.Charging
                                        ? "battery_charging_full"
                                        : "battery_full"
                                    size: Theme.iconSize
                                    color: batteryRow.modelData.state === UPowerDeviceState.Charging
                                        ? Theme.primary
                                        : Theme.surfaceText
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                        - Theme.iconSize
                                        - batteryPercent.implicitWidth
                                        - Theme.spacingM * 2
                                    spacing: Theme.spacingXXS

                                    StyledText {
                                        width: parent.width
                                        text: batteryRow.modelData.model || "Battery " + (batteryRow.index + 1)
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: panel.individualBatteryDetails(batteryRow.modelData)
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceTextMedium
                                        elide: Text.ElideRight
                                    }
                                }

                                StyledText {
                                    id: batteryPercent

                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(100 * batteryRow.modelData.percentage) + "%"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }
                            }
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 72
                    radius: Theme.cornerRadius
                    color: root.conservationHasError
                        ? Theme.withAlpha(Theme.error, 0.10)
                        : Theme.nestedSurface
                    border.width: root.conservationHasError ? 1 : 0
                    border.color: Theme.withAlpha(Theme.error, 0.35)

                    DankToggle {
                        anchors.fill: parent
                        checked: root.conservationEnabled
                        toggling: root.conservationBusy
                        enabled: root.conservationKnown && !root.conservationBusy
                        text: "Battery conservation mode"
                        description: root.conservationText
                        descriptionColor: root.conservationHasError
                            ? Theme.error
                            : Theme.surfaceVariantText
                        onToggled: checked => root.setConservation(checked)
                    }
                }
            }
        }
    }
}
