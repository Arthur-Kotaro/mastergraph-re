import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog {
    id: root
    title: "Редактирование сроков задачи"
    width: 480
    height: 260
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    
    property string taskId: ""
    property date startDate: new Date()
    property date endDate: new Date()
    
    function loadTaskData() {
        if (!taskId || taskId === "") {
            console.error("EditTaskDialog: taskId is empty")
            return false
        }
        var task = projectController?.projectData?.taskModel?.getTask(taskId)
        if (task) {
            startDate = task.startDate
            endDate = task.endDate
            errorLabel.visible = false
            if (startPicker) startPicker.selectedDate = startDate
            if (endPicker) endPicker.selectedDate = endDate
            console.log("Task loaded:", taskId, startDate, endDate)
            return true
        } else {
            console.error("Task not found:", taskId)
            return false
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        
        Label {
            text: "Измените даты задачи:"
            font.bold: true
            Layout.fillWidth: true
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            
            DatePicker {
                id: startPicker
                title: "Дата начала"
                Layout.fillWidth: true
                selectedDate: root.startDate
                onDateSelected: root.startDate = selectedDate
            }
            
            DatePicker {
                id: endPicker
                title: "Дата завершения"
                Layout.fillWidth: true
                selectedDate: root.endDate
                onDateSelected: root.endDate = selectedDate
            }
        }
        
        Label {
            id: errorLabel
            color: "red"
            visible: false
            text: "Дата завершения не может быть раньше даты начала"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
    
    onOpened: {
        console.log("EditTaskDialog opened, taskId:", taskId)
        loadTaskData()
    }
    
    onAccepted: {
        if (startDate <= endDate) {
            console.log("Updating task dates:", taskId, startDate, endDate)
            projectController.updateTaskDates(taskId, startDate, endDate)
        } else {
            errorLabel.visible = true
        }
    }
    
    function open(taskId) {
        console.log("EditTaskDialog.open called with taskId:", taskId)
        if (!taskId || taskId === "") {
            console.error("EditTaskDialog.open: invalid taskId")
            return
        }
        root.taskId = taskId
        root.open()
    }
}
