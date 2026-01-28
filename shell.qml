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
				left: true
				right: true
			}

			implicitHeight: 20

			Rectangle {
				id: taskbarPanel
				color: Env.colors.primary
				anchors {
					fill: parent
				}

				TaskbarWidget {
					anchors.fill: parent
				}
			}
		}
	}
}
