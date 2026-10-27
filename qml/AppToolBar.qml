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

    function collapseAll()
    {
        if (!projectController || !projectController.projectData) return
        var gm = projectController.projectData.groupModel
        var ids = gm.getGroupIds()
        for (var i = 0; i < ids.length; i++)
            gm.setGroupExpanded(ids[i], false)
    }

    function expandAll()
    {
        if (!projectController || !projectController.projectData) return
        var gm = projectController.projectData.groupModel
        var ids = gm.getGroupIds()
        for (var i = 0; i < ids.length; i++)
            gm.setGroupExpanded(ids[i], true)
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
            text: "Настройки"
            Layout.preferredWidth: 95
            onClicked: mainWindow.settingsDialog.open()
        }

        ToolSeparator {}

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

        ToolSeparator {}

        Button
        {
            text: "Блокировка"
            checked: projectController ? projectController.settingsManager.editingLocked : false
            onCheckedChanged: { if (projectController) projectController.settingsManager.editingLocked = checked }
            checkable: true
            Layout.preferredWidth: 105
            font.pixelSize: 12
        }

        ToolSeparator {}

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

            Connections
            {
                target: projectController ? projectController.settingsManager : null
                function onViewModeChanged()
                {
                    if (projectController)
                        viewModeCombo.currentIndex = projectController.settingsManager.viewMode
                }
            }
        }

        ComboBox
        {
            id: zoomCombo
            Layout.preferredWidth: 110
            font.pixelSize: 12
            model: ["День", "Неделя"]
            currentIndex: projectController ? projectController.settingsManager.zoomLevel : 0
            onActivated:
            {
                if (projectController)
                    projectController.settingsManager.setZoomLevel(currentIndex)
            }

            Connections
            {
                target: projectController ? projectController.settingsManager : null
                function onZoomLevelChanged()
                {
                    if (projectController)
                        zoomCombo.currentIndex = projectController.settingsManager.zoomLevel
                }
            }
        }

        ComboBox
        {
            id: screenCombo
            Layout.preferredWidth: 130
            font.pixelSize: 12
            model: ["В окне", "Весь экран"]
            currentIndex: mainWindow.visibility === Window.FullScreen ? 1 : 0
            onActivated:
            {
                if (currentIndex === 1)
                    mainWindow.showFullScreen()
                else
                    mainWindow.showNormal()
            }

            Connections
            {
                target: mainWindow
                function onVisibilityChanged()
                {
                    screenCombo.currentIndex = (mainWindow.visibility === Window.FullScreen) ? 1 : 0
                }
            }
        }

        ToolSeparator {}

        Button
        {
            text: "Прогресс"
            visible: !appToolBar.isLocalMode
            checked: mainWindow.hasGridArea() ? mainWindow.gridArea.showProgress : true
            checkable: true
            Layout.preferredWidth: 95
            onCheckedChanged: { if(mainWindow.hasGridArea()) mainWindow.gridArea.showProgress = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Зависимости"
            checked: mainWindow.hasGridArea() ? mainWindow.gridArea.showDependencies : true
            checkable: true
            Layout.preferredWidth: 110
            onCheckedChanged: { if(mainWindow.hasGridArea()) mainWindow.gridArea.showDependencies = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Переносы"
            checked: mainWindow.hasGridArea() ? mainWindow.gridArea.showTaskHistory : true
            checkable: true
            Layout.preferredWidth: 95
            onCheckedChanged:
            {
                if (mainWindow.hasGridArea())
                    mainWindow.gridArea.showTaskHistory = checked
            }
            font.pixelSize: 12
        }

        Button
        {
            text: "Комментарии"
            checked: mainWindow.hasGridArea() ? mainWindow.gridArea.showComments : true
            checkable: true
            Layout.preferredWidth: 115
            onCheckedChanged: { if(mainWindow.hasGridArea()) mainWindow.gridArea.showComments = checked }
            font.pixelSize: 12
        }

        Button
        {
            text: "Праздники"
            checked: projectController ? projectController.settingsManager.showHolidays : false
            checkable: true
            Layout.preferredWidth: 100
            font.pixelSize: 12
            onCheckedChanged:
            {
                if (projectController)
                    projectController.settingsManager.showHolidays = checked
                if (mainWindow.hasGridArea())
                    mainWindow.gridArea.updateData()
                if (mainWindow.calendarHeader)
                    mainWindow.calendarHeader.refresh()
            }
        }

        ToolButton
        {
            text: "⊟"
            font.pixelSize: 16
            Layout.preferredWidth: 30
            ToolTip.visible: hovered
            ToolTip.delay: 400
            ToolTip.text: "Свернуть все группы"
            onClicked: appToolBar.collapseAll()
        }

        ToolButton
        {
            text: "⊞"
            font.pixelSize: 16
            Layout.preferredWidth: 30
            ToolTip.visible: hovered
            ToolTip.delay: 400
            ToolTip.text: "Развернуть все группы"
            onClicked: appToolBar.expandAll()
        }

        Button
        {
            text: "🔄"
            Layout.preferredWidth: 50
            font.pixelSize: 18
            onClicked:
            {
                if (mainWindow.hasGridArea())
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
