import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Rectangle {
    id: myListPage
    color: "#0B0F1A"
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0F172A" }
        GradientStop { position: 1.0; color: "#0B0F1A" }
    }

    property string userEmail: ""
    property var myListModel: []
    property string statusMessage: ""

    function refreshList() {
        if (!userEmail || userEmail.trim() === "")
            return
        const resp = backend.userProfile(userEmail)
        if (resp && resp.myList) {
            myListModel = resp.myList
            statusMessage = ""
        } else {
            statusMessage = qsTr("Unable to load My List")
        }
    }

    Component.onCompleted: refreshList()
    onUserEmailChanged: refreshList()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: Math.min(parent.width - 48, 1120)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text { text: qsTr("My List"); color: "white"; font.pixelSize: 28; font.bold: true; Layout.fillWidth: true }
                Button { text: qsTr("Refresh"); onClicked: refreshList() }
            }

            Text {
                text: statusMessage
                color: "#A5B4FC"
                visible: statusMessage.length > 0
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Flow {
                width: parent.width
                spacing: 16
                Repeater {
                    model: myListModel || []
                    delegate: MediaCard {
                        card: modelData || ({})
                        width: 180
                        height: 320
                        onClicked: {} // no overlay here; view via Movies/Series
                    }
                }
            }

            Text {
                text: qsTr("No saved titles yet.")
                color: "#9FB3C8"
                visible: (myListModel || []).length === 0
                font.pixelSize: 14
            }
        }
    }
}
