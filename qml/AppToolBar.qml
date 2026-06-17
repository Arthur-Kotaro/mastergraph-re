import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: appToolBar
    height: 40
    color: "#e0e0e0"
    z: 10

    Row
    {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 5

        Button
        {
            text: "Файл"
            onClicked: fileMenu.popup()
            Menu
            {
                id: fileMenu
                MenuItem
                {
                    text: "Создать"
                    onTriggered: { mainWindow.newProjectDialog.refreshData(); mainWindow.newProjectDialog.open() }
                }
                MenuItem
                {
                    text: "Открыть"
                    onTriggered: mainWindow.openFileDialog.open()
                }
                MenuSeparator {}
                MenuItem
                {
                    text: "Сохранить"
                    onTriggered:
                    {
                        if(projectController && projectController.inEditMode)
                            projectController.saveProject()
                    }
                }
                MenuItem
                {
                    text: "Сохранить как"
                    onTriggered:
                    {
                        if(projectController && projectController.inEditMode)
                            mainWindow.saveAsDialog.open()
                    }
                }
                MenuSeparator {}
                MenuItem
                {
                    text: "Выход"
                    onTriggered: Qt.quit()
                }
            }
        }

        Button
        {
            text: "Вид"
            onClicked: viewMenu.popup()
            Menu
            {
                id: viewMenu
                MenuItem
                {
                    text: mainWindow.visibility === Window.FullScreen ? "В окне" : "Весь экран"
                    onTriggered:
                    {
                        if (mainWindow.visibility === Window.FullScreen)
                            mainWindow.showNormal()
                        else
                            mainWindow.showFullScreen()
                    }
                }
                MenuSeparator {}
                MenuItem
                {
                    text: "Трассировка"
                    checkable: true
                    checked: projectController ? projectController.settingsManager.tracingEnabled : false
                    onTriggered:
                    {
                        if(projectController)
                            projectController.settingsManager.tracingEnabled = checked
                    }
                }
                MenuSeparator {}
                MenuItem
                {
                    text: projectController && projectController.settingsManager.zoomLevel === 0 ? "Масштаб: Неделя" : "Масштаб: День"
                    onTriggered:
                    {
                        if(projectController)
                            projectController.settingsManager.setZoomLevel(projectController.settingsManager.zoomLevel === 0 ? 1 : 0)
                    }
                }
            }
        }

        Button
        {
            text: "Настройки"
            onClicked: mainWindow.settingsDialog.open()
        }

        Item { width: 180; height: 1 }

        Button
        {
            text: "Блокировка"
            checkable: true
            font.pixelSize: 12
        }

        Button
        {
            text: "Зависимости"
            checked: true
            checkable: true
            onCheckedChanged: { if(mainWindow && mainWindow.gridArea) mainWindow.gridArea.showDependencies = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Добавить каскад"
            font.pixelSize: 12
            onClicked: mainWindow.cascadeDialog.open()
        }

        Button
        {
            text: "Переносы"
            checkable: true
            onCheckedChanged: { if (mainWindow.calendarHeader) mainWindow.calendarHeader.milestoneBar.showRescheduled = checked }
            font.pixelSize: 12
        }

        Item
        {
            width: appToolBar.width - 1200
            height: 1
        }

        Button
        {
            text: "Помощь"
            onClicked: mainWindow.helpDialog.open()
        }

        Button
        {
            text: "О программе"
            onClicked: mainWindow.aboutDialog.open()
        }
    }
}