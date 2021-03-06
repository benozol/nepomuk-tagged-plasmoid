import QtQuick 1.0
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.graphicswidgets 0.1 as PlasmaWidgets
import org.kde.plasma.extras 0.1 as PlasmaExtras

Item {
    id: root
    property string tagName: ""
    property string dataEngine: "nepomuk-tagged-engine"
    Component.onCompleted: {
        plasmoid.setAction("reload", "Reload tagged resources", "appointment-recurring");
        plasmoid.aspectRatioMode = 0;
	plasmoid.addEventListener('ConfigChanged', configChanged);
    }
    function configChanged() {
        var tagName = plasmoid.readConfig("tag", "todo");
        importantStuffSource.disconnectSource(root.tagName);
        plasmoid.writeConfig("tag", tagName);
        root.tagName = tagName
        importantStuffSource.connectSource(tagName);
        importantStuffSource.interval = 500;
        plasmoid.busy = true;
    }
    function action_reload () {
        importantStuffSource.update();
    }
    PlasmaCore.DataSource {
        id: importantStuffSource
        dataEngine: root.dataEngine
        onNewData: {
            interval = 0;
            plasmoid.busy = false;
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
        function update() {
            interval = 100;
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

    Text {
        id: heading
        text: "<i>"+(root.tagName ? "<font color='#888'>#</font>" + root.tagName : "&lt;not configured&gt;")+"</i>"
        anchors {
            bottomMargin: 2
        }
        color: '#ddd'
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        smooth: true
        style: Text.Raised
    }
    ListView {
        id: listView
        anchors {
            top: heading.bottom
            bottom: root.bottom
        }
        highlightFollowsCurrentItem: true
        width: parent.width
        contentWidth: root.width - (listView.contentHeight > listView.height ? 7 : 0)
        Behavior on contentWidth {
            NumberAnimation {}
        }
        model: importantStuffModel
        delegate: ImportantStuffItem {
            Component.onCompleted: update.connect(importantStuffSource.update)
            dataEngine: root.dataEngine
            plasmoidRoot: root
        }
        clip: true
    }
    Rectangle {
        id: scrollbar
        visible: listView.contentHeight > listView.height 
        anchors.right: listView.right
        y: heading.height + Math.max(0, listView.visibleArea.yPosition * listView.height)
        width: 3
        height: listView.visibleArea.heightRatio * listView.height + Math.min(0, listView.visibleArea.yPosition * listView.height)
        color: "#ccc"
        radius: 1
    }
    clip: true
}
