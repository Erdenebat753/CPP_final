import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: loginPage
    property string mode: "login" // "login" or "signup"
    property string role: "user" // "user" or "admin"
    signal loginSucceeded(string mode, string role, string identifier)

    color: "#0B0F1A"
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0F172A" }
        GradientStop { position: 1.0; color: "#0B0F1A" }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        width: Math.min(parent.width - 80, 420)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: mode === "signup" ? qsTr("Create your account") : qsTr("Welcome back")
                color: "white"
                font.pixelSize: 28
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: qsTr("Choose role and sign in to continue")
                color: "#9FB3C8"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { key: "login", label: qsTr("Login") },
                    { key: "signup", label: qsTr("Sign up") }
                ]
                delegate: Button {
                    property bool active: loginPage.mode === modelData.key
                    Layout.fillWidth: true
                    checkable: true
                    checked: active
                    text: modelData.label
                    background: Rectangle {
                        radius: 10
                        color: active ? "#1E293B" : "#111827"
                        border.color: active ? "#4F46E5" : "#2C2E3A"
                    }
                    contentItem: Text {
                        text: modelData.label
                        color: active ? "white" : "#C7D1E5"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: loginPage.mode = modelData.key
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { key: "user", label: qsTr("User") },
                    { key: "admin", label: qsTr("Admin") }
                ]
                delegate: Button {
                    property bool active: loginPage.role === modelData.key
                    Layout.fillWidth: true
                    checkable: true
                    checked: active
                    text: modelData.label
                    background: Rectangle {
                        radius: 10
                        color: active ? "#0EA5E9" : "#111827"
                        border.color: active ? "#38BDF8" : "#2C2E3A"
                    }
                    contentItem: Text {
                        text: modelData.label
                        color: active ? "white" : "#C7D1E5"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: loginPage.role = modelData.key
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            TextField {
                id: emailField
                placeholderText: qsTr("Email or username")
                color: "white"
                Layout.fillWidth: true
                background: Rectangle {
                    radius: 12
                    color: "#111827"
                    border.color: "#2C2E3A"
                }
            }

            TextField {
                id: passwordField
                placeholderText: qsTr("Password")
                echoMode: TextInput.Password
                color: "white"
                Layout.fillWidth: true
                background: Rectangle {
                    radius: 12
                    color: "#111827"
                    border.color: "#2C2E3A"
                }
            }

            TextField {
                id: confirmField
                visible: loginPage.mode === "signup"
                placeholderText: qsTr("Confirm password")
                echoMode: TextInput.Password
                color: "white"
                Layout.fillWidth: true
                background: Rectangle {
                    radius: 12
                    color: "#111827"
                    border.color: "#2C2E3A"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: submitButton
                Layout.fillWidth: true
                padding: 12
                text: loginPage.mode === "signup" ? qsTr("Create account") : qsTr("Login")
                background: Rectangle {
                    radius: 14
                    color: "#4F46E5"
                }
                contentItem: Text {
                    text: submitButton.text
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    statusLabel.text = ""
                    if (!emailField.text.length || !passwordField.text.length) {
                        statusLabel.text = qsTr("Please fill in all required fields.")
                        return
                    }
                    if (loginPage.mode === "signup" && passwordField.text !== confirmField.text) {
                        statusLabel.text = qsTr("Passwords do not match.")
                        return
                    }
                    loginPage.loginSucceeded(loginPage.mode, loginPage.role, emailField.text)
                }
            }

            Text {
                id: statusLabel
                Layout.fillWidth: true
                color: "#FCA5A5"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }
}
