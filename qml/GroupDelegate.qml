import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Item
{
    id: root
    height: groupHeader.height + (expanded ? tasksColumn.height : 0)
    property string groupId: model.groupId
    property string groupName: model.groupName
    property bool expanded: model.expanded
    property var taskIds: model.taskIds

    property var tasksList: []

    function refreshTasks()
    {
        if (projectController && projectController.projectData && groupId)
        //console.log("refreshTasks called, groupId:", groupId, "tasks:", tasksList.length)
        {
            tasksRepeater.model = []
            tasksList = projectController.projectData.taskModel.getTasksForGroup(groupId)
            tasksRepeater.model = tasksList
        }
    }

    Component.onCompleted: refreshTasks()

    Connections
    {
        target: projectController.projectData.taskModel
        function onCountChanged() { refreshTasks() }
        function onRowsInserted() { refreshTasks() }
        function onRowsRemoved() { refreshTasks() }
        function onDataChanged() { refreshTasks() }
    }

    Connections
    {
        target: projectController.projectData.groupModel
        function onDataChanged() { refreshTasks() }
        function onGroupExpandedChanged(changedGroupId)
        {
            if (changedGroupId === groupId) refreshTasks()
        }
    }

    Rectangle
    {
        id: groupHeader
        width: parent.width
        height: 40
        color: "#e0e0e0"
        border.color: "#cccccc"
        border.width: 1

        Row
        {
            anchors.fill: parent
            anchors.leftMargin: 5
            spacing: 5

            Rectangle
            {
                width: 24; height: 24; color: "transparent"; anchors.verticalCenter: parent.verticalCenter
                Text { text: expanded ? "▼" : "▶"; anchors.centerIn: parent; font.pixelSize: 12 }
                MouseArea
                {
                    anchors.fill: parent
                    onClicked:
                    {
                        if (projectController && projectController.projectData)
                        {
                            projectController.projectData.groupModel.setGroupExpanded(groupId, !root.expanded)
                        }
                    }
                }
            }

            Text
            {
                text: groupName
                font.pixelSize: 14
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 30
                elide: Text.ElideRight
            }
        }

        MouseArea
        {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: function(mouse)
            {
                if (mouse.button === Qt.RightButton)
                {
                    groupContextMenu.popup()
                }
            }
        }

        Menu
        {
            id: groupContextMenu

            MenuItem
            {
                text: "Добавить задачу"
                onTriggered:
                {
                    if (projectController && projectController.projectData)
                    {
                        var startDate = new Date()
                        var endDate = new Date()
                        endDate.setDate(endDate.getDate() + 7)
                        mainWindow.newTaskDialog.openForGroup(groupId)
                        refreshTasks()
                        if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.gridArea)
                        {
                            mainWindow.gridArea.updateData()
                        }
                    }
                }
            }

            MenuItem
            {
                text: "Переименовать"
                onTriggered:
                {
                    renameGroupDialog.openWithGroup(groupId, groupName)
                }
            }

            MenuSeparator {}

            MenuItem
            {
                text: "Добавить группу сверху"
                onTriggered: addGroupAbove()
            }

            MenuItem
            {
                text: "Добавить группу снизу"
                onTriggered: addGroupBelow()
            }

            MenuSeparator {}

            MenuItem
            {
                text: "Удалить"
                onTriggered: deleteGroup()
            }
        }
    }

    Column
    {
        id: tasksColumn
        y: groupHeader.height
        width: parent.width
        visible: root.expanded
        height: tasksRepeater.count * 40

        Repeater
        {
            id: tasksRepeater
            model: []

            delegate: Rectangle
            {
                width: root.width
                height: 40
                color: "white"
                border.color: "#eeeeee"
                border.width: 1

                property string taskId: modelData
                property var taskData: null

                Component.onCompleted:
                {
                    if (projectController && projectController.projectData && taskId)
                    {
                        taskData = projectController.projectData.taskModel.getTask(taskId)
                    }
                }

                Row
                {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 0

                    Rectangle
                    {
                        width: parent.width * 0.35
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: taskData ? taskData.title : ""
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 20
                            font.pixelSize: 12
                        }
                    }

                    Rectangle
                    {
                        width: parent.width * 0.20
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: taskData ? taskData.responsible : ""
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 10
                            font.pixelSize: 12
                        }
                    }

                    Rectangle
                    {
                        width: parent.width * 0.22
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: taskData && taskData.startDate ? Qt.formatDateTime(taskData.startDate, "dd.MM.yyyy") : ""
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                        }
                    }

                    Rectangle
                    {
                        width: parent.width * 0.23
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: taskData && taskData.endDate ? Qt.formatDateTime(taskData.endDate, "dd.MM.yyyy") : ""
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                        }
                    }
                }

                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    cursorShape: Qt.ArrowCursor
                    onClicked: function(mouse)
                    {
                        if (mouse.button === Qt.RightButton)
                        {
                            taskContextMenu.taskId = taskId
                            taskContextMenu.popup()
                        }
                    }
                }

                TaskContextMenu
                {
                    id: taskContextMenu
                    onAddTaskAboveCallback: function(tId) { addTaskAbove(tId) }
                    onAddTaskBelowCallback: function(tId) { addTaskBelow(tId) }
                    onRenameCallback: function(tId) { renameTaskDialog.openWithTask(tId, projectController.projectData.taskModel.getTask(tId).title) }
                    //onAssignResponsibleCallback: function(tId) { assignResponsibleDialog.openWithTask(tId, projectController.projectData.taskModel.getTask(tId).responsible) }
                }
            }
        }
    }

    Dialog
    {
        id: renameGroupDialog
        title: "Переименовать группу"
        width: 400
        height: 230
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: Overlay.overlay

        property string groupId: ""

        function openWithGroup(gId, gName)
        {
            groupId = gId
            newNameField.text = gName
            open()
        }

        ColumnLayout
        {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Label
            {
                text: "Новое название группы:"
                Layout.fillWidth: true
                font.pixelSize: 13
            }

            TextField
            {
                id: newNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Введите название группы"
                font.pixelSize: 13
                focus: true
                onAccepted:
                {
                    if (newNameField.text !== "")
                    {
                        renameGroupDialog.accept()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 10

                Button
                {
                    text: "Отмена"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    onClicked: renameGroupDialog.close()
                }

                Button
                {
                    text: "ОК"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    enabled: newNameField.text !== ""
                    onClicked: renameGroupDialog.accept()
                }
            }
        }

        onAccepted:
        {
            if (newNameField.text !== "" && projectController && projectController.projectData && groupId)
            {
                projectController.projectData.groupModel.renameGroup(groupId, newNameField.text)
            }
        }
    }

    Dialog
    {
        id: renameTaskDialog
        title: "Переименовать задачу"
        width: 400
        height: 230
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: Overlay.overlay

        property string taskId: ""

        function openWithTask(tId, tTitle)
        {
            taskId = tId
            taskNewNameField.text = tTitle
            open()
        }

        ColumnLayout
        {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Label
            {
                text: "Новое название задачи:"
                Layout.fillWidth: true
                font.pixelSize: 13
            }

            TextField
            {
                id: taskNewNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Введите название задачи"
                font.pixelSize: 13
                focus: true
                onAccepted:
                {
                    if (taskNewNameField.text !== "")
                    {
                        renameTaskDialog.accept()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 10

                Button
                {
                    text: "Отмена"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    onClicked: renameTaskDialog.close()
                }

                Button
                {
                    text: "ОК"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    enabled: taskNewNameField.text !== ""
                    onClicked: renameTaskDialog.accept()
                }
            }
        }

        onAccepted:
        {
            if (taskNewNameField.text !== "" && projectController && projectController.projectData && taskId)
            {
                var task = projectController.projectData.taskModel.getTask(taskId)
                if (task)
                {
                    projectController.projectData.taskModel.updateTask(
                        taskId, taskNewNameField.text, task.responsible,
                        task.startDate, task.endDate, task.status
                    )
                }
            }
        }
    }

    Dialog
    {
        id: assignResponsibleDialog
        title: "Назначить ответственного"
        width: 400
        height: 230
        modal: true
        standardButtons: Dialog.NoButton
        anchors.centerIn: Overlay.overlay

        property string taskId: ""

        function openWithTask(tId, tResponsible)
        {
            taskId = tId
            responsibleField.text = tResponsible ? tResponsible : ""
            open()
        }

        ColumnLayout
        {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Label
            {
                text: "ФИО ответственного:"
                Layout.fillWidth: true
                font.pixelSize: 13
            }

            TextField
            {
                id: responsibleField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Введите ФИО ответственного"
                font.pixelSize: 13
                focus: true
                onAccepted:
                {
                    if (responsibleField.text !== "")
                    {
                        assignResponsibleDialog.accept()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 10

                Button
                {
                    text: "Отмена"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    onClicked: assignResponsibleDialog.close()
                }

                Button
                {
                    text: "ОК"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    enabled: responsibleField.text !== ""
                    onClicked: assignResponsibleDialog.accept()
                }
            }
        }

        onAccepted:
        {
            if (responsibleField.text !== "" && projectController && projectController.projectData && taskId)
            {
                var task = projectController.projectData.taskModel.getTask(taskId)
                if (task)
                {
                    projectController.projectData.taskModel.updateTask(
                        taskId, task.title, responsibleField.text,
                        task.startDate, task.endDate, task.status
                    )
                }
            }
        }
    }

    function addTaskAbove(existingTaskId)
    {
        mainWindow.newTaskDialog.openForGroup(groupId, existingTaskId)
    }

    function addTaskBelow(existingTaskId)
    {
        var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
        var index = tasks.indexOf(existingTaskId)
        var insertAfter = (index >= 0 && index + 1 < tasks.length) ? tasks[index + 1] : ""
        mainWindow.newTaskDialog.openForGroup(groupId, insertAfter)
    }

    function addGroupAbove()
    {
        if (projectController && projectController.projectData)
        {
            var groupIds = projectController.projectData.groupModel.getGroupIds()
            var index = groupIds.indexOf(groupId)
            if (index < 0) index = 0
            projectController.projectData.groupModel.addGroupAt(index, "Новая группа")
        }
    }

    function addGroupBelow()
    {
        if (projectController && projectController.projectData)
        {
            var groupIds = projectController.projectData.groupModel.getGroupIds()
            var index = groupIds.indexOf(groupId)
            if (index < 0) index = groupIds.length
            projectController.projectData.groupModel.addGroupAt(index + 1, "Новая группа")
        }
    }

    function deleteGroup()
    {
        if (projectController && projectController.projectData)
        {
            var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
            for (var i = tasks.length - 1; i >= 0; i--)
            {
                projectController.removeTask(tasks[i])
            }
            projectController.projectData.groupModel.removeGroup(groupId)
        }
    }
}
