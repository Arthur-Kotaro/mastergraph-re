import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Window 6.0
import Qt.labs.platform 1.1 as Labs
import GanttProject 1.0

ApplicationWindow
{
    id: mainWindow
    width: 1280
    height: 800
    minimumWidth: 1000
    minimumHeight: 700
    visible: true
    title:
    {
        if (projectController && projectController.projectData && projectController.projectData.projectName)
            return "Мастерграфик: re. Проект: " + projectController.projectData.projectName
        else
            return "Мастерграфик: re"
    }

    property bool inEditMode: (projectController && projectController.inEditMode) || false
    property alias gridArea: gridArea
    property alias editTaskDialog: editTaskDialog
    property alias newProjectDialog: newProjectDialog
    property alias openFileDialog: openFileDialog
    property alias saveAsDialog: saveAsDialog
    property alias settingsDialog: settingsDialog
    property alias aboutDialog: aboutDialog
    property alias helpDialog: helpDialog
    property alias dependencyDialog: dependencyDialog
    property alias cascadeDialog: cascadeDialog
    property alias completeTaskDialog: completeTaskDialog
    property alias newTaskDialog: newTaskDialog
    property alias commentDialog: commentDialog
    property alias leftPanel: leftPanel
    property alias calendarHeader: calendarHeader

    Shortcut { sequence: "Ctrl+N"; onActivated: if (projectController) { newProjectDialog.refreshData(); newProjectDialog.open() } }
    Shortcut { sequence: "Ctrl+O"; onActivated: if (projectController) openFileDialog.open() }
    Shortcut { sequence: "Ctrl+S"; onActivated: if (projectController && inEditMode) projectController.saveProject() }
    Shortcut { sequence: "Ctrl+Shift+S"; onActivated: if (projectController && inEditMode) saveAsDialog.open() }
    Shortcut { sequence: "F1"; onActivated:
    {
        if (mainWindow.visibility === Window.FullScreen) mainWindow.showNormal()
        else mainWindow.showFullScreen()
    } }

    Connections
    {
        target: projectController
        function onProjectLoaded()
        {
            if (gridArea) gridArea.updateData()
        }
    }
    AppToolBar { id: appToolBar; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right }

    Item
    {
        id: contentArea
        anchors.top: appToolBar.bottom
        anchors.bottom: infoPanel.top
        anchors.left: parent.left
        anchors.right: parent.right

        WelcomeScreen
        {
            visible: !inEditMode
            anchors.fill: parent
            onNewProjectRequested: { newProjectDialog.refreshData(); newProjectDialog.open() }
            onOpenProjectRequested: openFileDialog.open()
        }

        Row
        {
            visible: inEditMode
            anchors.fill: parent
            spacing: 0

            LeftPanel
            {
                flickableRight: flickableRight
                id: leftPanel
                width: 460
                height: parent.height
            }

            Rectangle
            {
                width: 2
                height: parent.height
                color: "#888888"
            }

            Rectangle
            {
                width: parent.width - 462
                height: parent.height
                color: "white"
                clip: true

                CalendarHeader
                {
                    id: calendarHeader
                    x: -flickableRight.contentX
                    width: parent.width
                    height: 240
                }

                Flickable
                {
                    id: flickableRight
                    anchors.top: calendarHeader.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    contentWidth: gridArea.width
                    contentHeight: gridArea.height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOn }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

                    GridArea
                    {
                        id: gridArea
                        externalFlickable: flickableRight
                        width: calendarHeader.contentWidth
                    }
                }

                MouseArea
                {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(wheel)
                    {
                        if (wheel.modifiers & Qt.ControlModifier)
                        {
                            if (wheel.angleDelta.y > 0)
                                projectController.settingsManager.setZoomLevel(0)
                            else
                                projectController.settingsManager.setZoomLevel(1)
                            wheel.accepted = true
                        }
                    }
                }
            }
        }
    }

    InfoPanel { id: infoPanel; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right }

    NewProjectDialog { id: newProjectDialog }
    SaveAsDialog { id: saveAsDialog }
    SettingsDialog { id: settingsDialog }
    EditTaskDialog { id: editTaskDialog }
    ChangeMilestoneDateDialog { id: changeMilestoneDateDialog }
    AboutDialog { id: aboutDialog }
    HelpDialog { id: helpDialog }
    DependencyDialog { id: dependencyDialog }
    CascadeDialog { id: cascadeDialog }
    CompleteTaskDialog { id: completeTaskDialog }
    NewTaskDialog { id: newTaskDialog }
    CommentDialog { id: commentDialog }

    Labs.FileDialog
    {
        id: openFileDialog
        title: "Открыть график"
        nameFilters: ["Файлы графиков (*.gantt)", "Все файлы (*)"]
        onAccepted:
        {
            var path = file.toString()
            if (path.startsWith("file://")) path = path.substring(7)
            if (projectController) projectController.openProject(path)
        }
    }
}