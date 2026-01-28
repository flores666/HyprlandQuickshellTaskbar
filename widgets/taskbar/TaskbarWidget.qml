import QtQuick
import QtQuick.Controls
import "../../globals"

Rectangle {
	id: taskbar
	height: parent.height
	width: parent.width
	color: Env.colors.primary

	Row {
		id: appRow
		spacing: 8
		anchors.centerIn: parent

		Repeater {
			model: TaskbarManager.clients

			delegate: Rectangle {
				height: parent.height * 0.7
				radius: 10
				color: Env.colors.secondary
				border.color: Env.colors.primary
				border.width: 2

				Text {
					id: titleText
					text: modelData.title
					color: "white"
					elide: Text.ElideRight
					anchors.centerIn: parent
					anchors.margins: 6
				}

				implicitWidth: Math.max(120, textMetrics.width + 24)

				TextMetrics {
					id: textMetrics
					text: modelData.title
					font: titleText.font
				}
			}
		}
	}
}
