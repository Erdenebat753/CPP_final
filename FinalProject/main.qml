import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtMultimedia
import "qml/components"
import "qml/pages"

Window {
    id: root
    property bool authenticated: false
    property string activeRole: ""
    property string activeAuthMode: "login"
    property string activePage: "home"
    property string activeUserIdentifier: ""
    property bool showFullPlayer: false
    property string fullPlayerUrl: ""
    property bool showSubPrompt: false
    property string pendingPlayUrl: ""

    width: 1280
    height: 768
    visible: true
    color: "#0D1117"
    title: qsTr("Nebula Streaming")

    NavigationBar {
        id: navigationBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.authenticated
        z: 1
        currentPage: root.activePage
        onGoHome: {
            if (root.activeRole !== "admin") {
                root.activePage = "home"
            }
        }
        onOpenSeries: {
            if (root.activeRole !== "admin") {
                root.activePage = "series"
            }
        }
        onOpenMovies: {
            if (root.activeRole !== "admin") {
                root.activePage = "movies"
            }
        }
        onOpenMyList: {
            if (root.activeRole !== "admin") {
                root.activePage = "mylist"
            }
        }
        onOpenProfile: {
            if (root.activeRole !== "admin") {
                root.activePage = "profile"
            }
        }
    }

    HomePage {
        id: homePage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole !== "admin" && root.activePage === "home"
        heroItem: backend.heroItem
        categoriesModel: backend.categories
        userEmail: root.activeUserIdentifier
        playHandler: function(url) { if (url && url.length > 0) root.handlePlay(url) }
    }

    SeriesPage {
        id: seriesPage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole !== "admin" && root.activePage === "series"
        categoriesModel: backend.categories
        userEmail: root.activeUserIdentifier
        playHandler: function(url) { if (url && url.length > 0) root.handlePlay(url) }
    }

    MoviesPage {
        id: moviesPage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole !== "admin" && root.activePage === "movies"
        categoriesModel: backend.categories
        userEmail: root.activeUserIdentifier
        playHandler: function(url) { if (url && url.length > 0) root.handlePlay(url) }
    }

    MyListPage {
        id: myListPage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole !== "admin" && root.activePage === "mylist"
        userEmail: root.activeUserIdentifier
    }

    AdminPage {
        id: adminPage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole === "admin"
    }

    ProfilePage {
        id: profilePage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated && root.activeRole !== "admin" && root.activePage === "profile"
        userEmail: root.activeUserIdentifier
    }

    LoginPage {
        id: loginPage
        anchors.fill: parent
        visible: !root.authenticated
        z: 2
        onLoginSucceeded: function(mode, role, identifier) {
            root.activeAuthMode = mode
            root.activeRole = role
            root.authenticated = true
            root.activeUserIdentifier = identifier
            if (role !== "admin") {
                root.activePage = "home"
            }
        }
    }

    function startFullPlayer(url) {
        if (!url || url.length === 0) return
        fullPlayerUrl = url
        fullVideo.source = url
        showFullPlayer = true
        fullVideo.play()
    }

    function handlePlay(url, title) {
        if (!url || url.length === 0) return
        if (!root.authenticated) {
            startFullPlayer(url)
            return
        }
        if (root.activeRole === "admin") {
            startFullPlayer(url)
            return
        }
        const profile = backend.userProfile(root.activeUserIdentifier) || {}
        if (profile.subscription && profile.subscription.active) {
            backend.logPlayback(root.activeUserIdentifier, title || "", 0, false)
            startFullPlayer(url)
        } else {
            pendingPlayUrl = url
            showSubPrompt = true
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: showFullPlayer
        color: Qt.rgba(0, 0, 0, 0.85)
        z: 20

        MouseArea {
            anchors.fill: parent
            onClicked: {
                fullVideo.stop()
                showFullPlayer = false
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: qsTr("Playing")
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }
                Button {
                    text: qsTr("Close")
                    onClicked: {
                        fullVideo.stop()
                        showFullPlayer = false
                    }
                }
            }

            Video {
                id: fullVideo
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: VideoOutput.PreserveAspectFit
                autoPlay: false
                source: fullPlayerUrl
            }
        }
    }

    // Subscription prompt overlay
    Rectangle {
        anchors.fill: parent
        visible: showSubPrompt
        color: Qt.rgba(0, 0, 0, 0.75)
        z: 25

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: Math.min(parent.width - 200, 480)
            height: 220
            radius: 14
            color: "#0F172A"
            border.color: "#1E293B"
            anchors.centerIn: parent
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Text { text: qsTr("Subscription required"); color: "white"; font.pixelSize: 20; font.bold: true }
                Text {
                    text: qsTr("You need an active plan to play this title. Go to subscription to pick a plan.")
                    color: "#9FB3C8"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Button {
                        text: qsTr("Go to subscription")
                        Layout.fillWidth: true
                        onClicked: {
                            root.activePage = "profile"
                            showSubPrompt = false
                        }
                    }
                    Button {
                        text: qsTr("Cancel")
                        Layout.preferredWidth: 100
                        onClicked: {
                            showSubPrompt = false
                            pendingPlayUrl = ""
                        }
                    }
                }
            }
        }
    }
}
