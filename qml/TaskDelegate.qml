import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Rectangle {
    id: root
    height: 40
    color: "white"
    border.color: "#dddddd"
    
    property string taskId
    property var taskData: (projectController && projectController.projectData) 
                           ? projectController.projectData.taskModel.getTask(taskId) : null
    property string title: taskData?.title || ""
    property string responsible: taskData?.responsible || ""
    property string startDate: taskData?.startDate ? Qt.formatDateTime(taskData.startDate, "dd.MM.yyyy") : ""
    property string endDate: taskData?.endDate ? Qt.formatDateTime(taskData.endDate, "dd.MM.yyyy") : ""
    
    // Диалог переименования
    Dialog {
        id: renameDialog
        title: "Переименовать задачу"
        width: 400
        height: 230
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: Overlay.overlay
        
        property string taskId: ""
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Label { 
                text: "Новое название задачи:" 
                Layout.fillWidth: true
                font.pixelSize: 13
            }
            
            TextField { 
                id: newTitleField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                text: root.title
                placeholderText: "Введите название задачи"
                font.pixelSize: 13
                focus: true
                onAccepted: {
                    if (newTitleField.text !== "") {
                        renameDialog.accept()
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    onClicked: renameDialog.close()
                }
                
                Button {
                    text: "ОК"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    enabled: newTitleField.text !== ""
                    onClicked: renameDialog.accept()
                }
            }
        }
        
        onAccepted: {
            if (newTitleField.text !== "" && projectController && projectController.projectData) {
                var task = projectController.projectData.taskModel.getTask(renameDialog.taskId)
                if (task) {
                    projectController.projectData.taskModel.updateTask(
                        renameDialog.taskId, newTitleField.text, task.responsible,
                        task.startDate, task.endDate, task.status
                    )
                    root.title = newTitleField.text
                }
            }
        }
    }
    
    // Диалог назначения ответственного
    Dialog {
        id: responsibleDialog
        title: "Назначить ответственного"
        width: 400
        height: 230
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: Overlay.overlay
        
        property string taskId: ""
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Label { 
                text: "ФИО ответственного:" 
                Layout.fillWidth: true
                font.pixelSize: 13
            }
            
            TextField { 
                id: responsibleField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                text: root.responsible
                placeholderText: "Введите ФИО ответственного"
                font.pixelSize: 13
                focus: true
                onAccepted: {
                    if (responsibleField.text !== "") {
                        responsibleDialog.accept()
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    onClicked: responsibleDialog.close()
                }
                
                Button {
                    text: "ОК"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    enabled: responsibleField.text !== ""
                    onClicked: responsibleDialog.accept()
                }
            }
        }
        
        onAccepted: {
            if (responsibleField.text !== "" && projectController && projectController.projectData) {
                var task = projectController.projectData.taskModel.getTask(responsibleDialog.taskId)
                if (task) {
                    projectController.projectData.taskModel.updateTask(
                        responsibleDialog.taskId, task.title, responsibleField.text,
                        task.startDate, task.endDate, task.status
                    )
                    root.responsible = responsibleField.text
                }
            }
        }
    }
    
    Row {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 0
        
        Rectangle {
            width: parent.width * 0.35
            height: parent.height
            Text { 
                id: titleText
                text: root.title
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: parent.width - 10
                font.pixelSize: 12
            }
        }
        Rectangle {
            width: parent.width * 0.20
            height: parent.height
            Text { 
                id: responsibleText
                text: root.responsible
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: parent.width - 10
                font.pixelSize: 12
            }
        }
        Rectangle {
            width: parent.width * 0.22
            height: parent.height
            Text { 
                text: startDate
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }
        }
        Rectangle {
            width: parent.width * 0.23
            height: parent.height
            Text { 
                text: endDate
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.ArrowCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                taskContextMenu.popup()
            }
        }
    }
    
    Menu {
        id: taskContextMenu
        MenuItem { text: "Переименовать"; onTriggered: { renameDialog.taskId = taskId; renameDialog.open() } }
        MenuItem { text: "Назначить ответственного"; onTriggered: { responsibleDialog.taskId = taskId; responsibleDialog.open() } }
        Menu {
            title: "Изменить статус"
            MenuItem { text: "🟡 Запланировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 0) }
            MenuItem { text: "🟢 Выполнено"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 1) }
            MenuItem { text: "🟠 Имеются риски"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 2) }
            MenuItem { text: "🔴 Блокировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(taskId, 3) }
        }
        MenuItem { text: "Изменить сроки"; onTriggered: { editTaskDialog.open(taskId) } }
        MenuSeparator {}
        MenuItem { text: "Добавить задачу сверху" }
        MenuItem { text: "Добавить задачу снизу" }
        MenuItem { text: "Удалить"; onTriggered: if(projectController) projectController.removeTask(taskId) }
    }
    
    Connections {
        target: projectController?.projectData?.taskModel
        function onDataChanged() {
            var updatedTask = projectController.projectData.taskModel.getTask(taskId)
            if (updatedTask) {
                root.title = updatedTask.title
                root.responsible = updatedTask.responsible
                root.startDate = Qt.formatDateTime(updatedTask.startDate, "dd.MM.yyyy")
                root.endDate = Qt.formatDateTime(updatedTask.endDate, "dd.MM.yyyy")
            }
        }
    }
}
