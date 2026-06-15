import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Создание каскада задач"
    width: 900
    height: 550
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: Overlay.overlay

    property int taskCount: 0
    property date startDate: new Date()
    property var cascadeModel: []

    function buildCascade()
    {
        cascadeModel = []
        for (var i = 0; i < taskCount; i++)
        {
            cascadeModel.push({
                groupIndex: 0,
                title: "Задача " + (i + 1),
                responsible: "",
                duration: 7
            })
        }
        cascadeRepeater.model = cascadeModel
    }

    onOpened:
    {
        countField.forceActiveFocus()
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 10

            Label { text: "Количество задач:" }
            TextField
            {
                id: countField
                Layout.preferredWidth: 60
                text: "3"
                validator: IntValidator { bottom: 1; top: 100 }
                onEditingFinished:
                {
                    root.taskCount = parseInt(text) || 3
                    root.buildCascade()
                }
            }

            Label { text: "Дата начала:" }
            TextField
            {
                id: startDateField
                Layout.preferredWidth: 100
                text: Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                onEditingFinished:
                {
                    var parts = text.split(".")
                    if (parts.length === 3)
                    {
                        var d = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
                        if (!isNaN(d.getTime()))
                            root.startDate = d
                    }
                }
            }

            Button
            {
                text: "Построить"
                onClicked:
                {
                    root.taskCount = parseInt(countField.text) || 3
                    root.buildCascade()
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#cccccc" }

        ScrollView
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout
            {
                width: parent.width
                spacing: 5

                Repeater
                {
                    id: cascadeRepeater
                    model: cascadeModel

                    delegate: RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 5

                        Label { text: (index + 1) + "."; Layout.preferredWidth: 25 }

                        ComboBox
                        {
                            Layout.preferredWidth: 160
                            model: projectController.projectData.groupModel.getGroupIds().map(function(id) {
                                return projectController.projectData.groupModel.getGroup(id).name
                            })
                            onCurrentIndexChanged:
                            {
                                if (cascadeModel[index])
                                    cascadeModel[index].groupIndex = currentIndex
                            }
                        }

                        TextField
                        {
                            Layout.fillWidth: true
                            text: modelData ? modelData.title : ""
                            onTextChanged:
                            {
                                if (cascadeModel[index])
                                    cascadeModel[index].title = text
                            }
                        }

                        TextField
                        {
                            Layout.preferredWidth: 120
                            placeholderText: "Ответств."
                            text: modelData ? modelData.responsible : ""
                            onTextChanged:
                            {
                                if (cascadeModel[index])
                                    cascadeModel[index].responsible = text
                            }
                        }

                        TextField
                        {
                            Layout.preferredWidth: 60
                            text: modelData ? modelData.duration : "7"
                            validator: IntValidator { bottom: 1; top: 365 }
                            onTextChanged:
                            {
                                if (cascadeModel[index])
                                    cascadeModel[index].duration = parseInt(text) || 7
                            }
                        }

                        Label { text: "дн."; Layout.preferredWidth: 30 }
                    }
                }
            }
        }
    }

    onAccepted:
    {
        if (cascadeModel.length === 0) return

        var currentDate = new Date(root.startDate)
        var prevTaskId = ""

        for (var i = 0; i < cascadeModel.length; i++)
        {
            var item = cascadeModel[i]
            var groupIds = projectController.projectData.groupModel.getGroupIds()
            var groupId = groupIds[item.groupIndex] || groupIds[0]
            var endDate = new Date(currentDate)
            endDate.setDate(endDate.getDate() + item.duration - 1)

            projectController.addTask(groupId, item.title, item.responsible, currentDate, endDate)

            var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
            var newTaskId = tasks[tasks.length - 1]

            if (prevTaskId)
            {
                projectController.addDependency(prevTaskId, newTaskId)
            }

            prevTaskId = newTaskId
            currentDate = new Date(endDate)
            currentDate.setDate(currentDate.getDate() + 1)
        }

        if (mainWindow && mainWindow.gridArea)
            mainWindow.gridArea.updateData()
    }
}
