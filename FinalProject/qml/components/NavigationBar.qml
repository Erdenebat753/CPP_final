import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: navigationBar
    color: Qt.rgba(0, 0, 0, 0.85)
    height: 72
    implicitHeight: height
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined

    RowLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        Label {
            text: qsTr("NEBULA")
            color: "white"
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 6
            Layout.alignment: Qt.AlignVCenter
        }

        Repeater {
            model: [qsTr("Home"), qsTr("Series"), qsTr("Movies"), qsTr("My List")]
            delegate: Label {
                text: modelData
                color: "#ECEFF1"
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.9
            }
        }

        Item {
            Layout.fillWidth: true
        }

        TextField {
            id: searchField
            placeholderText: qsTr("Search")
            Layout.preferredWidth: 220
            color: "white"
            inputMethodHints: Qt.ImhNoPredictiveText
            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.08)
                radius: 18
                border.color: Qt.rgba(1, 1, 1, 0.2)
            }
        }

        Button {
            id: profileButton
            text: qsTr("Profile")
            padding: 10
            font.bold: true
            background: Rectangle {
                radius: 18
                color: Qt.rgba(1, 1, 1, 0.12)
            }
            contentItem: Text {
                text: profileButton.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
