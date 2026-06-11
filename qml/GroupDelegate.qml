import QtQuick 6.0
import QtQuick.Controls 6.0

Item {
    id: root
    height: groupHeader.height + (expanded ? tasksHeight : 0)
    property string groupId: model.groupId
    property string groupName: model.groupName
    property bool expanded: model.expanded
    property var taskIds: model.taskIds
    property real tasksHeight: tasksRepeater.count * 40
    
    function refreshTasks() {
        if (projectController && projectController.projectData && groupId) {
            tasksRepeater.model = projectController.projectData.taskModel.getTasksForGroup(groupId)
        }
    }
    
    Component.onCompleted: refreshTasks()
    
    Connections {
        target: (projectController && projectController.projectData) ? projectController.projectData.taskModel : null
        function onCountChanged() { refreshTasks() }
        function onRowsInserted() { refreshTasks() }
    }
    
    Rectangle {
        id: groupHeader
        width: parent.width
        height: 40
        color: "#e0e0e0"
        border.color: "#cccccc"
        
        Row {
            anchors.fill: parent
            anchors.leftMargin: 5
            spacing: 5
            
            Rectangle {
                width: 24; height: 24; color: "transparent"; anchors.verticalCenter: parent.verticalCenter
                Text { text: expanded ? "▼" : "▶"; anchors.centerIn: parent; font.pixelSize: 12 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (projectController && projectController.projectData) {
                            projectController.projectData.groupModel.setGroupExpanded(groupId, !expanded)
                        }
                    }
                }
            }
            
            Text { text: groupName; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
        
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.RightButton
            onClicked: (mouse) => { if (mouse.button === Qt.RightButton) groupContextMenu.popup() }
        }
        
        Menu {
            id: groupContextMenu
            MenuItem { 
                text: "Добавить задачу"
                onTriggered: {
                    if (projectController && projectController.projectData) {
                        // Используем сегодняшнюю дату как дату начала
                        var startDate = new Date()
                        var endDate = new Date()
                        endDate.setDate(endDate.getDate() + 7)
                        projectController.addTask(groupId, "Новая задача", "", startDate, endDate)
                        refreshTasks()
                        if (mainWindow && mainWindow.gridArea) {
                            mainWindow.gridArea.updateData()
                        }
                    }
                }
            }
            MenuItem { text: "Переименовать" }
            MenuItem { text: "Назначить ответственного" }
            MenuSeparator {}
            MenuItem { text: "Добавить группу сверху"; onTriggered: addGroupAbove() }
            MenuItem { text: "Добавить группу снизу"; onTriggered: addGroupBelow() }
            MenuSeparator {}
            MenuItem { text: "Удалить"; onTriggered: deleteGroup() }
        }
    }
    
    Column {
        id: tasksColumn
        y: groupHeader.height
        width: parent.width
        visible: expanded
        height: tasksHeight
        
        Repeater {
            id: tasksRepeater
            model: []
            delegate: TaskDelegate {
                width: root.width
                taskId: modelData
            }
        }
    }
    
    function addGroupAbove() {
        if (projectController && projectController.projectData) {
            var index = projectController.projectData.groupModel.getGroupIds().indexOf(groupId)
            projectController.projectData.groupModel.addGroupAt(index, "Новая группа")
        }
    }
    
    function addGroupBelow() {
        if (projectController && projectController.projectData) {
            var index = projectController.projectData.groupModel.getGroupIds().indexOf(groupId)
            projectController.projectData.groupModel.addGroupAt(index + 1, "Новая группа")
        }
    }
    
    function deleteGroup() {
        if (projectController && projectController.projectData) {
            for (var i = 0; i < tasksRepeater.model.length; i++) {
                projectController.projectData.taskModel.removeTask(tasksRepeater.model[i])
            }
            projectController.projectData.groupModel.removeGroup(groupId)
        }
    }
}
