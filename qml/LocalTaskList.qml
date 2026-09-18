import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Flickable
{
    id: root
    clip: true
    contentWidth: width
    contentHeight: tasksColumn.height
    boundsBehavior: Flickable.StopAtBounds
    interactive: false

    property var flickableRight: null

    contentY: flickableRight ? flickableRight.contentY : 0

    function taskIds()
    {
        if (!projectController || !projectController.projectData) return []
        var all = projectController.projectData.taskModel.getAllTasks()
        var ids = []
        for (var i = 0; i < all.length; i++)
            ids.push(all[i].id)
        return ids
    }

    property var taskList: []

    function refreshTasks()
    {
        taskList = taskIds()
        tasksRepeater.model = taskList
    }

    Component.onCompleted: refreshTasks()

    Connections
    {
        target: projectController?.projectData?.taskModel
        function onCountChanged() { refreshTasks() }
        function onRowsInserted() { refreshTasks() }
        function onRowsRemoved() { refreshTasks() }
        function onDataChanged() { refreshTasks() }
        function onModelReset() { refreshTasks() }
    }

    Column
    {
        id: tasksColumn
        width: root.width
        spacing: 0

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
                property var taskData: (projectController && projectController.projectData)
                                       ? projectController.projectData.taskModel.getTask(taskId) : null

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
                    if (!taskData) return "—"
                    var r = taskData.responsible
                    return (r && r.length > 0) ? r : "—"
                }

                function startDateText()
                {
                    if (!taskData) return "—"
                    if (!isValidDate(taskData.startDate)) return "—"
                    return Qt.formatDateTime(new Date(taskData.startDate), "dd.MM.yyyy")
                }

                function endDateText()
                {
                    if (!taskData) return "—"
                    if (!isValidDate(taskData.endDate)) return "—"
                    return Qt.formatDateTime(new Date(taskData.endDate), "dd.MM.yyyy")
                }

                function viewLabelText()
                {
                    if (!taskData) return ""
                    if (taskData.status === 1) return "Факт"
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
                }
            }
        }
    }
}
