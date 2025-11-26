import QtQuick 2.15
import QtQuick.Controls 2.15
import "../utils/Formatting.js" as Formatting

Item {
    id: mediaCard
    width: 180
    height: 320
    property var card: ({})

    Column {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            width: parent.width
            height: 260
            radius: 12
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            color: (card.accentColor && card.accentColor.length > 0) ? card.accentColor : "#424242"
            clip: true

            Image {
                anchors.fill: parent
                source: card.thumbnailUrl
                fillMode: Image.PreserveAspectCrop
                visible: card.thumbnailUrl && card.thumbnailUrl.length > 0
                opacity: 0.95
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
}
