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
    property var flickableRight: null

    property var rowsModel: []

    function currentViewMode()
    {
        return projectController && projectController.settingsManager
               ? projectController.settingsManager.viewMode : 0
    }

    function refreshTasks()
    {
        if (!projectController || !projectController.projectData || !groupId)
        {
            rowsModel = []
            return
        }

        var mode = currentViewMode()
        var taskIds = projectController.projectData.taskModel.getTasksForGroup(groupId)
        var rows = []

        for (var i = 0; i < taskIds.length; i++)
        {
            var taskData = projectController.projectData.taskModel.getTask(taskIds[i])
            if (!taskData) continue
            var isCompleted = (taskData.status === 1)

            if (mode === 0)
            {
                rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: isCompleted})
            }
            else if (mode === 1)
            {
                if (isCompleted)
                    rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: true})
                else
                    rows.push({taskId: taskIds[i], rowKind: "forecast", data: taskData, isCompleted: false})
            }
            else
            {
                rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: isCompleted})
                if (!isCompleted)
                    rows.push({taskId: taskIds[i], rowKind: "forecast", data: taskData, isCompleted: false})
            }
        }

        rowsModel = rows
    }

    Component.onCompleted: refreshTasks()

    Connections
    {
        target: projectController && projectController.projectData ? projectController.projectData.taskModel : null
        function onCountChanged() { refreshTasks() }
        function onRowsInserted() { refreshTasks() }
        function onRowsRemoved() { refreshTasks() }
        function onDataChanged() { refreshTasks() }
    }

    Connections
    {
        target: projectController && projectController.projectData ? projectController.projectData.groupModel : null
        function onDataChanged() { refreshTasks() }

        function onGroupExpandedChanged(changedGroupId)
        {
            if (changedGroupId === groupId)
            {
                var savedY = root.flickableRight ? root.flickableRight.contentY : 0
                refreshTasks()
                if (root.flickableRight)
                {
                    var maxY = Math.max(0, root.flickableRight.contentHeight - root.flickableRight.height)
                    root.flickableRight.contentY = Math.min(savedY, maxY)
                }
            }
        }

        function onRowsInserted() { refreshTasks() }
        function onRowsRemoved() { refreshTasks() }
    }

    Connections
    {
        target: projectController?.settingsManager
        function onViewModeChanged() { refreshTasks() }
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
                            projectController.projectData.groupModel.setGroupExpanded(groupId, !root.expanded)
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
                    groupContextMenu.popup()
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
                        mainWindow.newTaskDialog.openForGroup(groupId)
                        refreshTasks()
                        if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.gridArea)
                            mainWindow.gridArea.updateData()
                    }
                }
            }

            MenuItem
            {
                text: "Переименовать"
                onTriggered: renameGroupDialog.openWithGroup(groupId, groupName)
            }

            MenuSeparator {}

            MenuItem { text: "Добавить группу сверху"; onTriggered: addGroupAbove() }
            MenuItem { text: "Добавить группу снизу"; onTriggered: addGroupBelow() }

            MenuSeparator {}

            MenuItem { text: "Удалить"; onTriggered: deleteGroup() }
        }
    }

    Column
    {
        id: tasksColumn
        y: groupHeader.height
        width: parent.width
        visible: root.expanded
        height: rowsRepeater.count * 40

        Repeater
        {
            id: rowsRepeater
            model: root.rowsModel

            delegate: Rectangle
            {
                width: root.width
                height: 40
                color: "white"
                border.color: "#eeeeee"
                border.width: 1

                property string taskId: modelData ? modelData.taskId : ""
                property string rowKind: modelData ? modelData.rowKind : "target"
                property var taskData: modelData ? modelData.data : null

                function isValidDate(d)
                {
                    return d !== undefined && d !== null && !isNaN(new Date(d).getTime())
                }

                function hasDates()
                {
                    if (!taskData) return false
                    return isValidDate(taskData.startDate) && isValidDate(taskData.endDate)
                }

                function titleText()
                {
                    if (!taskData) return ""
                    var prefix = ""
                    if (taskData.localGraphState !== undefined && taskData.localGraphState !== 0)
                        prefix = "* "
                    return prefix + taskData.title
                }

                function responsibleText()
                {
                    if (!taskData) return ""
                    var r = taskData.responsible
                    return (r && r.length > 0) ? r : "—"
                }

                function startDateText()
                {
                    if (!taskData) return "—"
                    var d
                    if (rowKind === "forecast" && !modelData.isCompleted)
                        d = taskData.forecastStart
                    else
                        d = taskData.startDate
                    if (!isValidDate(d)) return "—"
                    return Qt.formatDateTime(new Date(d), "dd.MM.yyyy")
                }

                function endDateText()
                {
                    if (!taskData) return "—"
                    var d
                    if (rowKind === "forecast" && !modelData.isCompleted)
                        d = taskData.forecastEnd
                    else
                        d = taskData.endDate
                    if (!isValidDate(d)) return "—"
                    return Qt.formatDateTime(new Date(d), "dd.MM.yyyy")
                }

                function viewLabelText()
                {
                    if (rowKind === "forecast") return "Прогноз"
                    if (modelData && modelData.isCompleted) return "Факт"
                    if (!hasDates()) return "Драфт"
                    return "Цель"
                }

                Row
                {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 0

                    Rectangle
                    {
                        width: parent.width - 265
                        height: parent.height
                        color: "transparent"

                        Row
                        {
                            anchors.fill: parent
                            Rectangle
                            {
                                width: parent.width * 0.64
                                height: parent.height
                                color: "transparent"
                                Text
                                {
                                    text: titleText()
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: parent.width - 20
                                    font.pixelSize: 12
                                    color: "#222222"
                                }
                            }
                            Rectangle
                            {
                                width: parent.width * 0.36
                                height: parent.height
                                color: "transparent"
                                Text
                                {
                                    text: responsibleText()
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: parent.width - 10
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    Rectangle
                    {
                        width: 65
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: viewLabelText()
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: "#444444"
                        }
                    }

                    Rectangle
                    {
                        width: 100
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: startDateText()
                            anchors.left: parent.left
                            anchors.leftMargin: 30
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                        }
                    }

                    Rectangle
                    {
                        width: 100
                        height: parent.height
                        color: "transparent"
                        Text
                        {
                            text: endDateText()
                            anchors.left: parent.left
                            anchors.leftMargin: 30
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
                        if (mouse.button === Qt.RightButton && taskId)
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

            Label { text: "Новое название группы:"; Layout.fillWidth: true; font.pixelSize: 13 }

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
                        renameGroupDialog.accept()
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
                projectController.projectData.groupModel.renameGroup(groupId, newNameField.text)
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
                projectController.removeTask(tasks[i])
            projectController.projectData.groupModel.removeGroup(groupId)
        }
    }
}
