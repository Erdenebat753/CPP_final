import QtQuick 2.15
import QtQuick.Controls 2.15
import "../utils/Formatting.js" as Formatting

Item {
    id: mediaCard
    width: 180
    height: 320
    property var card: ({})
    signal clicked(var card)
    property bool imageReady: false
    property color fallbackColor: "#111827"

    onCardChanged: imageReady = false

    Column {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            width: parent.width
            height: 260
            radius: 12
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            color: fallbackColor
            clip: true

            Image {
                anchors.fill: parent
                source: card && card.thumbnailUrl ? card.thumbnailUrl : ""
                fillMode: Image.PreserveAspectCrop
                opacity: 0.95
                asynchronous: true
                cache: true
                onSourceChanged: imageReady = false
                onStatusChanged: {
                    imageReady = (status === Image.Ready)
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#1F2937"
                opacity: imageReady ? 0 : 0.9
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: qsTr("No Image")
                        color: "#C7D1E5"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        Text {
            text: card.title || ""
            color: "white"
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            text: Formatting.joinWithBullet(card.genre, card.duration)
            color: "#B0BEC5"
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mediaCard.clicked(card)
        cursorShape: Qt.PointingHandCursor
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: clickArea.containsMouse ? 0.05 : 0
        }
    }
}
