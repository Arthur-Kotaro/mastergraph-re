import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Window 6.0
import Qt.labs.platform 1.1 as Labs
import GanttProject 1.0

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 800
    visible: true
    title: {
        if (projectController && projectController.projectData && projectController.projectData.projectName) {
            return "Мастерграфик: re. Проект: " + projectController.projectData.projectName
        } else {
            return "Мастерграфик: re"
        }
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
    
    Shortcut { sequence: "Ctrl+N"; onActivated: if (projectController) newProjectDialog.open() }
    Shortcut { sequence: "Ctrl+O"; onActivated: if (projectController) openFileDialog.open() }
    Shortcut { sequence: "Ctrl+S"; onActivated: if (projectController && inEditMode) projectController.saveProject() }
    Shortcut { sequence: "Ctrl+Shift+S"; onActivated: if (projectController && inEditMode) saveAsDialog.open() }
    Shortcut { sequence: "F1"; onActivated: {
        if (mainWindow.visibility === Window.FullScreen) mainWindow.showNormal()
        else mainWindow.showFullScreen()
    } }
    
    AppToolBar { id: appToolBar; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right }
    
    Item {
        id: contentArea
        anchors.top: appToolBar.bottom
        anchors.bottom: infoPanel.top
        anchors.left: parent.left
        anchors.right: parent.right
        
        WelcomeScreen {
            visible: !inEditMode
            anchors.fill: parent
            onNewProjectRequested: { newProjectDialog.refreshData(); newProjectDialog.open() }
            onOpenProjectRequested: openFileDialog.open()
        }
        
        // Режим редактирования
        Row {
            visible: inEditMode
            anchors.fill: parent
            spacing: 0
            
            LeftPanel {
                id: leftPanel
                width: 460
                height: parent.height
            }
            
            // Правая область с календарём и сеткой
            Rectangle {
                width: parent.width - 460
                height: parent.height
                color: "white"
                clip: true
                
                // Календарь фиксирован
                CalendarHeader {
                    x: -flickableRight.contentX
                    id: calendarHeader
                    width: parent.width
                    height: 240
                }
                
                // Сетка с прокруткой
                Flickable {
                    id: flickableRight
                    contentY: -4
                    anchors.top: calendarHeader.bottom
                    anchors.bottom: parent.bottom
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOn }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
                    contentHeight: gridArea.height
                    contentWidth: gridArea.width
                    boundsBehavior: Flickable.StopAtBounds
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    
                    GridArea {
                        id: gridArea
                        externalFlickable: flickableRight
                        width: calendarHeader.contentWidth
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
    
    Labs.FileDialog {
        id: openFileDialog
        title: "Открыть график"
        nameFilters: ["Файлы графиков (*.gantt)", "Все файлы (*)"]
        onAccepted: if (projectController) projectController.openProject(file)
    }
}
