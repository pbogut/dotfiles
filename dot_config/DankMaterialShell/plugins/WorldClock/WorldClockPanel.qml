import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PopoutComponent {
    id: panel

    property var liveData: ({})
    property bool showLondon: true
    property bool showDubai: false
    property bool previewing: false
    property string selectedTime: ""
    property var previewData: ({})
    property string inputError: ""
    property int requestId: 0
    readonly property var displayData: previewing ? previewData : liveData
    readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("./world-clock.py").toString().replace(/^file:\/\//, ""))

    signal barVisibilityChanged(string city, bool enabled)

    headerText: "World Clock"
    detailsText: (previewing ? "Preview" : "Live") + " · Today " + (liveData.localDate || "") + " · Local " + (liveData.localZone || "")
    showCloseButton: true

    function syncControls(value) {
        if (!timeInput || !timeSlider)
            return;
        if (timeInput.text !== value)
            timeInput.text = value;
        if (/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) {
            const parts = value.split(":");
            timeSlider.value = Math.min(1425, Number(parts[0]) * 60 + Number(parts[1]));
        }
    }

    function reset() {
        requestId++;
        previewTimer.stop();
        previewing = false;
        selectedTime = "";
        previewData = {};
        inputError = "";
        syncControls(liveData.localTime || "");
    }

    function selectTime(value) {
        requestId++;
        previewTimer.stop();
        previewing = true;
        selectedTime = value;
        previewData = {};
        syncControls(value);
        inputError = /^([01]\d|2[0-3]):[0-5]\d$/.test(value) ? "" : "Enter a time from 00:00 to 23:59.";
        if (!inputError)
            previewTimer.restart();
    }

    function selectMinutes(minutes) {
        selectTime(String(Math.floor(minutes / 60)).padStart(2, "0") + ":" + String(minutes % 60).padStart(2, "0"));
    }

    function requestPreview() {
        const serial = requestId;
        Proc.runCommand(null, ["python3", helperPath, "--time", selectedTime], (stdout, exitCode) => {
            if (!panel || serial !== panel.requestId)
                return;
            let data;
            try {
                data = JSON.parse(stdout);
            } catch (_) {
                data = {error: "Unable to convert this time."};
            }
            panel.inputError = data.error || (exitCode !== 0 ? "Time conversion failed." : "");
            panel.previewData = panel.inputError ? {} : data;
        }, 0, 5000);
    }

    function dateLabel(clock) {
        if (!clock)
            return previewing && !inputError ? "Converting…" : "";
        const day = clock.dayOffset < 0 ? "Previous day · " : clock.dayOffset > 0 ? "Next day · " : "";
        return day + clock.date + " · " + clock.zone;
    }

    onLiveDataChanged: {
        if (!previewing)
            syncControls(liveData.localTime || "");
        else if (parentPopout?.shouldBeVisible)
            selectTime(selectedTime);
    }
    Component.onCompleted: reset()
    Component.onDestruction: requestId++

    Connections {
        target: panel.parentPopout
        function onShouldBeVisibleChanged() {
            if (panel.parentPopout.shouldBeVisible)
                panel.reset();
        }
    }

    Timer {
        id: previewTimer
        interval: 60
        onTriggered: panel.requestPreview()
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: ["london", "dubai"]

            StyledRect {
                id: cityCard
                required property string modelData
                readonly property var clock: panel.displayData[modelData]
                width: parent.width
                height: 100
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                StyledText {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    text: cityCard.modelData === "london" ? "🇬🇧 London" : "🇦🇪 Dubai"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                StyledText {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    text: cityCard.clock?.time || "--:--"
                    font.pixelSize: Theme.fontSizeLarge + 4
                    font.weight: Font.Medium
                    color: Theme.primary
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 40
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    text: panel.dateLabel(cityCard.clock)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                DankToggle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacingXS
                    height: 32
                    text: "Show in bar"
                    checked: cityCard.modelData === "london" ? panel.showLondon : panel.showDubai
                    onToggled: checked => panel.barVisibilityChanged(cityCard.modelData, checked)
                }
            }
        }

        Item { width: 1; height: Theme.spacingXS }

        StyledText {
            text: "Time travel"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
        }

        StyledText {
            width: parent.width
            text: "Choose your local time today. Bar clocks stay live."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            DankTextField {
                id: timeInput
                width: parent.width - nowButton.width - parent.spacing
                height: 44
                placeholderText: "HH:MM"
                leftIconName: "schedule"
                maximumLength: 5
                onTextEdited: panel.selectTime(text)
            }

            DankButton {
                id: nowButton
                text: "Now"
                iconName: "restore"
                buttonHeight: 44
                onClicked: panel.reset()
            }
        }

        DankSlider {
            id: timeSlider
            width: parent.width
            minimum: 0
            maximum: 1425
            step: 15
            showValue: false
            unit: ""
            onSliderValueChanged: newValue => panel.selectMinutes(newValue)
        }

        Row {
            width: parent.width

            StyledText {
                width: parent.width / 3
                text: "00:00"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width / 3
                text: "15-minute steps"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width / 3
                text: "23:45"
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        StyledText {
            width: parent.width
            text: panel.inputError || panel.displayData.error || panel.displayData.note || ""
            visible: text !== ""
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeSmall
            color: panel.inputError || panel.displayData.error ? Theme.error : Theme.surfaceVariantText
        }
    }
}
