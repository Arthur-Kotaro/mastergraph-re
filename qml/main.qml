import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Window 6.0
import Qt.labs.platform 1.1 as Labs
import GanttProject 1.0

ApplicationWindow
{
    id: mainWindow
    width: 1400
    height: 750
    minimumWidth: 1400
    minimumHeight: 750
    visible: true
    title:
    {
        if (projectController && projectController.projectData && projectController.projectData.projectName)
            return "Мастерграфик: re. Проект: " + projectController.projectData.projectName
        else
            return "Мастерграфик: re"
    }

    property bool inEditMode: (projectController && projectController.inEditMode) || false
    property int leftPanelWidth: 525

    readonly property bool editingText: {
        var item = activeFocusItem
        if (!item) return false
        return (item instanceof TextInput
                || item instanceof TextField
                || item instanceof TextArea
                || item instanceof TextEdit)
    }

    property alias gridArea: gridArea
    property alias editTaskDialog: editTaskDialog
    property alias editForecastDatesDialog: editForecastDatesDialog
    property alias newProjectDialog: newProjectDialog
    property alias openFileDialog: openFileDialog
    property alias saveAsDialog: saveAsDialog
    property alias settingsDialog: settingsDialog
    property alias aboutDialog: aboutDialog
    property alias helpDialog: helpDialog
    property alias dependencyDialog: dependencyDialog
    property alias cascadeDialog: cascadeDialog
    property alias listDialog: listDialog
    property alias completeTaskDialog: completeTaskDialog
    property alias newTaskDialog: newTaskDialog
    property alias commentDialog: commentDialog
    property alias responsibleDialog: responsibleDialog
    property alias renameTaskDialog: renameTaskDialog
    property alias leftPanel: leftPanel
    property alias calendarHeader: calendarHeader

    // --- Файл ---
    Shortcut { sequence: "Ctrl+N"; onActivated: if (projectController) { newProjectDialog.refreshData(); newProjectDialog.open() } }
    Shortcut { sequence: "Ctrl+O"; onActivated: if (projectController) openFileDialog.open() }
    Shortcut { sequence: "Ctrl+S"; enabled: inEditMode && !editingText; onActivated: if (projectController && inEditMode) projectController.saveProject() }
    Shortcut { sequence: "Ctrl+Shift+S"; enabled: inEditMode && !editingText; onActivated: if (projectController && inEditMode) saveAsDialog.open() }

    // --- Режимы отображения ---
    Shortcut {
        sequence: "Ctrl+1"
        enabled: inEditMode
        onActivated: if (projectController) projectController.settingsManager.setViewMode(0)
    }
    Shortcut {
        sequence: "Ctrl+2"
        enabled: inEditMode
        onActivated: if (projectController) projectController.settingsManager.setViewMode(1)
    }
    Shortcut {
        sequence: "Ctrl+3"
        enabled: inEditMode
        onActivated: if (projectController) projectController.settingsManager.setViewMode(2)
    }

    // --- Переключатели ---
    Shortcut {
        sequence: "Ctrl+L"
        enabled: inEditMode && !editingText
        onActivated: if (projectController) projectController.settingsManager.editingLocked = !projectController.settingsManager.editingLocked
    }
    Shortcut {
        sequence: "Ctrl+D"
        enabled: inEditMode && !editingText
        onActivated: if (mainWindow.gridArea) mainWindow.gridArea.showDependencies = !mainWindow.gridArea.showDependencies
    }
    Shortcut {
        sequence: "Ctrl+H"
        enabled: inEditMode && !editingText
        onActivated: {
            if (mainWindow.gridArea)
                mainWindow.gridArea.showTaskHistory = !mainWindow.gridArea.showTaskHistory
            if (mainWindow.calendarHeader && mainWindow.calendarHeader.milestoneBar)
                mainWindow.calendarHeader.milestoneBar.showRescheduled = mainWindow.gridArea.showTaskHistory
        }
    }
    Shortcut {
        sequence: "Ctrl+/"
        enabled: inEditMode && !editingText
        onActivated: if (mainWindow.gridArea) mainWindow.gridArea.showComments = !mainWindow.gridArea.showComments
    }

    // --- Навигация ---
    Shortcut {
        sequence: "Home"
        enabled: inEditMode && !editingText
        onActivated: {
            if (!flickableRight) return
            flickableRight.contentX = 0
            flickableRight.contentY = 0
        }
    }
    Shortcut {
        sequence: "End"
        enabled: inEditMode && !editingText
        onActivated: {
            if (!flickableRight) return
            flickableRight.contentX = Math.max(0, flickableRight.contentWidth - flickableRight.width)
            flickableRight.contentY = Math.max(0, flickableRight.contentHeight - flickableRight.height)
        }
    }
    Shortcut {
        sequence: "PageDown"
        enabled: inEditMode && !editingText
        onActivated: scrollPageDown()
    }
    Shortcut {
        sequence: "PageUp"
        enabled: inEditMode && !editingText
        onActivated: scrollPageUp()
    }
    Shortcut {
        sequence: "Alt+Down"
        enabled: inEditMode && !editingText
        onActivated: scrollPageDown()
    }
    Shortcut {
        sequence: "Alt+Up"
        enabled: inEditMode && !editingText
        onActivated: scrollPageUp()
    }

    function scrollPageDown()
    {
        if (!flickableRight) return
        var step = Math.max(40, flickableRight.height - 40)
        flickableRight.contentY = Math.min(
            flickableRight.contentY + step,
            Math.max(0, flickableRight.contentHeight - flickableRight.height))
    }

    function scrollPageUp()
    {
        if (!flickableRight) return
        var step = Math.max(40, flickableRight.height - 40)
        flickableRight.contentY = Math.max(0, flickableRight.contentY - step)
    }

    // --- Прочее ---
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
                width: leftPanelWidth
                height: parent.height
            }

            Rectangle
            {
                id: splitter
                width: 6
                height: parent.height
                color: "#888888"

                MouseArea
                {
                    anchors.fill: parent
                    anchors.leftMargin: -4
                    anchors.rightMargin: -4
                    cursorShape: Qt.SizeHorCursor
                    drag.target: splitter
                    drag.axis: Drag.XAxis
                    drag.minimumX: 525
                    drag.maximumX: 800

                    onPositionChanged:
                    {
                        if (drag.active)
                        {
                            leftPanelWidth = splitter.x
                        }
                    }
                }
            }

            Rectangle
            {
                width: parent.width - leftPanelWidth - 6
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
            }
        }
    }

    InfoPanel { id: infoPanel; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right }

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        z: 100
        onWheel: function(wheel)
        {
            var flick = flickableRight
            if (!flick) return

            if (wheel.modifiers & Qt.ControlModifier)
            {
                if (wheel.angleDelta.y > 0) projectController.settingsManager.setZoomLevel(0)
                else projectController.settingsManager.setZoomLevel(1)
                wheel.accepted = true
                return
            }

            if (wheel.modifiers & Qt.ShiftModifier)
            {
                flick.contentX = Math.max(0,
                    Math.min(flick.contentX - wheel.angleDelta.y,
                             flick.contentWidth - flick.width))
            }
            else
            {
                flick.contentY = Math.max(0,
                    Math.min(flick.contentY - wheel.angleDelta.y,
                             flick.contentHeight - flick.height))
            }
            wheel.accepted = true
        }
    }

    NewProjectDialog { id: newProjectDialog }
    SaveAsDialog { id: saveAsDialog }
    SettingsDialog { id: settingsDialog }
    EditTaskDialog { id: editTaskDialog }
    EditForecastDatesDialog { id: editForecastDatesDialog }
    ChangeMilestoneDateDialog { id: changeMilestoneDateDialog }
    AboutDialog { id: aboutDialog }
    HelpDialog { id: helpDialog }
    DependencyDialog { id: dependencyDialog }
    CascadeDialog { id: cascadeDialog }
    ListDialog { id: listDialog }
    CompleteTaskDialog { id: completeTaskDialog }
    NewTaskDialog { id: newTaskDialog }
    CommentDialog { id: commentDialog }
    ResponsibleDialog { id: responsibleDialog }
    RenameTaskDialog { id: renameTaskDialog }

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
