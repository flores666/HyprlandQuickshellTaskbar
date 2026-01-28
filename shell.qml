import QtQuick
import Quickshell
import QtQuick.Controls
import "widgets/taskbar"
import "globals"

Variants {
	model: Quickshell.screens

	delegate: Component {
		Item {
			property var modelData
			readonly property var scr: modelData
			property var tooltipSpace: 34

			// --- MAIN TASKBAR WINDOW (появляется/исчезает) ---
			PanelWindow {
				id: taskbarWindow
				screen: scr
				color: "transparent"
				exclusiveZone: 0

				// окно скрыто, когда панель спрятана (чтобы не перехватывать клики)
				visible: false

				anchors { bottom: true }
				margins { bottom: 7 }

				implicitWidth: 3000
				//implicitWidth: taskbarWidget.implicitWidth
				implicitHeight: taskbarWidget.implicitHeight + tooltipSpace

				mask: Region { item: slideContainer }

				Item {
					anchors.fill: parent
					clip: true

					Item {
						id: slideContainer
						width: taskbarWidget.implicitWidth
						height: taskbarWidget.implicitHeight

						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom

						// спрятано: уезжает вниз за границу окна
						anchors.bottomMargin: taskbarController.shown ? 0 : -(height + 14)

						Behavior on anchors.bottomMargin {
							NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
						}

						TaskbarWidget {
							id: taskbarWidget
							anchors.centerIn: parent
						}

						HoverHandler {
							id: panelHover
							acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
							onHoveredChanged: {
								if (hovered) {
									taskbarController.show()
									autoHideTimer.stop()
								} else {
									autoHideTimer.restart()
								}
							}
						}

					}
				}
			}

			// --- TRIGGER WINDOW (тонкая зона внизу экрана) ---
			PanelWindow {
				id: triggerWindow
				screen: scr
				color: "transparent"
				exclusiveZone: 0

				anchors { bottom: true }
				margins { bottom: 0 }

				implicitHeight: 2
				implicitWidth: taskbarWidget.width

				Item {
					anchors.fill: parent

					HoverHandler {
						acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
						onHoveredChanged: {
							if (hovered) taskbarController.show()
						}
					}
				}
			}

			// --- Controller: show/hide + автоскрытие ---
			QtObject {
				id: taskbarController
				property bool shown: false

				function show() {
					if (!taskbarWindow.visible)
					taskbarWindow.visible = true

					shown = true

					// если курсор НЕ на панели — запустим таймер
					if (!panelHover.hovered)
					autoHideTimer.restart()
				}

				function hide() {
					// если курсор на панели — не прячем
					if (panelHover.hovered) return

					shown = false
					hideFinalizeTimer.restart()
				}
			}

			Timer {
				id: autoHideTimer
				interval: 2000
				repeat: false
				onTriggered: taskbarController.hide()
			}

			// дождаться окончания анимации и только потом скрыть окно
			Timer {
				id: hideFinalizeTimer
				interval: 220
				repeat: false
				onTriggered: {
					if (!taskbarController.shown)
					taskbarWindow.visible = false
				}
			}
		}
	}
}

