import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Rectangle {
    id: root
    property string taskId: ""
    property string taskTitle: ""
    property string taskResponsible: ""
    property date taskStart: new Date()
    property date taskEnd: new Date()
    property int taskStatus: 0
    property date displayStart: new Date()
    property int dayWidth: 30
    property int zoomLevel: 0
    
    property bool hasValidDates: taskId !== "" && taskStart.toString() !== "Invalid Date" && taskEnd.toString() !== "Invalid Date"
    
    Component.onCompleted: {
        console.log("GanttBar created: taskId=" + taskId + 
                    " title=" + taskTitle +
                    " start=" + (taskStart ? taskStart.toLocaleDateString() : "null") + 
                    " end=" + (taskEnd ? taskEnd.toLocaleDateString() : "null") +
                    " displayStart=" + (displayStart ? displayStart.toLocaleDateString() : "null") +
                    " x=" + x + " width=" + width + " visible=" + visible)
    }
    
    function getColor() {
        switch(taskStatus) {
            case 0: return "#FFD700"  // Запланировано - жёлтый
            case 1: return "#32CD32"  // Выполнено - зелёный
            case 2: return "#FF8C00"  // Имеются риски - оранжевый
            case 3: return "#FF4444"  // Блокировано - красный
            default: return "#FFD700"
        }
    }
    
    function calculateX() {
        if (!hasValidDates) return 0
        var daysDiff = Math.floor((taskStart - displayStart) / (1000 * 60 * 60 * 24))
        var result = daysDiff * dayWidth
        console.log("calculateX: taskId=" + taskId + " daysDiff=" + daysDiff + " result=" + result)
        return Math.max(0, result)
    }
    
    function calculateWidth() {
        if (!hasValidDates) return 10
        var daysDiff = Math.floor((taskEnd - taskStart) / (1000 * 60 * 60 * 24)) + 1
        var result = Math.max(10, daysDiff * dayWidth)
        console.log("calculateWidth: taskId=" + taskId + " daysDiff=" + daysDiff + " result=" + result)
        return result
    }
    
    x: calculateX()
    width: calculateWidth()
    color: getColor()
    radius: 6
    border.color: Qt.darker(getColor(), 1.2)
    border.width: 1
    z: 2
    visible: hasValidDates
    
    function calculateDateFromX(xPos) {
        var daysOffset = Math.round(xPos / dayWidth)
        var newDate = new Date(displayStart)
        newDate.setDate(newDate.getDate() + daysOffset)
        return newDate
    }
    
    ToolTip {
        visible: mouseArea.containsMouse && hasValidDates
        text: taskTitle + "\nДлительность: " + 
              (Math.floor((taskEnd - taskStart) / (24 * 60 * 60 * 1000)) + 1) + 
              " дней\nОтветственный: " + taskResponsible
        delay: 500
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: hasValidDates
        drag.target: root
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: root.parent.width - width
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                taskContextMenu.popup()
            }
        }
        
        onPositionChanged: {
            if (drag.active && hasValidDates) {
                var newStart = calculateDateFromX(x)
                var duration = Math.floor((taskEnd - taskStart) / (24 * 60 * 60 * 1000)) + 1
                var newEnd = new Date(newStart)
                newEnd.setDate(newEnd.getDate() + duration - 1)
                if (projectController) projectController.updateTaskDates(taskId, newStart, newEnd)
            }
        }
        
        Rectangle {
            width: 10
            height: parent.height
            anchors.right: parent.right
            color: Qt.darker(root.color, 1.5)
            radius: 2
            visible: mouseArea.containsMouse
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: parent.parent
                drag.axis: Drag.XAxis
                drag.minimumX: root.x + 10
                
                onPositionChanged: {
                    if (drag.active && hasValidDates) {
                        var newEnd = calculateDateFromX(root.x + root.width)
                        if (newEnd > taskStart && projectController) {
                            projectController.updateTaskDates(taskId, taskStart, newEnd)
                        }
                    }
                }
            }
        }
    }
    
    Menu {
        id: taskContextMenu
        MenuItem { text: "Переименовать"; onTriggered: renameDialog.open() }
        MenuItem { text: "Назначить ответственного"; onTriggered: responsibleDialog.open() }
        Menu {
            title: "Изменить статус"
            MenuItem { text: "Запланировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 0) }
            MenuItem { text: "Выполнено"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 1) }
            MenuItem { text: "Имеются риски"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 2) }
            MenuItem { text: "Блокировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 3) }
        }
        MenuItem { text: "Изменить сроки"; onTriggered: if(editTaskDialog) editTaskDialog.open(taskId) }
        MenuSeparator {}
        MenuItem { text: "Добавить задачу сверху" }
        MenuItem { text: "Добавить задачу снизу" }
        MenuItem { text: "Удалить"; onTriggered: if(projectController) projectController.removeTask(taskId) }
    }
    
    Dialog {
        id: renameDialog
        title: "Переименовать"
        width: 350
        height: 130
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            Label { text: "Новое название:" }
            TextField { id: newNameField; placeholderText: "Введите название" }
        }
        onAccepted: {
            if (taskId !== "" && newNameField.text !== "") {
                projectController.projectData.taskModel.updateTask(taskId, newNameField.text, taskResponsible, taskStart, taskEnd, taskStatus)
                taskTitle = newNameField.text
            }
        }
    }
    
    Dialog {
        id: responsibleDialog
        title: "Ответственный"
        width: 350
        height: 130
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            Label { text: "ФИО ответственного:" }
            TextField { id: responsibleField; placeholderText: "Введите ФИО" }
        }
        onAccepted: {
            if (taskId !== "" && responsibleField.text !== "") {
                projectController.projectData.taskModel.updateTask(taskId, taskTitle, responsibleField.text, taskStart, taskEnd, taskStatus)
                taskResponsible = responsibleField.text
            }
        }
    }
}
