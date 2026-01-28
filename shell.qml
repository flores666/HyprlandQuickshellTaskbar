import QtQuick
import Quickshell
import "widgets/taskbar"
import "globals"

Variants {
	model: Quickshell.screens;

	delegate: Component {
		PanelWindow {
			property var modelData
			screen: modelData

			anchors {
				bottom: true
				horizontalCenter: true
				bottomMargin: 12
			}

			exclusiveZone: 0
			implicitHeight: taskbarPanel.implicitHeight
			implicitWidth: taskbarPanel.implicitWidth

			Rectangle {
				id: taskbarPanel
				color: "transparent"
				implicitWidth: taskbarWidget.implicitWidth
				implicitHeight: taskbarWidget.implicitHeight
				anchors {
					fill: parent
				}

				TaskbarWidget {
					id: taskbarWidget
					anchors.centerIn: parent
				}
			}
		}
	}
}
