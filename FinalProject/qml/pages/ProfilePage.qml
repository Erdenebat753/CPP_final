import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: profilePage
    property string userEmail: ""
    property var profileData: ({})

    color: "#0B0F1A"
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0F172A" }
        GradientStop { position: 1.0; color: "#0B0F1A" }
    }

    function refreshProfile() {
        if (!userEmail || userEmail.trim() === "")
            return
        profileData = backend.userProfile(userEmail)
    }

    onUserEmailChanged: refreshProfile()
    Component.onCompleted: refreshProfile()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: Math.min(parent.width - 48, 1080)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24
            spacing: 18

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    width: 72; height: 72; radius: 36
                    color: "#111827"
                    border.color: "#1E293B"
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: (profileData.profiles && profileData.profiles.length > 0 && profileData.profiles[0].avatarUrl) ? profileData.profiles[0].avatarUrl : ""
                        visible: source !== ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: qsTr("Profile"); color: "white"; font.pixelSize: 26; font.bold: true }
                    Text { text: userEmail || qsTr("Unknown user"); color: "#9FB3C8"; font.pixelSize: 14 }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            height: 26; radius: 13; color: "#0F172A"; border.color: "#1E293B"
                            Text { anchors.centerIn: parent; text: qsTr("Role: %1").arg(profileData.user ? profileData.user.role : "user"); color: "#C7D1E5"; font.pixelSize: 12 }
                        }
                        Rectangle {
                            height: 26; radius: 13; color: "#0F172A"; border.color: "#1E293B"
                            Text { anchors.centerIn: parent; text: qsTr("Created: %1").arg(profileData.user ? profileData.user.createdAt : qsTr("N/A")); color: "#C7D1E5"; font.pixelSize: 12 }
                        }
                    }
                }

                Button {
                    text: qsTr("Refresh")
                    Layout.preferredWidth: 110
                    onClicked: refreshProfile()
                }
            }

            // Stats row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: [
                        { title: qsTr("Profiles"), value: (profileData.counts && profileData.counts.profiles) || 0 },
                        { title: qsTr("Watch history"), value: (profileData.counts && profileData.counts.history) || 0 },
                        { title: qsTr("My list"), value: (profileData.counts && profileData.counts.myList) || 0 }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        radius: 12
                        color: "#0F172A"
                        border.color: "#1E293B"
                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6
                            Text { text: modelData.title; color: "#9FB3C8"; font.pixelSize: 12 }
                            Text { text: modelData.value; color: "white"; font.pixelSize: 24; font.bold: true }
                        }
                    }
                }
            }

            // Main grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 16

                // Subscription
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    radius: 12
                    color: "#0F172A"
                    border.color: "#1E293B"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text { text: qsTr("Subscription"); color: "white"; font.pixelSize: 18; font.bold: true; Layout.fillWidth: true }
                            Rectangle {
                                radius: 10
                                height: 26
                                width: 90
                                color: (profileData.subscription && profileData.subscription.active) ? "#14532D" : "#4B1E1E"
                                border.color: "#1E293B"
                                Text {
                                    anchors.centerIn: parent
                                    text: (profileData.subscription && profileData.subscription.active) ? qsTr("Active") : qsTr("Inactive")
                                    color: (profileData.subscription && profileData.subscription.active) ? "#86EFAC" : "#FCA5A5"
                                    font.pixelSize: 12
                                }
                            }
                        }
                        Text {
                            text: profileData.subscription && profileData.subscription.planName ? profileData.subscription.planName : qsTr("No plan")
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            text: profileData.subscription && profileData.subscription.priceMonth
                                  ? qsTr("%1 / month · %2").arg(profileData.subscription.priceMonth).arg(profileData.subscription.maxQuality || qsTr("HD"))
                                  : qsTr("No subscription on record.")
                            color: "#C7D1E5"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: profileData.subscription && profileData.subscription.startDate
                            text: qsTr("Start: %1   End: %2")
                                  .arg(profileData.subscription ? profileData.subscription.startDate || qsTr("N/A") : qsTr("N/A"))
                                  .arg(profileData.subscription ? profileData.subscription.endDate || qsTr("N/A") : qsTr("N/A"))
                            color: "#9FB3C8"
                            font.pixelSize: 12
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1E293B"; opacity: 0.6 }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: qsTr("Pick a plan"); color: "white"; font.pixelSize: 14; font.bold: true }
                            ComboBox {
                                id: planCombo
                                Layout.fillWidth: true
                                model: backend.listPlans()
                                textRole: "name"
                            }
                            Button {
                                text: qsTr("Subscribe")
                                Layout.preferredWidth: 140
                                onClicked: {
                                    if (planCombo.currentIndex >= 0) {
                                        const plan = planCombo.model[planCombo.currentIndex]
                                        const resp = backend.subscribePlan(profilePage.userEmail, plan.id)
                                        statusMessage.text = resp.message || ""
                                        if (resp.success) refreshProfile()
                                    }
                                }
                            }
                            Text {
                                id: statusMessage
                                color: "#A5B4FC"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Profiles
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    radius: 12
                    color: "#0F172A"
                    border.color: "#1E293B"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10
                        Text { text: qsTr("Profiles"); color: "white"; font.pixelSize: 18; font.bold: true }
                        ListView {
                            id: profilesList
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            clip: true
                            model: profileData.profiles || []
                            delegate: Rectangle {
                                width: parent ? parent.width : profilesList.width
                                height: 56
                                radius: 8
                                color: index % 2 === 0 ? "#0B1220" : "#0E1525"
                                border.color: "#1E293B"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    Rectangle {
                                        width: 32; height: 32; radius: 16
                                        color: (modelData.avatarUrl && modelData.avatarUrl !== "") ? "#1E293B" : "#111827"
                                        border.color: "#1E293B"
                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: modelData.avatarUrl || ""
                                            visible: (modelData.avatarUrl && modelData.avatarUrl !== "")
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.name || ""; color: "white"; font.pixelSize: 14; font.bold: true }
                                        Text {
                                            text: (modelData.isKid ? qsTr("Kid") : qsTr("Standard")) + " \u2022 " + (modelData.createdAt || "")
                                            color: "#9FB3C8"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                            footer: Component {
                                Text {
                                    text: qsTr("No profiles yet.")
                                    color: "#9FB3C8"
                                    horizontalAlignment: Text.AlignHCenter
                                    width: profilesList.width
                                    visible: profilesList.count === 0
                                }
                            }
                        }
                    }
                }

                // My list
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 230
                    radius: 12
                    color: "#0F172A"
                    border.color: "#1E293B"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10
                        Text { text: qsTr("My list"); color: "white"; font.pixelSize: 18; font.bold: true }
                        ListView {
                            id: myListView
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            model: profileData.myList || []
                            clip: true
                            delegate: Rectangle {
                                width: parent ? parent.width : myListView.width
                                height: 68
                                radius: 8
                                color: index % 2 === 0 ? "#0B1220" : "#0E1525"
                                border.color: "#1E293B"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    Rectangle {
                                        width: 68; height: 46; radius: 8
                                        color: modelData.accentColor || "#1E293B"
                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: modelData.thumbnailUrl || ""
                                            visible: (modelData.thumbnailUrl && modelData.thumbnailUrl !== "")
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.title || ""; color: "white"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight }
                                        Text { text: qsTr("%1 min").arg(modelData.runtime || 0); color: "#9FB3C8"; font.pixelSize: 11 }
                                        Text { text: qsTr("Added %1").arg(modelData.addedAt || ""); color: "#7587A8"; font.pixelSize: 11 }
                                    }
                                }
                            }
                            footer: Component {
                                Text {
                                    text: qsTr("No saved titles yet.")
                                    color: "#9FB3C8"
                                    horizontalAlignment: Text.AlignHCenter
                                    width: myListView.width
                                    visible: myListView.count === 0
                                }
                            }
                        }
                    }
                }

                // Watch history
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 230
                    radius: 12
                    color: "#0F172A"
                    border.color: "#1E293B"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10
                        Text { text: qsTr("Watch history"); color: "white"; font.pixelSize: 18; font.bold: true }
                        ListView {
                            id: historyList
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            model: profileData.history || []
                            clip: true
                            delegate: Rectangle {
                                width: parent ? parent.width : historyList.width
                                height: 68
                                radius: 8
                                color: index % 2 === 0 ? "#0B1220" : "#0E1525"
                                border.color: "#1E293B"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    Rectangle {
                                        width: 62; height: 46; radius: 8
                                        color: "#111827"
                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: modelData.thumbnailUrl || ""
                                            visible: (modelData.thumbnailUrl && modelData.thumbnailUrl !== "")
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.title || ""; color: "white"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight }
                                        Text {
                                            text: qsTr("Progress %1 / %2 min").arg(Math.floor((modelData.positionSec || 0) / 60)).arg(modelData.runtime || 0)
                                            color: "#9FB3C8"
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            text: (modelData.finished ? qsTr("Finished") : qsTr("In progress")) + " \u2022 " + (modelData.updatedAt || "")
                                            color: modelData.finished ? "#86EFAC" : "#FACC15"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                            footer: Component {
                                Text {
                                    text: qsTr("No viewing history yet.")
                                    color: "#9FB3C8"
                                    horizontalAlignment: Text.AlignHCenter
                                    width: historyList.width
                                    visible: historyList.count === 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
