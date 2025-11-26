import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Flickable {
    id: homePage
    property var heroItem: ({})
    property var categoriesModel: []

    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: contentColumn
        width: parent.width
        spacing: 32
        property int horizontalPadding: 32

        HeroBanner {
            width: Math.max(0, contentColumn.width - contentColumn.horizontalPadding * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            heroItem: homePage.heroItem
        }

        Repeater {
            model: homePage.categoriesModel || []
            delegate: Column {
                width: contentColumn.width
                spacing: 12
                property var category: modelData || ({})

                Item {
                    width: parent.width - contentColumn.horizontalPadding * 2
                    height: titleLabel.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: titleLabel
                        text: category.name || ""
                        color: "white"
                        font.pixelSize: 20
                        font.bold: true
                        anchors.left: parent.left
                    }

                    Text {
                        text: qsTr("See all")
                        color: "#90CAF9"
                        anchors.right: parent.right
                    }
                }

                ListView {
                    width: parent.width - contentColumn.horizontalPadding * 2
                    height: 320
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16
                    orientation: ListView.Horizontal
                    model: category.items || []
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: MediaCard { card: modelData || ({}) }
                }
            }
        }
    }
}
