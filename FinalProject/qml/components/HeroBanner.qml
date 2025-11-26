import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../utils/Formatting.js" as Formatting

Rectangle {
    id: heroBanner
    property var heroItem: ({})
    property color defaultAccent: "#512DA8"

    width: 0
    height: Math.max(360, heroContent.implicitHeight + 96)
    radius: 24
    clip: true

    property string accent: (heroItem && heroItem.accentColor && heroItem.accentColor.length > 0)
                               ? heroItem.accentColor
                               : defaultAccent

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(heroBanner.accent, 1.3) }
        GradientStop { position: 0.4; color: heroBanner.accent }
        GradientStop { position: 1.0; color: "#0D1117" }
    }

    Image {
        anchors.fill: parent
        source: heroItem.thumbnailUrl
        visible: heroItem && heroItem.thumbnailUrl && heroItem.thumbnailUrl.length > 0
        fillMode: Image.PreserveAspectCrop
        opacity: 0.35
    }

    Column {
        id: heroContent
        anchors.fill: parent
        anchors.margins: 48
        spacing: 16

        Text {
            text: Formatting.joinWithBullet(heroItem.genre, heroItem.rating)
            color: "#B0BEC5"
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 4
            opacity: 0.9
        }

        Text {
            text: heroItem.title || ""
            color: "white"
            font.pixelSize: 42
            font.bold: true
            wrapMode: Text.WordWrap
        }

        Text {
            text: heroItem.description || ""
            color: "#ECEFF1"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }

        Row {
            spacing: 12

            Button {
                id: playButton
                text: qsTr("Play")
                padding: 12
                background: Rectangle {
                    radius: 24
                    color: "white"
                }
                contentItem: Text {
                    text: playButton.text
                    color: "black"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: infoButton
                text: qsTr("More Info")
                padding: 12
                background: Rectangle {
                    radius: 24
                    border.color: Qt.rgba(1, 1, 1, 0.4)
                    border.width: 1
                    color: Qt.rgba(0, 0, 0, 0.5)
                }
                contentItem: Text {
                    text: infoButton.text
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
