import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: navigationBar
    property string currentPage: ""
    signal goHome()
    signal openSeries()
    signal openMovies()
    signal openMyList()
    signal openProfile()
    color: Qt.rgba(0, 0, 0, 0.85)
    height: 72
    implicitHeight: height
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined

    RowLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 28

        Label {
            id: brandLabel
            text: qsTr("NEBULA")
            color: "white"
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 6
            Layout.alignment: Qt.AlignVCenter
            MouseArea {
                anchors.fill: parent
                onClicked: navigationBar.goHome()
            }
        }

        Repeater {
            model: [
                { key: "home", label: qsTr("Home") },
                { key: "series", label: qsTr("Series") },
                { key: "movies", label: qsTr("Movies") },
                { key: "mylist", label: qsTr("My List") }
            ]
            delegate: Rectangle {
                color: "transparent"
                radius: 10
                Layout.preferredWidth: implicitWidth + 16
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                border.color: (navigationBar.currentPage === modelData.key) ? "#4F46E5" : "transparent"
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: modelData.label
                        color: (navigationBar.currentPage === modelData.key) ? "white" : "#ECEFF1"
                        font.weight: Font.DemiBold
                        opacity: 0.95
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.key === "home") navigationBar.goHome()
                        else if (modelData.key === "series") navigationBar.openSeries()
                        else if (modelData.key === "movies") navigationBar.openMovies()
                        else if (modelData.key === "mylist") navigationBar.openMyList()
                    }
                }
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
            onClicked: navigationBar.openProfile()
        }
    }
}
