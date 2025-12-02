import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: moviesPage
    property var categoriesModel: []
    property string userEmail: ""
    property var selectedItem: ({})
    property bool showDetails: false
    property string actionStatus: ""
    property var playHandler: null

    function filteredCategories() {
        const result = []
        const list = categoriesModel || []
        for (let i = 0; i < list.length; i++) {
            const cat = list[i] || {}
            const items = (cat.items || []).filter(function(it) {
                const t = (it.type || "").toLowerCase()
                return t === "" || t === "movie"
            })
            if (items.length > 0) {
                result.push({ name: cat.name, items: items })
            }
        }
        return result
    }

    Flickable {
        id: contentArea
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !showDetails

        Column {
            id: contentColumn
            width: parent.width
            spacing: 24
            property int horizontalPadding: 32
            anchors.top: parent.top
            anchors.topMargin: 24

            Rectangle {
                width: parent.width
                height: 60
                color: "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: contentColumn.horizontalPadding
                    spacing: 12
                    Text {
                        text: qsTr("Movies")
                        color: "white"
                        font.pixelSize: 28
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }
            }

            Repeater {
                model: filteredCategories()
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
                        delegate: MediaCard {
                            card: modelData || ({})
                            onClicked: {
                                selectedItem = modelData || ({})
                                actionStatus = ""
                                showDetails = true
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: showDetails
        color: Qt.rgba(0, 0, 0, 0.65)
        z: 10

        MouseArea {
            id: moviesBackdrop
            anchors.fill: parent
            onClicked: {
                const p = detailCardMovies.mapFromItem(moviesBackdrop, mouse.x, mouse.y)
                if (p.x < 0 || p.y < 0 || p.x > detailCardMovies.width || p.y > detailCardMovies.height) {
                    showDetails = false
                }
            }
        }

        Rectangle {
            id: detailCardMovies
            width: Math.min(parent.width - 120, 900)
            height: Math.min(parent.height - 120, 620)
            radius: 16
            anchors.centerIn: parent
            color: "#0F172A"
            border.color: "#1E293B"
            border.width: 1
            z: 11

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        width: 240
                        height: 150
                        radius: 12
                        color: selectedItem.accentColor || "#1E293B"
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: selectedItem.thumbnailUrl || ""
                            visible: selectedItem.thumbnailUrl && selectedItem.thumbnailUrl !== ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: selectedItem.title || ""; color: "white"; font.pixelSize: 24; font.bold: true; wrapMode: Text.Wrap }
                        Text { text: selectedItem.genre || ""; color: "#A5B4FC"; font.pixelSize: 13 }
                        Text { text: selectedItem.duration || ""; color: "#C7D1E5"; font.pixelSize: 13 }
                        Text {
                            text: selectedItem.description || qsTr("No description available.")
                            color: "#E5E7EB"
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1E293B"; opacity: 0.7 }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1E293B"; opacity: 0.7 }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: qsTr("More info")
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: selectedItem.description || qsTr("No additional info.")
                        color: "#9FB3C8"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Button {
                        text: qsTr("Play")
                        Layout.preferredWidth: 120
                        enabled: selectedItem && selectedItem.videoUrl && selectedItem.videoUrl.length > 0
                        onClicked: {
                            if (playHandler && selectedItem && selectedItem.videoUrl) {
                                playHandler(selectedItem.videoUrl, selectedItem.title || "")
                            }
                        }
                    }
                    Button {
                        text: qsTr("Add to My List")
                        enabled: userEmail && userEmail.length > 0
                        Layout.preferredWidth: 150
                        onClicked: {
                            const resp = backend.addToMyList(userEmail, selectedItem.title || "")
                            actionStatus = resp.message || ""
                        }
                    }
                    Button {
                        text: qsTr("Close")
                        Layout.preferredWidth: 120
                        onClicked: {
                            showDetails = false
                        }
                    }
                    Text {
                        text: actionStatus
                        color: "#A5B4FC"
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
