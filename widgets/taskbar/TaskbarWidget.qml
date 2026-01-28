import QtQuick
import QtQuick.Controls
import "../../globals"

Item {
	id: taskbar
	implicitHeight: 64
	implicitWidth: dockBackground.implicitWidth

	Rectangle {
		id: dockBackground
		anchors.fill: parent
		color: Qt.rgba(0.08, 0.08, 0.09, 0.85)
		radius: height / 2
		border.color: Qt.rgba(1, 1, 1, 0.15)
		border.width: 1

		implicitWidth: appRow.implicitWidth + 24
		implicitHeight: appRow.implicitHeight + 16
	}

	Row {
		id: appRow
		spacing: 10
		anchors.centerIn: parent

		Repeater {
			model: TaskbarManager.clients

			delegate: Item {
				id: appItem
				implicitWidth: 44
				implicitHeight: 44

				Rectangle {
					id: iconBackground
					anchors.fill: parent
					radius: 12
					color: Qt.rgba(1, 1, 1, hoveredHandler.hovered ? 0.18 : 0.08)
					border.color: Qt.rgba(1, 1, 1, 0.18)
					border.width: hoveredHandler.hovered ? 1.5 : 1
				}

				Image {
					id: appIcon
					anchors.centerIn: parent
					width: 26
					height: 26
					fillMode: Image.PreserveAspectFit
					source: "image://icon/" + modelData.className
				}

				Text {
					anchors.centerIn: parent
					text: modelData.title.slice(0, 1).toUpperCase()
					color: Env.colors.text
					font.pixelSize: 18
					visible: appIcon.status !== Image.Ready
				}

				Rectangle {
					width: 6
					height: 6
					radius: 3
					color: Qt.rgba(1, 1, 1, 0.8)
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 4
				}

				HoverHandler {
					id: hoveredHandler
				}

				ToolTip.visible: hoveredHandler.hovered
				ToolTip.text: modelData.title
				ToolTip.delay: 200
			}
		}
	}
}
