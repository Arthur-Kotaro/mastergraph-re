import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Завершить задачу"
    width: 450
    height: 300
    modal: true
    standardButtons: Dialog.NoButton
    anchors.centerIn: Overlay.overlay

    property string taskId: ""
    property date startDate: new Date()
    property date endDate: new Date()

    function openForTask(tId)
    {
        taskId = tId
        var task = projectController?.projectData?.taskModel?.getTask(tId)
        if (task)
        {
            startDate = task.startDate
            endDate = new Date()
        }
        else
        {
            startDate = new Date()
            endDate = new Date()
        }
        startDateField.text = Qt.formatDateTime(startDate, "dd.MM.yyyy")
        endDateField.text = Qt.formatDateTime(endDate, "dd.MM.yyyy")
        open()
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label
        {
            text: "Дата начала:"
            font.bold: true
            font.pixelSize: 13
        }

        TextField
        {
            id: startDateField
            Layout.fillWidth: true
            text: Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            onEditingFinished:
            {
                var parts = text.split(".")
                if (parts.length === 3)
                {
                    var d = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
                    if (!isNaN(d.getTime()))
                    {
                        root.startDate = d
                        text = Qt.formatDateTime(d, "dd.MM.yyyy")
                    }
                    else
                    {
                        text = Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                    }
                }
                else
                {
                    text = Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                }
            }
        }

        Label
        {
            text: "Дата завершения:"
            font.bold: true
            font.pixelSize: 13
        }

        TextField
        {
            id: endDateField
            Layout.fillWidth: true
            text: Qt.formatDateTime(root.endDate, "dd.MM.yyyy")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            onEditingFinished:
            {
                var parts = text.split(".")
                if (parts.length === 3)
                {
                    var d = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
                    if (!isNaN(d.getTime()))
                    {
                        root.endDate = d
                        text = Qt.formatDateTime(d, "dd.MM.yyyy")
                    }
                    else
                    {
                        text = Qt.formatDateTime(root.endDate, "dd.MM.yyyy")
                    }
                }
                else
                {
                    text = Qt.formatDateTime(root.endDate, "dd.MM.yyyy")
                }
            }
        }

        RowLayout
        {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button
            {
                text: "Отмена"
                width: 80
                height: 35
                onClicked: root.close()
            }

            Button
            {
                text: "Завершить"
                width: 100
                height: 35
                onClicked:
                {
                    if (taskId && projectController)
                    {
                        projectController.updateTaskDates(taskId, startDate, endDate)
                        projectController.projectData.taskModel.setTaskStatus(taskId, 1)
                    }
                    root.close()
                }
            }
        }
    }
}
