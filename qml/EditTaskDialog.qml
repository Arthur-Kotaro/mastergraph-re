import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Редактирование сроков задачи"
    width: 560
    height: 280
    modal: true
    anchors.centerIn: Overlay.overlay
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    property string taskId: ""
    property date startDate: new Date()
    property date endDate: new Date()

    function loadTaskData()
    {
        if (!taskId || taskId === "")
        {
            return false
        }
        var task = projectController?.projectData?.taskModel?.getTask(taskId)
        if (task)
        {
            startDate = task.startDate
            endDate = task.endDate
            errorLabel.visible = false
            startDateField.text = Qt.formatDateTime(startDate, "dd.MM.yyyy")
            endDateField.text = Qt.formatDateTime(endDate, "dd.MM.yyyy")
            return true
        }
        return false
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 4
        anchors.bottomMargin: 8
        spacing: 8

        Label
        {
            text: "Измените даты задачи:"
            font.bold: true
            font.pixelSize: 14
            Layout.fillWidth: true
            leftPadding: 0
        }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 20

            ColumnLayout
            {
                Layout.fillWidth: true
                spacing: 4

                Label
                {
                    text: "Дата начала:"
                    font.bold: true
                    font.pixelSize: 12
                    leftPadding: 0
                }

                TextField
                {
                    id: startDateField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: 6
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

                Button
                {
                    text: "Выбрать дату"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    onClicked: startCalendarPopup.open()
                }

                Popup
                {
                    id: startCalendarPopup
                    width: 380
                    height: 360
                    modal: true
                    focus: true
                    anchors.centerIn: Overlay.overlay

                    property int calendarYear: root.startDate.getFullYear()
                    property int calendarMonth: root.startDate.getMonth()
                    property var calendarModel: []

                    function updateCalendarModel()
                    {
                        var firstDay = new Date(calendarYear, calendarMonth, 1)
                        var startWeekday = firstDay.getDay()
                        var startIndex = (startWeekday === 0) ? 6 : startWeekday - 1
                        var daysInMonth = new Date(calendarYear, calendarMonth + 1, 0).getDate()
                        var result = []
                        for (var i = 0; i < startIndex; i++) result.push("")
                        for (var i = 1; i <= daysInMonth; i++) result.push(i)
                        var remaining = (7 - (result.length % 7)) % 7
                        for (var i = 0; i < remaining; i++) result.push("")
                        calendarModel = result
                    }

                    Component.onCompleted: updateCalendarModel()

                    Rectangle
                    {
                        anchors.fill: parent
                        color: "white"
                        border.color: "#cccccc"
                        radius: 4

                        ColumnLayout
                        {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            RowLayout
                            {
                                Layout.fillWidth: true
                                Button
                                {
                                    text: "<<"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 45
                                    onClicked:
                                    {
                                        startCalendarPopup.calendarYear -= 1
                                        startCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Button
                                {
                                    text: "<"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 40
                                    onClicked:
                                    {
                                        if (startCalendarPopup.calendarMonth === 0)
                                        {
                                            startCalendarPopup.calendarMonth = 11
                                            startCalendarPopup.calendarYear -= 1
                                        }
                                        else
                                        {
                                            startCalendarPopup.calendarMonth -= 1
                                        }
                                        startCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Label
                                {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 16
                                    font.bold: true
                                    text:
                                    {
                                        var months = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                                     "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
                                        return months[startCalendarPopup.calendarMonth] + " " + startCalendarPopup.calendarYear
                                    }
                                }
                                Button
                                {
                                    text: ">"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 40
                                    onClicked:
                                    {
                                        if (startCalendarPopup.calendarMonth === 11)
                                        {
                                            startCalendarPopup.calendarMonth = 0
                                            startCalendarPopup.calendarYear += 1
                                        }
                                        else
                                        {
                                            startCalendarPopup.calendarMonth += 1
                                        }
                                        startCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Button
                                {
                                    text: ">>"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 45
                                    onClicked:
                                    {
                                        startCalendarPopup.calendarYear += 1
                                        startCalendarPopup.updateCalendarModel()
                                    }
                                }
                            }

                            Rectangle
                            {
                                Layout.fillWidth: true
                                height: 25
                                color: "#f0f0f0"
                                Row
                                {
                                    spacing: 2
                                    Repeater
                                    {
                                        model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                                        Label
                                        {
                                            width: 46
                                            height: 25
                                            text: modelData
                                            font.pixelSize: 13
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }

                            GridView
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cellWidth: 48
                                cellHeight: 40

                                model: startCalendarPopup.calendarModel
                                delegate: Rectangle
                                {
                                    width: 46
                                    height: 38
                                    color:
                                    {
                                        if (modelData === "") return "transparent"
                                        var cellDate = new Date(startCalendarPopup.calendarYear, startCalendarPopup.calendarMonth, modelData)
                                        if (cellDate.toDateString() === root.startDate.toDateString()) return "#0078d7"
                                        return "transparent"
                                    }
                                    radius: 3

                                    Text
                                    {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: parent.color === "#0078d7" ? "white" : "black"
                                        font.pixelSize: 14
                                    }

                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        onClicked:
                                        {
                                            if (modelData !== "")
                                            {
                                                var newDate = new Date(startCalendarPopup.calendarYear, startCalendarPopup.calendarMonth, modelData)
                                                root.startDate = newDate
                                                startDateField.text = Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                                                startCalendarPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                spacing: 4

                Label
                {
                    text: "Дата завершения:"
                    font.bold: true
                    font.pixelSize: 12
                    leftPadding: 0
                }

                TextField
                {
                    id: endDateField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: Qt.formatDateTime(root.endDate, "dd.MM.yyyy")
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: 6
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

                Button
                {
                    text: "Выбрать дату"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    onClicked: endCalendarPopup.open()
                }

                Popup
                {
                    id: endCalendarPopup
                    width: 380
                    height: 360
                    modal: true
                    focus: true
                    anchors.centerIn: Overlay.overlay

                    property int calendarYear: root.endDate.getFullYear()
                    property int calendarMonth: root.endDate.getMonth()
                    property var calendarModel: []

                    function updateCalendarModel()
                    {
                        var firstDay = new Date(calendarYear, calendarMonth, 1)
                        var startWeekday = firstDay.getDay()
                        var startIndex = (startWeekday === 0) ? 6 : startWeekday - 1
                        var daysInMonth = new Date(calendarYear, calendarMonth + 1, 0).getDate()
                        var result = []
                        for (var i = 0; i < startIndex; i++) result.push("")
                        for (var i = 1; i <= daysInMonth; i++) result.push(i)
                        var remaining = (7 - (result.length % 7)) % 7
                        for (var i = 0; i < remaining; i++) result.push("")
                        calendarModel = result
                    }

                    Component.onCompleted: updateCalendarModel()

                    Rectangle
                    {
                        anchors.fill: parent
                        color: "white"
                        border.color: "#cccccc"
                        radius: 4

                        ColumnLayout
                        {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            RowLayout
                            {
                                Layout.fillWidth: true
                                Button
                                {
                                    text: "<<"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 45
                                    onClicked:
                                    {
                                        endCalendarPopup.calendarYear -= 1
                                        endCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Button
                                {
                                    text: "<"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 40
                                    onClicked:
                                    {
                                        if (endCalendarPopup.calendarMonth === 0)
                                        {
                                            endCalendarPopup.calendarMonth = 11
                                            endCalendarPopup.calendarYear -= 1
                                        }
                                        else
                                        {
                                            endCalendarPopup.calendarMonth -= 1
                                        }
                                        endCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Label
                                {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 16
                                    font.bold: true
                                    text:
                                    {
                                        var months = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                                     "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
                                        return months[endCalendarPopup.calendarMonth] + " " + endCalendarPopup.calendarYear
                                    }
                                }
                                Button
                                {
                                    text: ">"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 40
                                    onClicked:
                                    {
                                        if (endCalendarPopup.calendarMonth === 11)
                                        {
                                            endCalendarPopup.calendarMonth = 0
                                            endCalendarPopup.calendarYear += 1
                                        }
                                        else
                                        {
                                            endCalendarPopup.calendarMonth += 1
                                        }
                                        endCalendarPopup.updateCalendarModel()
                                    }
                                }
                                Button
                                {
                                    text: ">>"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 45
                                    onClicked:
                                    {
                                        endCalendarPopup.calendarYear += 1
                                        endCalendarPopup.updateCalendarModel()
                                    }
                                }
                            }

                            Rectangle
                            {
                                Layout.fillWidth: true
                                height: 25
                                color: "#f0f0f0"
                                Row
                                {
                                    spacing: 2
                                    Repeater
                                    {
                                        model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                                        Label
                                        {
                                            width: 46
                                            height: 25
                                            text: modelData
                                            font.pixelSize: 13
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }

                            GridView
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cellWidth: 48
                                cellHeight: 40

                                model: endCalendarPopup.calendarModel
                                delegate: Rectangle
                                {
                                    width: 46
                                    height: 38
                                    color:
                                    {
                                        if (modelData === "") return "transparent"
                                        var cellDate = new Date(endCalendarPopup.calendarYear, endCalendarPopup.calendarMonth, modelData)
                                        if (cellDate.toDateString() === root.endDate.toDateString()) return "#0078d7"
                                        return "transparent"
                                    }
                                    radius: 3

                                    Text
                                    {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: parent.color === "#0078d7" ? "white" : "black"
                                        font.pixelSize: 14
                                    }

                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        onClicked:
                                        {
                                            if (modelData !== "")
                                            {
                                                var newDate = new Date(endCalendarPopup.calendarYear, endCalendarPopup.calendarMonth, modelData)
                                                root.endDate = newDate
                                                endDateField.text = Qt.formatDateTime(root.endDate, "dd.MM.yyyy")
                                                endCalendarPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Label
        {
            id: errorLabel
            color: "red"
            visible: false
            text: "Дата завершения не может быть раньше даты начала"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            leftPadding: 0
        }

        RowLayout
        {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Button
            {
                text: "ОК"
                Layout.preferredHeight: 30
                Layout.preferredWidth: 85
                font.pixelSize: 13
                onClicked:
                {
                    if (startDate <= endDate)
                    {
                        projectController.updateTaskDates(taskId, startDate, endDate)
                        //console.log("EditTaskDialog: updateTaskDates called, taskId:", taskId, "start:", startDate, "end:", endDate)
                        // if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.gridArea)
                        // {
                        //     mainWindow.gridArea.updateData()
                        // }
                        root.close()
                    }
                    else
                    {
                        errorLabel.visible = true
                    }
                }
            }

            Button
            {
                text: "Отмена"
                Layout.preferredHeight: 30
                Layout.preferredWidth: 85
                font.pixelSize: 13
                onClicked: root.close()
            }
        }
    }

    onOpened:
    {
        loadTaskData()
    }

    function openForTask(tId)
    {
        if (!tId || tId === "")
        {
            return
        }
        root.taskId = tId
        root.open()
    }
}
