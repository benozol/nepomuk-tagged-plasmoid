import QtQuick 1.0
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.graphicswidgets 0.1 as PlasmaWidgets



Item {
    id: root
    property string tagName: "todo"
    Component.onCompleted: {
        plasmoid.setAction("reload", "Reload tagged resources", "appointment-recurring");
        plasmoid.aspectRatioMode = 0;
    }
    function action_reload () {
        console.log('reload');
        importantStuffSource.update();
    }
    PlasmaCore.DataSource {
        id: importantStuffSource
        dataEngine: "nepomuk-tags-engine"
        Component.onCompleted: {
            //plasmoid.busy = true;
            connectSource(root.tagName);
        }
        onNewData: {
            broadcast(data);
        }
        function update() {
            interval = 500;
            //plasmoid.busy = true;
        }
        function broadcast(data) {
            // plasmoid.busy = false;
            interval = 0;
            importantStuffModel.clear();
            for(var label in data) {
                var obj = {}
                obj.tagName = root.tagName;
                for(var key in data[label]) {
                    obj[key] = data[label][key];
                }
                importantStuffModel.append(obj);
            }
        }
        interval: 1000 * 60
    }

    ListModel {
        id: importantStuffModel
        ListElement {
            subject: ""; fileName: ""; url: ""; from: ""; type: ""; label: ""; fileUrl: "";
            uri: ""; genericIcon: ""; description: ""; tagName: ""
        }
    }

    ListView {
        anchors.fill: root
        id: importantStuffList
        width: parent.width
        contentWidth: root.width - 7
        height: parent.height
        model: importantStuffModel
        delegate: ImportantStuffItem {
            Component.onCompleted: update.connect(importantStuffSource.update)
        }
    }

    Rectangle {
        id: scrollbar
        anchors.right: importantStuffList.right
        y: importantStuffList.visibleArea.yPosition * importantStuffList.height
        width: 3
        height: importantStuffList.visibleArea.heightRatio * importantStuffList.height
        color: "#ccc"
        radius: 1
    }
    clip: true
}
