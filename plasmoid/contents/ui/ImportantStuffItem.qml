import QtQuick 1.1
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.components 0.1 as PlasmaComponents
import org.kde.qtextracomponents 0.1 as QtExtraComponents
import org.kde.plasma.extras 0.1 as PlasmaExtras

PlasmaComponents.ListItem {
    id: root
    enabled: true
    signal update
    property string dataEngine
    property Item plasmoidRoot
    PlasmaCore.DataSource {
        id: dataSource
        dataEngine: root.dataEngine
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onDoubleClicked: Qt.openUrlExternally(url)
    }
    PlasmaCore.ToolTip {
        id: tooltip
        target: root
        image: "dialog-information"
        mainText: "Resource data"
        function formatted() {
            function aux(attribute, value) {
                return ((value !== undefined) && ("<font color='#999'>"+attribute+":</font> <i>"+value+"</i><br/>")) || ""
            }
            var res =
              aux('description', description) +
              aux('subject', subject) +
              aux('fileName', fileName) +
              aux('url', url) +
              aux('type', type) +
              aux('fileUrl', fileUrl) +
              aux('uri', uri) +
              "";
            return res;
        }
        subText: formatted()
    }
    Row {
        id: row
        spacing: 2
        property int size: column.height //titleText.font.pixelSize + subTitleText.font.pixelSize
        QtExtraComponents.QIconItem {
            id: icon
            icon: genericIcon
            width: row.size
            height: row.size
        }
        Column {
            id: column
            width: root.width - 2.2 * row.size
            clip: true
            Text {
                id: titleText
                text: label || fileName || url || uri || ""
                clip: true
                font.pixelSize: 12
                color: "white"
            }
            Text {
                id: subTitleText
                text: from || fileUrl || url || uri || ""
                clip: true
                color: "#bbbbbb"
                font.pixelSize: 8
            }
        }
        Item {
            id: buttons
            property string dialogText: "Remove the tag <i>"+tagName+"</i>?"
            width: row.size
            height: row.size
            QtExtraComponents.QIconItem {
                id: rejectIcon
                icon: "task-reject"
                opacity: 0.4 // rejectMouseArea.containsMouse ? 1.0 : 0.2
                anchors.centerIn: parent
                width: row.size / 2
                height: row.size / 2
                MouseArea {
                    id: rejectMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        removeTagDialog.open();
                    }
                    // onPositionChanged: {
                    //     console.log('onPositionChanged');
                    // }
                }
                // states: State {
                //     name: "hover"
                //     when: rejectMouseArea.containsMouse
                //     PropertyChanges {
                //         target: rejectIcon
                //         opacity: 1.0
                //     }
                // }
                // transitions: Transition {
                //     from: ""; to: "hover"; reversible: true
                //     NumberAnimation { properties: "opacity"; duration: 200; easing.type: Easing.InOutQuad }
                // }
                PlasmaComponents.Dialog {
                    id: removeTagDialog
                    content: [
                        PlasmaExtras.Paragraph {
                            text: buttons.dialogText
                            width: root.width
                        }
                    ]
                    onOpen: dialog.popupPosition(plasmoidRoot.root, Qt.AlignCenter)
                    function finishedDropTag(job) {
                        console.log('finishedDropTag', job);
                        root.update();
                    }
                    onAccepted: {
                        console.log('dropping tag ', tagName, ' from ', uri);
                        var service = dataSource.serviceForSource(tagName);
                        var configGroup = service.operationDescription('remove');
                        configGroup.ressource = uri.toString();
                        var dropJob = service.startOperationCall(configGroup);
                        dropJob.finished.connect(finishedDropTag);
                    }
                    buttons: [
                        Row {
                            spacing: 5
                            PlasmaComponents.Button {
                                text: "yes"
                                onClicked: {
                                    removeTagDialog.accept();
                                }
                                width: root.width/2
                            }
                            PlasmaComponents.Button {
                                text: "no"
                                onClicked: {
                                    removeTagDialog.reject()
                                }
                                width: root.width/2
                            }
                        }
                    ]
                }
            }
        }
    }
}
