import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "qml/components"
import "qml/pages"

Window {
    id: root
    property bool authenticated: false
    property string activeRole: ""
    property string activeAuthMode: "login"

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
    }

    HomePage {
        id: homePage
        anchors.top: navigationBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.authenticated
        heroItem: heroItem
        categoriesModel: categoriesModel
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
        }
    }
}
