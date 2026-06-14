import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Выберите зависимую задачу"
    width: 500
    height: 400
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: Overlay.overlay

    property string sourceTaskId: ""
    property string targetTaskId: ""
    property bool downstream: true

    property var taskList: []
    property var groupList: []

    function loadTasks()
    {
        taskList = []
        groupList = projectController.projectData.groupModel.getGroupIds()
        for (var g = 0; g < groupList.length; g++)
        {
            var groupId = groupList[g]
            var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
            for (var t = 0; t < tasks.length; t++)
            {
                if (tasks[t] !== sourceTaskId)
                {
                    taskList.push({
                        taskId: tasks[t],
                        groupId: groupId,
                        title: projectController.projectData.taskModel.getTask(tasks[t]).title,
                        groupName: projectController.projectData.groupModel.getGroup(groupId).name
                    })
                }
            }
        }
        taskListView.model = taskList
    }

    function openForTask(taskId, isDownstream)
    {
        root.sourceTaskId = taskId
        root.downstream = isDownstream
        root.targetTaskId = ""
        root.open()
    }

    onOpened: loadTasks()

    onAccepted:
    {
        console.log("DependencyDialog accepted, targetTaskId:", targetTaskId, "sourceTaskId:", sourceTaskId)
        if (targetTaskId && sourceTaskId)
        {
            if (downstream)
                projectController.addDependency(sourceTaskId, targetTaskId)
            else
                projectController.addDependency(targetTaskId, sourceTaskId)
        }
    }

    ListView
    {
        id: taskListView
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        delegate: Rectangle
        {
            width: parent.width
            height: 40
            color: mouseArea.containsMouse ? "#e0e0e0" : "white"
            border.color: "#cccccc"
            border.width: 1

            Text
            {
                text: modelData.title + " (" + modelData.groupName + ")"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 13
            }

            MouseArea
            {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked:
                {
                    root.targetTaskId = modelData.taskId
                    root.accept()
                }
            }
        }
    }
}