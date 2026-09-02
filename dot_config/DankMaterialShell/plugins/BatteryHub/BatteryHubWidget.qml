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

    layerNamespacePlugin: "battery-hub"

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

    readonly property var primaryBattery: BatteryService.device
    readonly property bool primaryBatteryAvailable: primaryBattery !== null
    readonly property int primaryBatteryLevel: primaryBatteryAvailable
        ? Math.max(0, Math.min(100, Math.round(primaryBattery.percentage * 100)))
        : 0
    readonly property bool primaryBatteryCharging: primaryBatteryAvailable
        && primaryBattery.state === UPowerDeviceState.Charging
    readonly property bool primaryBatteryLow: primaryBatteryAvailable
        && primaryBatteryLevel <= SettingsData.batteryLowThreshold
    readonly property real primaryBatteryChangeRate: primaryBatteryAvailable
        ? Number(primaryBattery.changeRate || 0)
        : 0
    readonly property string primaryBatteryStatus: primaryBatteryAvailable
        ? BatteryService.translateBatteryState(primaryBattery.state)
        : "No battery"
    readonly property string primaryBatteryHealth: primaryBatteryAvailable
        && primaryBattery.healthSupported
        && primaryBattery.healthPercentage > 0
        ? Math.round(primaryBattery.healthPercentage) + "%"
        : "N/A"
    readonly property real primaryBatteryCapacity: primaryBatteryAvailable
        ? Number(primaryBattery.energyCapacity || 0)
        : 0
    readonly property var additionalLaptopBatteries: BatteryService.batteries.filter(
        battery => battery !== primaryBattery
    )

    readonly property var conservationData: conservation.value || ({})
    readonly property bool conservationAvailable: conservationData.available === true
    readonly property bool conservationKnown: conservationData.known === true
    readonly property bool conservationEnabled: conservationData.enabled === true
    readonly property bool conservationBusy: conservationData.busy === true
    readonly property string conservationText: String(
        conservationData.text || "Battery conservation mode status is unknown."
    )
    readonly property bool conservationHasError: String(conservationData.error || "") !== ""

    readonly property var peripheralData: peripheralBatteries.value || ({})
    readonly property var peripheralDevices: Array.isArray(peripheralData.devices)
        ? peripheralData.devices
        : []
    readonly property bool peripheralRefreshing: peripheralData.refreshing === true
    readonly property bool peripheralHasError: String(peripheralData.error || "") !== ""
    readonly property bool refreshBusy: conservationBusy || peripheralRefreshing
    readonly property bool showPrimaryBarItem: primaryBatteryAvailable || peripheralDevices.length === 0

    readonly property string batteryTimeText: {
        if (showTimeOnlyOnBattery && BatteryService.isPluggedIn)
            return "";
        return formatPrimaryBatteryTime();
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
            return primaryBatteryLevel + "% (" + batteryTimeText + ")";
        if (showPercent)
            return primaryBatteryLevel + "%";
        if (showTime && batteryTimeText)
            return batteryTimeText;
        return "";
    }

    readonly property string verticalDisplayText: {
        if (showPercent && showTime && batteryTimeText)
            return primaryBatteryLevel + "\n" + verticalBatteryTimeText;
        if (showPercent)
            return primaryBatteryLevel.toString();
        if (showTime && batteryTimeText)
            return verticalBatteryTimeText;
        return "";
    }

    readonly property string horizontalSideText: {
        if (!pillStyle)
            return horizontalDisplayText;
        return showTime && batteryTimeText ? batteryTimeText : "";
    }

    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds <= 0 || seconds > 86400)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    function formatPrimaryBatteryTime() {
        if (!primaryBatteryAvailable)
            return "";

        if (primaryBatteryCharging)
            return formatDuration(primaryBattery.timeToFull);
        if (primaryBattery.state === UPowerDeviceState.Discharging
                && primaryBatteryChangeRate > 0) {
            return formatDuration(3600 * primaryBattery.energy / primaryBatteryChangeRate);
        }
        return "";
    }

    function primaryBatteryIcon() {
        if (!primaryBatteryAvailable)
            return "power";

        const level = primaryBatteryLevel;
        if (primaryBatteryCharging || BatteryService.isPluggedIn) {
            if (level >= 90)
                return "battery_charging_full";
            if (level >= 80)
                return "battery_charging_90";
            if (level >= 60)
                return "battery_charging_80";
            if (level >= 50)
                return "battery_charging_60";
            if (level >= 30)
                return "battery_charging_50";
            if (level >= 20)
                return "battery_charging_30";
            return "battery_charging_20";
        }
        if (level >= 95)
            return "battery_full";
        if (level >= 85)
            return "battery_6_bar";
        if (level >= 70)
            return "battery_5_bar";
        if (level >= 55)
            return "battery_4_bar";
        if (level >= 40)
            return "battery_3_bar";
        if (level >= 25)
            return "battery_2_bar";
        return "battery_1_bar";
    }

    function peripheralTypeIcon(type) {
        const normalized = String(type || "").toLowerCase();
        if (normalized === "mouse")
            return "mouse";
        if (normalized === "keyboard")
            return "keyboard";
        return "";
    }

    function peripheralBatteryColor(device) {
        if (device.charging)
            return Theme.primary;
        if (device.lowThreshold > 0 && device.percentage <= device.lowThreshold)
            return Theme.error;
        return Theme.widgetIconColor;
    }

    function batteryColor() {
        if (!primaryBatteryAvailable)
            return Theme.widgetIconColor;
        if (primaryBatteryLow && !primaryBatteryCharging)
            return Theme.error;
        if (primaryBatteryCharging || BatteryService.isPluggedIn)
            return Theme.primary;
        return Theme.widgetIconColor;
    }

    function refreshAvailable() {
        Quickshell.execDetached([
            "dms", "ipc", "call", "battery-hub-conservation", "refresh"
        ]);
        Quickshell.execDetached([
            "dms", "ipc", "call", "battery-hub-devices", "refresh"
        ]);
    }

    function refreshAll() {
        Quickshell.execDetached([
            "dms", "ipc", "call", "battery-hub-conservation", "discover"
        ]);
        Quickshell.execDetached([
            "dms", "ipc", "call", "battery-hub-devices", "discover"
        ]);
    }

    function setConservation(enabled) {
        if (!conservationAvailable)
            return;
        Quickshell.execDetached([
            "dms",
            "ipc",
            "call",
            "battery-hub-conservation",
            enabled ? "enable" : "disable"
        ]);
    }

    function toggleConservation() {
        if (!conservationAvailable)
            return;
        Quickshell.execDetached(["dms", "ipc", "call", "battery-hub-conservation", "toggle"]);
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

    pillRightClickAction: () => {
        if (root.conservationAvailable)
            root.toggleConservation();
    }
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
        readonly property real level: root.primaryBatteryLevel
        readonly property bool charging: root.primaryBatteryCharging
        readonly property bool lowState: root.primaryBatteryLow && !root.primaryBatteryCharging
        readonly property color fillColor: {
            if (!root.primaryBatteryAvailable)
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
                visible: root.primaryBatteryAvailable
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
            "available": false,
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

    PluginGlobalVar {
        id: peripheralBatteries

        varName: "peripheralBatteries"
        defaultValue: ({
            "available": false,
            "devices": [],
            "refreshing": true,
            "error": "",
            "updatedAt": 0
        })
    }

    horizontalBarPill: Component {
        Row {
            spacing: (root.barConfig?.noBackground ?? false) ? 1 : 2

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showPrimaryBarItem && !root.pillStyle
                name: root.primaryBatteryIcon()
                size: root.iconSize
                color: root.batteryColor()
            }

            BatteryPill {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showPrimaryBarItem && root.pillStyle
                vertical: false
                showNumber: root.showPercent
                showPercentSign: root.pillPercentSign
                thickness: root.iconSize
            }

            OfficialBolt {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pillStyle
                    && root.primaryBatteryAvailable
                    && root.primaryBatteryCharging
                fillColor: Theme.primary
                size: Math.round(root.iconSize * 0.85)
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.primaryBatteryAvailable && root.horizontalSideText !== ""
                text: root.horizontalSideText
                font.pixelSize: Theme.barTextSize(
                    root.barThickness,
                    root.barConfig?.fontScale,
                    root.barConfig?.maximizeWidgetText
                )
                color: Theme.widgetTextColor
            }

            Repeater {
                model: root.peripheralDevices

                delegate: Row {
                    id: horizontalPeripheralBattery

                    required property var modelData
                    readonly property string typeIcon: root.peripheralTypeIcon(modelData.type)

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXXS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: horizontalPeripheralBattery.typeIcon !== ""
                        name: horizontalPeripheralBattery.typeIcon
                        size: root.iconSize
                        color: root.peripheralBatteryColor(horizontalPeripheralBattery.modelData)
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: horizontalPeripheralBattery.typeIcon === ""
                        text: String(horizontalPeripheralBattery.modelData.type || "device")
                        font.pixelSize: Theme.barTextSize(
                            root.barThickness,
                            root.barConfig?.fontScale,
                            root.barConfig?.maximizeWidgetText
                        )
                        color: root.peripheralBatteryColor(horizontalPeripheralBattery.modelData)
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: horizontalPeripheralBattery.modelData.percentage + "%"
                        font.pixelSize: Theme.barTextSize(
                            root.barThickness,
                            root.barConfig?.fontScale,
                            root.barConfig?.maximizeWidgetText
                        )
                        color: root.peripheralBatteryColor(horizontalPeripheralBattery.modelData)
                    }
                }
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
                visible: root.showPrimaryBarItem && !root.pillStyle
                name: root.primaryBatteryIcon()
                size: root.iconSizeLarge
                color: root.batteryColor()
            }

            BatteryPill {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.showPrimaryBarItem && root.pillStyle
                vertical: true
                showNumber: false
                thickness: root.iconSizeLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.primaryBatteryAvailable && root.verticalDisplayText !== ""
                text: root.verticalDisplayText
                font.pixelSize: Theme.barTextSize(
                    root.barThickness,
                    root.barConfig?.fontScale,
                    root.barConfig?.maximizeWidgetText
                )
                color: Theme.widgetTextColor
                horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
                model: root.peripheralDevices

                delegate: Column {
                    id: verticalPeripheralBattery

                    required property var modelData
                    readonly property string typeIcon: root.peripheralTypeIcon(modelData.type)

                    spacing: 1

                    DankIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: verticalPeripheralBattery.typeIcon !== ""
                        name: verticalPeripheralBattery.typeIcon
                        size: root.iconSizeLarge
                        color: root.peripheralBatteryColor(verticalPeripheralBattery.modelData)
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: verticalPeripheralBattery.typeIcon === ""
                        text: String(verticalPeripheralBattery.modelData.type || "device")
                        font.pixelSize: Theme.barTextSize(
                            root.barThickness,
                            root.barConfig?.fontScale,
                            root.barConfig?.maximizeWidgetText
                        )
                        color: root.peripheralBatteryColor(verticalPeripheralBattery.modelData)
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: verticalPeripheralBattery.modelData.percentage + "%"
                        font.pixelSize: Theme.barTextSize(
                            root.barThickness,
                            root.barConfig?.fontScale,
                            root.barConfig?.maximizeWidgetText
                        )
                        color: root.peripheralBatteryColor(verticalPeripheralBattery.modelData)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
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
                if (!root.primaryBatteryAvailable) {
                    if (root.peripheralDevices.length > 0)
                        return root.peripheralDevices.length + " peripheral battery device(s)";
                    return "No batteries detected";
                }
                const time = root.formatPrimaryBatteryTime();
                if (!time)
                    return "";
                return root.primaryBatteryCharging
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
                        && battery.changeRate > 0) {
                    seconds = (3600 * battery.energy) / battery.changeRate;
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

            headerText: "Battery Hub"
            detailsText: timeInfoText
            showCloseButton: true
            headerActions: Component {
                DankActionButton {
                    id: refreshButton

                    iconName: "refresh"
                    tooltipText: root.refreshBusy
                        ? "Refreshing battery information"
                        : "Refresh battery information"
                    enabled: !root.refreshBusy
                    onClicked: root.refreshAll()

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.refreshBusy

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
                        root.refreshAvailable();
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledRect {
                    width: parent.width
                    height: 72
                    visible: root.primaryBatteryAvailable
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: root.primaryBatteryIcon()
                            size: Theme.iconSizeLarge
                            color: {
                                if (root.primaryBatteryLow && !root.primaryBatteryCharging)
                                    return Theme.error;
                                if (root.primaryBatteryCharging || BatteryService.isPluggedIn)
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
                                    text: root.primaryBatteryLevel + "%"
                                    font.pixelSize: Theme.fontSizeXLarge
                                    font.weight: Font.Bold
                                    color: root.primaryBatteryLow && !root.primaryBatteryCharging
                                        ? Theme.error
                                        : (root.primaryBatteryCharging ? Theme.primary : Theme.surfaceText)
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.primaryBatteryStatus
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: root.primaryBatteryLow && !root.primaryBatteryCharging
                                        ? Theme.error
                                        : (root.primaryBatteryCharging ? Theme.primary : Theme.surfaceText)
                                }
                            }

                            StyledText {
                                visible: Math.abs(root.primaryBatteryChangeRate) > 0.05
                                text: {
                                    const onAc = root.primaryBatteryCharging || BatteryService.isPluggedIn;
                                    const prefix = onAc ? "+" : "-";
                                    return prefix + Math.abs(root.primaryBatteryChangeRate).toFixed(1) + "W";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: root.primaryBatteryCharging || BatteryService.isPluggedIn
                                    ? Theme.primary
                                    : Theme.warning
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.primaryBatteryAvailable

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
                                text: root.primaryBatteryHealth
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: {
                                    if (root.primaryBatteryHealth === "N/A")
                                        return Theme.surfaceText;
                                    return parseInt(root.primaryBatteryHealth, 10) < 80
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
                                text: root.primaryBatteryCapacity > 0
                                    ? root.primaryBatteryCapacity.toFixed(1) + " Wh"
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
                    visible: root.additionalLaptopBatteries.length > 0

                    StyledText {
                        text: "Additional laptop batteries"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceTextMedium
                    }

                    Repeater {
                        model: ScriptModel {
                            values: root.additionalLaptopBatteries
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

                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: root.peripheralDevices.length > 0 || root.peripheralHasError

                    Row {
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Peripheral batteries"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceTextMedium
                        }

                        StyledText {
                            visible: root.peripheralRefreshing
                            text: "Refreshing..."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    StyledText {
                        width: parent.width
                        visible: root.peripheralHasError
                        text: String(root.peripheralData.error || "Could not refresh peripheral batteries.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.error
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: ScriptModel {
                            values: root.peripheralDevices
                        }

                        delegate: StyledRect {
                            id: peripheralBatteryRow

                            required property var modelData
                            readonly property string typeIcon: root.peripheralTypeIcon(modelData.type)

                            width: parent.width
                            height: 64
                            radius: Theme.cornerRadius
                            color: Theme.nestedSurface
                            border.width: 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                Item {
                                    id: peripheralTypeBadge

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(Theme.iconSize, peripheralTypeText.implicitWidth)
                                    height: Theme.iconSize

                                    DankIcon {
                                        anchors.centerIn: parent
                                        visible: peripheralBatteryRow.typeIcon !== ""
                                        name: peripheralBatteryRow.typeIcon
                                        size: Theme.iconSize
                                        color: root.peripheralBatteryColor(peripheralBatteryRow.modelData)
                                    }

                                    StyledText {
                                        id: peripheralTypeText

                                        anchors.centerIn: parent
                                        visible: peripheralBatteryRow.typeIcon === ""
                                        text: String(peripheralBatteryRow.modelData.type || "device")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: root.peripheralBatteryColor(peripheralBatteryRow.modelData)
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                        - peripheralTypeBadge.width
                                        - peripheralPercent.implicitWidth
                                        - Theme.spacingM * 2
                                    spacing: Theme.spacingXXS

                                    StyledText {
                                        width: parent.width
                                        text: String(peripheralBatteryRow.modelData.name || "Peripheral device")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: String(peripheralBatteryRow.modelData.type || "device")
                                            + (peripheralBatteryRow.modelData.charging
                                                ? " | Charging"
                                                : " | On battery")
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceTextMedium
                                        elide: Text.ElideRight
                                    }
                                }

                                StyledText {
                                    id: peripheralPercent

                                    anchors.verticalCenter: parent.verticalCenter
                                    text: peripheralBatteryRow.modelData.percentage + "%"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: root.peripheralBatteryColor(peripheralBatteryRow.modelData)
                                }
                            }
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 72
                    visible: root.conservationAvailable
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
