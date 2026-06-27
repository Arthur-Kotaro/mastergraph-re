import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Rectangle
{
    id: appToolBar
    height: 40
    color: "#e0e0e0"
    z: 10

    RowLayout
    {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 5

        Button
        {
            text: "Файл"
            Layout.preferredWidth: 65
            onClicked: fileMenu.popup()
            Menu
            {
                id: fileMenu
                MenuItem { text: "Создать"; onTriggered: { mainWindow.newProjectDialog.refreshData(); mainWindow.newProjectDialog.open() } }
                MenuItem { text: "Открыть"; onTriggered: mainWindow.openFileDialog.open() }
                MenuSeparator {}
                MenuItem { text: "Сохранить"; onTriggered: { if(projectController && projectController.inEditMode) projectController.saveProject() } }
                MenuItem { text: "Сохранить как"; onTriggered: { if(projectController && projectController.inEditMode) mainWindow.saveAsDialog.open() } }
                MenuSeparator {}
                MenuItem { text: "Выход"; onTriggered: Qt.quit() }
            }
        }

        Button
        {
            text: "Вид"
            Layout.preferredWidth: 55
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
            Layout.preferredWidth: 95
            onClicked: mainWindow.settingsDialog.open()
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 5 }

        Button
        {
            text: "Добавить каскад"
            Layout.preferredWidth: 145
            font.pixelSize: 12
            onClicked: mainWindow.cascadeDialog.open()
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 5 }

        Button
        {
            text: "Блокировка"
            checked: projectController ? projectController.settingsManager.editingLocked : false
            onCheckedChanged: { if (projectController) projectController.settingsManager.editingLocked = checked }
            checkable: true
            Layout.preferredWidth: 105
            font.pixelSize: 12
        }

        Button
        {
            text: "Зависимости"
            checked: true
            checkable: true
            Layout.preferredWidth: 110
            onCheckedChanged: { if(mainWindow && mainWindow.gridArea) mainWindow.gridArea.showDependencies = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Переносы"
            checked: true
            checkable: true
            Layout.preferredWidth: 95
            onCheckedChanged:
            {
                if (mainWindow && mainWindow.gridArea)
                    mainWindow.gridArea.showTaskHistory = checked
                if (mainWindow.calendarHeader && mainWindow.calendarHeader.milestoneBar)
                    mainWindow.calendarHeader.milestoneBar.showRescheduled = checked
            }
            font.pixelSize: 12
        }

        Button
        {
            text: "Комментарии"
            checked: true
            checkable: true
            Layout.preferredWidth: 115
            onCheckedChanged: { if(mainWindow && mainWindow.gridArea) mainWindow.gridArea.showComments = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "🔄"
            Layout.preferredWidth: 50
            font.pixelSize: 18
            onClicked:
            {
                if (mainWindow && mainWindow.gridArea)
                    mainWindow.gridArea.updateData()
                if (mainWindow && mainWindow.calendarHeader && mainWindow.calendarHeader.milestoneBar && mainWindow.calendarHeader.milestoneBar.canvas)
                    mainWindow.calendarHeader.milestoneBar.canvas.requestPaint()
            }
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 5 }

        Button
        {
            text: "Помощь"
            Layout.preferredWidth: 80
            onClicked: mainWindow.helpDialog.open()
        }

        Button
        {
            text: "О программе"
            Layout.preferredWidth: 115
            onClicked: mainWindow.aboutDialog.open()
        }
    }
}
