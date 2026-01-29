import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../../globals"

Item {
	id: taskbar
	implicitHeight: 44
	implicitWidth: dockBackground.implicitWidth

	Rectangle {
		id: dockBackground
		anchors.fill: parent
		color: Env.colors.primary
		radius: 18
		border.color: Qt.rgba(1, 1, 1, 0.15)
		border.width: 1

		implicitWidth: appRow.implicitWidth + 20
		implicitHeight: appRow.implicitHeight + 16
	}

	Row {
		id: appRow
		spacing: 6
		anchors.centerIn: parent

		Repeater {
			model: TaskbarManager.items

			delegate: Item {
				id: appItem
				implicitWidth: 34
				implicitHeight: 34

				property bool tooltipShown: false

				Timer {
					id: tooltipDelay
					interval: 200
					repeat: false
					onTriggered: appItem.tooltipShown = true
				}

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
					width: 24
					height: 24
					fillMode: Image.PreserveAspectFit
					source: "image://icon/" + modelData.className
				}

				Text {
					anchors.centerIn: parent
					text: modelData.title.slice(0, 1).toUpperCase()
					color: Env.colors.text
					font.pixelSize: 12
					visible: appIcon.status !== Image.Ready
				}

				// Индикатор "запущено"
				Rectangle {
					width: 5
					height: 5
					radius: 4
					color: Qt.rgba(1, 1, 1, 0.8)
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 4
					visible: !!modelData.running
				}

				HoverHandler {
					id: hoveredHandler
					cursorShape: Qt.PointingHandCursor
					onHoveredChanged: {
						if (hovered) {
							tooltipDelay.restart()
						} else {
							tooltipDelay.stop()
							appItem.tooltipShown = false
						}
					}
				}

				// Минималистичный tooltip
				Item {
					id: macTooltip
					anchors.horizontalCenter: parent.horizontalCenter
					y: -28
					visible: appItem.tooltipShown
					opacity: visible ? 1 : 0

					readonly property int maxWidth: 220
					readonly property int padX: 10
					readonly property int padY: 6

					Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
					Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

					onVisibleChanged: y = visible ? -17 : -20

					Rectangle {
						id: tooltipBg
						anchors.centerIn: parent
						radius: 8
						color: Qt.rgba(0, 0, 0, 0.55)
						border.width: 1
						border.color: Qt.rgba(1, 1, 1, 0.12)

						implicitWidth: Math.min(macTooltip.maxWidth, tooltipText.implicitWidth + macTooltip.padX * 2)
						implicitHeight: tooltipText.implicitHeight + macTooltip.padY * 2

						Text {
							id: tooltipText
							anchors.centerIn: parent

							width: tooltipBg.implicitWidth - macTooltip.padX * 2

							text: modelData.title
							color: Qt.rgba(1, 1, 1, 0.92)
							font.pixelSize: 11
							elide: Text.ElideRight
							maximumLineCount: 1
							wrapMode: Text.NoWrap
							clip: true
						}
					}
				}

				// Контекстное меню закрепления
				Menu {
					id: pinMenu
					MenuItem {
						text: TaskbarManager.isPinned(modelData.className) ? "Открепить" : "Закрепить"
						onTriggered: TaskbarManager.togglePinned(modelData.className, modelData.title)
					}
				}

				TapHandler {
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onTapped: (point, button) => {
						if (button === Qt.RightButton) {
							pinMenu.popup();
							return;
						}

						// ЛКМ: фокусим только если запущено
						if (!modelData.running) return;

						const ws = modelData.workspace;
						const addr = modelData.address;

						focusProcess.command = [
							"hyprctl",
							"--batch",
							`dispatch workspace ${ws}; dispatch focuswindow address:${addr}`
						];
						focusProcess.running = true;
					}
				}

				Process {
					id: focusProcess
					running: false
				}
			}
		}
	}
}

