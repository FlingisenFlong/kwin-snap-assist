import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

// Small floating recommendation popup, shown centered over one leftover
// screen zone at a time. Picking a window snaps it into that zone.
PlasmaCore.Dialog {
    id: dialog

    signal windowPicked(var window)
    signal dismissed()

    property var targetTile: null
    property int autoHideMs: 7000

    type: PlasmaCore.Dialog.OnScreenDisplay
    flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
    hideOnWindowDeactivate: false
    backgroundHints: PlasmaCore.Types.SolidBackground
    visible: false

    function showFor(tile, candidateWindows) {
        targetTile = tile;
        repeater.model = candidateWindows;

        const geo = tile.absoluteGeometry;
        const w = Math.max(220, Math.min(geo.width - 32, candidateWindows.length * 96 + 24));
        const h = 128;

        dialog.width = w;
        dialog.height = h;
        dialog.x = Math.round(geo.x + (geo.width - w) / 2);
        dialog.y = Math.round(geo.y + (geo.height - h) / 2);
        dialog.visible = true;
        hideTimer.restart();
    }

    onVisibleChanged: {
        if (!visible)
            dismissed();
    }

    Timer {
        id: hideTimer
        interval: dialog.autoHideMs
        onTriggered: dialog.visible = false
    }

    Item {
        id: content
        width: dialog.width
        height: dialog.height
        focus: true

        Keys.onEscapePressed: dialog.visible = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            PlasmaComponents.Label {
                text: qsTr("Snap a window here")
                font.bold: true
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Repeater {
                    id: repeater

                    delegate: PlasmaComponents.ItemDelegate {
                        implicitWidth: 84
                        implicitHeight: 84

                        onClicked: {
                            hideTimer.stop();
                            dialog.windowPicked(modelData);
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            PlasmaCore.IconItem {
                                source: modelData.icon
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                            }

                            PlasmaComponents.Label {
                                text: modelData.caption
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
