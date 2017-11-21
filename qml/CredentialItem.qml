import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

Rectangle {
    property bool expired: true
    property bool isSelected: false
    property var model
    property color textColor: (isSelected
        ? palette.highlightedText
        : palette.windowText
    )
    property bool timerRunning: false
    property color unselectedColor

    signal singleClick(var mouse, var entry)
    signal doubleClick(var mouse, var entry)
    signal refresh(bool force)

    color: {
        if (isSelected) {
            return palette.highlight
        } else {
            return unselectedColor
        }
    }

    Layout.minimumHeight: (
        10 + issuerLbl.height + codeLbl.height + nameLbl.height
            + (hasCustomTimeBar(model.credential) ? 10 : 0)
    )
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop

    MouseArea {
        anchors.fill: parent
        onClicked: singleClick(mouse, model)
        onDoubleClicked: doubleClick(mouse, model)
        acceptedButtons: Qt.RightButton | Qt.LeftButton
    }

    ColumnLayout {
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        anchors.fill: parent
        spacing: 0
        Label {
            id: issuerLbl
            visible: model.credential.issuer != null
                     && model.credential.issuer.length > 0
            text: qsTr("") + model.credential.issuer
            color: textColor
        }
        Label {
            id: codeLbl
            opacity: expired ? 0.6 : 1
            visible: model.code !== null
            text: qsTr("") + getSpacedCredential(model.code && model.code.value)
            font.pointSize: issuerLbl.font.pointSize * 1.8
            color: textColor
        }
        Label {
            id: nameLbl
            text: model.credential.name
            color: textColor
        }
        Timer {
            interval: 100
            repeat: true
            running: timerRunning && hasCustomTimeBar(model.credential)
            triggeredOnStart: true
            onTriggered: {
                var timeLeft = model.code.valid_to - (Date.now() / 1000)
                if (timeLeft <= 0 && customTimeLeftBar.value > 0) {
                    refresh(true)
                }
                customTimeLeftBar.value = timeLeft
            }
        }
        ProgressBar {
            id: customTimeLeftBar
            visible: hasCustomTimeBar(model.credential)
            Layout.topMargin: 3
            Layout.fillWidth: true
            Layout.minimumHeight: 7
            Layout.maximumHeight: 7
            Layout.alignment: Qt.AlignBottom
            maximumValue: model.credential.period || 0
            rotation: 180
        }
    }

    function hasCustomTimeBar(cred) {
        return cred.period !== 30 && (cred.oath_type === 'TOTP' || cred.touch)
    }

    function getSpacedCredential(code) {
        // Add a space in the code for easier reading.
        if (code != null) {
            switch (code.length) {
            case 6:
                // 123 123
                return code.slice(0, 3) + " " + code.slice(3)
            case 7:
                // 1234 123
                return code.slice(0, 4) + " " + code.slice(4)
            case 8:
                // 1234 1234
                return code.slice(0, 4) + " " + code.slice(4)
            default:
                return code
            }
        }
    }

}
