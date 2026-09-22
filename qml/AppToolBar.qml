import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Rectangle
{
    id: appToolBar
    height: 40
    color: "#e0e0e0"
    z: 10

    readonly property bool isLocalMode: {
        return projectController && projectController.projectData
               && projectController.projectData.graphKind === 1
    }

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
                MenuItem {
                    text: "Создать"
                    visible: !appToolBar.isLocalMode
                    onTriggered: { mainWindow.newProjectDialog.refreshData(); mainWindow.newProjectDialog.open() }
                }
                MenuItem {
                    text: "Открыть"
                    visible: !appToolBar.isLocalMode
                    onTriggered: mainWindow.openFileDialog.open()
                }
                MenuSeparator { visible: !appToolBar.isLocalMode }
                MenuItem { text: "Сохранить"; onTriggered: { if(projectController && projectController.inEditMode) projectController.saveProject() } }
                MenuItem { text: "Сохранить как"; onTriggered: { if(projectController && projectController.inEditMode) mainWindow.saveAsDialog.open() } }
                MenuSeparator {}
                MenuItem { text: "Закрыть"; onTriggered: Qt.quit() }
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

        Button
        {
            text: "Добавить список"
            Layout.preferredWidth: 145
            font.pixelSize: 12
            onClicked: mainWindow.listDialog.open()
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

        ComboBox
        {
            id: viewModeCombo
            visible: !appToolBar.isLocalMode
            Layout.preferredWidth: 200
            font.pixelSize: 12
            model: ["Целевой", "Прогнозный", "Комбинированный"]
            currentIndex: projectController ? projectController.settingsManager.viewMode : 0
            onActivated:
            {
                if (projectController)
                    projectController.settingsManager.setViewMode(currentIndex)
            }
        }

        Button
        {
            text: "Прогресс"
            visible: !appToolBar.isLocalMode
            checked: mainWindow.gridArea ? mainWindow.gridArea.showProgress : true
            checkable: true
            Layout.preferredWidth: 95
            onCheckedChanged: { if(mainWindow && mainWindow.gridArea) mainWindow.gridArea.showProgress = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Зависимости"
            checked: mainWindow.gridArea ? mainWindow.gridArea.showDependencies : true
            checkable: true
            Layout.preferredWidth: 110
            onCheckedChanged: { if(mainWindow && mainWindow.gridArea) mainWindow.gridArea.showDependencies = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Переносы"
            checked: mainWindow.gridArea ? mainWindow.gridArea.showTaskHistory : true
            checkable: true
            Layout.preferredWidth: 95
            onCheckedChanged:
            {
                if (mainWindow && mainWindow.gridArea)
                    mainWindow.gridArea.showTaskHistory = checked
            }
            font.pixelSize: 12
        }

        Button
        {
            text: "Комментарии"
            checked: mainWindow.gridArea ? mainWindow.gridArea.showComments : true
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
            }
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 5 }

        Button
        {
            text: "Помощь"
            Layout.preferredWidth: 80
            onClicked: mainWindow.helpDialog.show()
        }

        Button
        {
            text: "О программе"
            Layout.preferredWidth: 115
            onClicked: mainWindow.aboutDialog.open()
        }
    }
}
