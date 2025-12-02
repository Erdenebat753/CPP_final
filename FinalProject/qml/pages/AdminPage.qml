import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform

Rectangle {
    id: adminPage
    color: "#0B0F1A"
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0F172A" }
        GradientStop { position: 1.0; color: "#0B0F1A" }
    }

    property var usersModel: []
    property var genresModel: []
    property string selectedThumbnailPath: ""
    property string selectedVideoPath: ""
    property int currentSection: 0 // 0 = add movie, 1 = users

    function refreshUsers() {
        usersModel = backend.listUsers()
    }

    function loadGenres() {
        genresModel = backend.listGenres() || []
        if (genreCombo && genresModel.length > 0) {
            genreCombo.currentIndex = 0
        }
    }

    Component.onCompleted: {
        refreshUsers()
        loadGenres()
    }

    Platform.FileDialog {
        id: thumbnailDialog
        title: qsTr("Select thumbnail image")
        nameFilters: [qsTr("Images (*.png *.jpg *.jpeg *.webp *.bmp)"), qsTr("All files (*.*)")]
        onAccepted: selectedThumbnailPath = file
    }

    Platform.FileDialog {
        id: videoDialog
        title: qsTr("Select video file")
        nameFilters: [qsTr("Videos (*.mp4 *.mov *.mkv *.avi)"), qsTr("All files (*.*)")]
        onAccepted: selectedVideoPath = file
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            radius: 12
            color: "#0F172A"
            border.color: "#1E293B"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Text {
                    text: qsTr("Admin")
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    text: qsTr("Manage movies and users without elements overlapping.")
                    color: "#9FB3C8"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1E293B"; opacity: 0.8 }

                ColumnLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Add movie section")
                        background: Rectangle { radius: 10; color: "#111827"; border.color: "#1E293B" }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: currentSection = 0
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Users section")
                        background: Rectangle { radius: 10; color: "#111827"; border.color: "#1E293B" }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: currentSection = 1
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1E293B"; opacity: 0.8 }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Users online")
                        color: "#9FB3C8"
                        font.pixelSize: 12
                    }

                    Text {
                        text: (usersModel || []).length + qsTr(" total")
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Refresh users")
                        background: Rectangle { radius: 10; color: "#4F46E5" }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: refreshUsers()
                    }
                }
            }
        }

        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentSection

            // Add movie view
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: addMovieColumn.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: addMovieColumn
                    width: parent.width
                    spacing: 20
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: qsTr("Admin Dashboard")
                            color: "white"
                            font.pixelSize: 28
                            font.bold: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Text {
                            text: qsTr("Add films, adjust settings, and keep user data tidy.")
                            color: "#9FB3C8"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 12
                        color: "#0F172A"
                        border.color: "#1E293B"
                        border.width: 1

                        ColumnLayout {
                            width: parent.width
                            anchors.margins: 16
                            spacing: 12

                            Text {
                                text: qsTr("Add New Movie")
                                color: "white"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            TextField {
                                id: movieName
                                placeholderText: qsTr("Title")
                                color: "white"
                                Layout.fillWidth: true
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                            }

                        TextArea {
                            id: movieDescription
                            placeholderText: qsTr("Description")
                            color: "white"
                            Layout.fillWidth: true
                            wrapMode: TextEdit.Wrap
                            background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ComboBox {
                                id: genreCombo
                                Layout.fillWidth: true
                                model: genresModel
                                currentIndex: genresModel.length > 0 ? 0 : -1
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                                contentItem: Text {
                                    text: genreCombo.displayText
                                    color: "white"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }

                            SpinBox {
                                id: runtime
                                from: 0
                                to: 600
                                value: 120
                                editable: true
                                validator: IntValidator { bottom: 0; top: 600 }
                                Layout.preferredWidth: 140
                                textFromValue: function(value) { return value + " min" }
                                valueFromText: function(text) {
                                    var digits = parseInt(text.replace(/[^0-9]/g, ""), 10)
                                    return isNaN(digits) ? runtime.value : digits
                                }
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            TextField {
                                id: newGenreField
                                placeholderText: qsTr("New genre name")
                                color: "white"
                                Layout.fillWidth: true
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                            }
                            Button {
                                text: qsTr("Add genre")
                                Layout.preferredWidth: 120
                                background: Rectangle { radius: 8; color: "#1E293B" }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    const response = backend.addGenre(newGenreField.text)
                                    genreStatus.text = response.message || ""
                                    if (response.success) {
                                        newGenreField.text = ""
                                        loadGenres()
                                    }
                                }
                            }
                            Button {
                                text: qsTr("Refresh")
                                Layout.preferredWidth: 90
                                background: Rectangle { radius: 8; color: "#1E293B" }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: loadGenres()
                            }
                        }

                        Text {
                            id: genreStatus
                            color: "#A5B4FC"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            TextField {
                                id: thumbnailField
                                placeholderText: qsTr("Thumbnail path (optional)")
                                color: "white"
                                Layout.fillWidth: true
                                readOnly: true
                                text: selectedThumbnailPath
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                            }

                            Button {
                                text: qsTr("Browse")
                                Layout.preferredWidth: 110
                                background: Rectangle { radius: 8; color: "#1E293B" }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: thumbnailDialog.open()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            TextField {
                                id: videoField
                                placeholderText: qsTr("Video path (optional)")
                                color: "white"
                                Layout.fillWidth: true
                                readOnly: true
                                text: selectedVideoPath
                                background: Rectangle { radius: 8; color: "#111827"; border.color: "#1E293B" }
                            }

                            Button {
                                text: qsTr("Browse")
                                Layout.preferredWidth: 110
                                background: Rectangle { radius: 8; color: "#1E293B" }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: videoDialog.open()
                            }
                        }

                        Button {
                            id: addMovieButton
                            text: qsTr("Add movie")
                                Layout.fillWidth: true
                                padding: 12
                                background: Rectangle { radius: 10; color: "#4F46E5" }
                                contentItem: Text {
                                    text: addMovieButton.text
                                    color: "white"
                                    font.pixelSize: 16
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            onClicked: {
                                    const chosenGenre = genreCombo.currentIndex >= 0 ? genreCombo.currentText : ""
                                    const response = backend.addMovie(
                                                        movieName.text,
                                                        movieDescription.text,
                                                        chosenGenre,
                                                        runtime.value,
                                                        selectedThumbnailPath,
                                                        selectedVideoPath)
                                    addStatus.text = response.message || ""
                                    if (response.success) {
                                        movieName.text = ""
                                        movieDescription.text = ""
                                        selectedThumbnailPath = ""
                                        selectedVideoPath = ""
                                        runtime.value = 120
                                        genreCombo.currentIndex = genresModel.length > 0 ? 0 : -1
                                    }
                                }
                            }

                            Text {
                                id: addStatus
                                color: "#A5B4FC"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // Users view
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: usersColumn.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: usersColumn
                    width: parent.width
                    spacing: 16
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: qsTr("Users")
                            color: "white"
                            font.pixelSize: 28
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Button {
                            text: qsTr("Refresh")
                            onClicked: refreshUsers()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 12
                        color: "#0F172A"
                        border.color: "#1E293B"
                        border.width: 1

                        ColumnLayout {
                            width: parent.width
                            anchors.margins: 16
                            spacing: 10

                            ListView {
                                id: usersList
                                Layout.fillWidth: true
                                Layout.preferredHeight: 500
                                model: usersModel || []
                                clip: true
                                delegate: Rectangle {
                                    width: parent ? parent.width : usersList.width
                                    height: 60
                                    color: index % 2 === 0 ? "#0B1220" : "#0E1525"
                                    radius: 8
                                    border.color: "#1E293B"
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12
                                        Text { text: modelData.email || ""; color: "white"; Layout.fillWidth: true }
                                        Text { text: modelData.role || ""; color: "#93C5FD" }
                                        Text { text: modelData.createdAt || ""; color: "#9FB3C8" }
                                    }
                                }
                                footer: Component {
                                    Text {
                                        text: qsTr("No users yet.")
                                        color: "#9FB3C8"
                                        horizontalAlignment: Text.AlignHCenter
                                        width: usersList.width
                                        visible: (usersList.count === 0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
