import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import Qt.labs.platform 1.1 as Labs

Dialog
{
    id: root
    title: "Создание нового мастерграфика"
    width: 950
    height: 650
    modal: true
    standardButtons: Dialog.NoButton
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    property string projectName: ""
    property string projectType: ""
    property date startDate: new Date()
    property string filePath: ""
    property bool useDefaultGroups: true
    property var selectedGroups: []

    property var typologiesModel: []
    property var taskGroupsModel: []

    function loadTypologies()
    {
        if (projectController && projectController.resourceManager)
        {
            typologiesModel = projectController.resourceManager.loadTypologies()
        }
    }

    function loadTaskGroups()
    {
        if (projectController && projectController.resourceManager)
        {
            taskGroupsModel = projectController.resourceManager.loadTaskGroups()
        }
    }

    function refreshData()
    {
        loadTypologies()
        loadTaskGroups()
    }

    function createProject()
    {
        if (root.projectName && root.projectType && root.filePath)
        {
            var fullPath = root.filePath
            if (!fullPath.endsWith(".gantt")) fullPath += ".gantt"
            projectController.createNewProject(
                root.projectName,
                root.projectType,
                root.startDate,
                fullPath,
                root.selectedGroups
            )
            root.close()
        }
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        RowLayout
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 15

                GroupBox
                {
                    title: "Основные параметры"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout
                    {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        ColumnLayout
                        {
                            Layout.fillWidth: true
                            spacing: 6

                            Label
                            {
                                text: "Название проекта:"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            TextField
                            {
                                id: nameField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "Введите название проекта"
                                font.pixelSize: 13
                                onTextChanged: root.projectName = text
                                onAccepted: createProject()
                            }
                        }

                        ColumnLayout
                        {
                            Layout.fillWidth: true
                            spacing: 6

                            Label
                            {
                                text: "Типология проекта:"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            ComboBox
                            {
                                id: typeCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                font.pixelSize: 13
                                model: typologiesModel
                                textRole: "name"
                                onCurrentValueChanged:
                                {
                                    if (currentValue) root.projectType = currentValue.typology_name
                                }
                            }
                        }

                        ColumnLayout
                        {
                            Layout.fillWidth: true
                            spacing: 6

                            Label
                            {
                                text: "Дата начала:"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            RowLayout
                            {
                                Layout.fillWidth: true
                                spacing: 10

                                TextField
                                {
                                    id: dateField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    text: Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                                    font.pixelSize: 13
                                    placeholderText: "ДД.ММ.ГГГГ"
                                    inputMethodHints: Qt.ImhDate
                                    validator: RegularExpressionValidator
                                    {
                                        regularExpression: /^\d{2}\.\d{2}\.\d{4}$/
                                    }
                                    onTextChanged:
                                    {
                                        var parts = text.split(".")
                                        if (parts.length === 3)
                                        {
                                            var newDate = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
                                            if (!isNaN(newDate.getTime()))
                                            {
                                                root.startDate = newDate
                                            }
                                        }
                                    }
                                }

                                Button
                                {
                                    text: "📅"
                                    Layout.preferredHeight: 40
                                    Layout.preferredWidth: 40
                                    font.pixelSize: 16
                                    onClicked: calendarPopup.open()
                                }
                            }

                            Popup
                            {
                                id: calendarPopup
                                width: 350
                                height: 320
                                x: parent.width - width
                                y: 45
                                modal: true
                                focus: true

                                Rectangle
                                {
                                    anchors.fill: parent
                                    color: "white"
                                    border.color: "#cccccc"
                                    border.width: 1
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
                                                text: "<"
                                                font.pixelSize: 14
                                                Layout.preferredWidth: 40
                                                onClicked:
                                                {
                                                    var newDate = new Date(calendarYear, calendarMonth - 1, 1)
                                                    calendarYear = newDate.getFullYear()
                                                    calendarMonth = newDate.getMonth()
                                                    updateCalendarModel()
                                                }
                                            }
                                            Label
                                            {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                font.pixelSize: 14
                                                font.bold: true
                                                text:
                                                {
                                                    var months = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                                                 "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
                                                    return months[calendarMonth] + " " + calendarYear
                                                }
                                            }
                                            Button
                                            {
                                                text: ">"
                                                font.pixelSize: 14
                                                Layout.preferredWidth: 40
                                                onClicked:
                                                {
                                                    var newDate = new Date(calendarYear, calendarMonth + 1, 1)
                                                    calendarYear = newDate.getFullYear()
                                                    calendarMonth = newDate.getMonth()
                                                    updateCalendarModel()
                                                }
                                            }
                                        }

                                        GridView
                                        {
                                            id: calendarGrid
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            cellWidth: 44
                                            cellHeight: 38

                                            property var dayNames: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

                                            header: Row
                                            {
                                                spacing: 2
                                                Repeater
                                                {
                                                    model: calendarGrid.dayNames
                                                    Label
                                                    {
                                                        width: 42
                                                        height: 30
                                                        text: modelData
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                }
                                            }

                                            model: calendarModel
                                            delegate: Rectangle
                                            {
                                                width: 42
                                                height: 36
                                                color:
                                                {
                                                    if (modelData === "") return "transparent"
                                                    var cellDate = new Date(calendarYear, calendarMonth, modelData)
                                                    if (cellDate.toDateString() === root.startDate.toDateString()) return "#0078d7"
                                                    return "transparent"
                                                }
                                                radius: 3

                                                Text
                                                {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: parent.color === "#0078d7" ? "white" : "black"
                                                    font.pixelSize: 13
                                                }

                                                MouseArea
                                                {
                                                    anchors.fill: parent
                                                    onClicked:
                                                    {
                                                        if (modelData !== "")
                                                        {
                                                            var newDate = new Date(calendarYear, calendarMonth, modelData)
                                                            root.startDate = newDate
                                                            dateField.text = Qt.formatDateTime(root.startDate, "dd.MM.yyyy")
                                                            calendarPopup.close()
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
                            spacing: 6

                            Label
                            {
                                text: "Путь к файлу графика:"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            RowLayout
                            {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField
                                {
                                    id: filePathField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    font.pixelSize: 13
                                    placeholderText: "Выберите место сохранения файла (.gantt)"
                                    onTextChanged: root.filePath = text
                                    onAccepted: createProject()
                                }

                                Button
                                {
                                    text: "Обзор..."
                                    Layout.preferredHeight: 40
                                    Layout.preferredWidth: 90
                                    font.pixelSize: 13
                                    onClicked: saveFileDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 15

                GroupBox
                {
                    title: "Типовые группы задач"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout
                    {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ScrollView
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ColumnLayout
                            {
                                width: parent.width
                                spacing: 6

                                Repeater
                                {
                                    id: groupsRepeater
                                    model: taskGroupsModel

                                    delegate: CheckBox
                                    {
                                        text: modelData.name
                                        font.pixelSize: 13
                                        checked: root.useDefaultGroups
                                        onCheckedChanged:
                                        {
                                            if (checked && !root.selectedGroups.includes(modelData.name))
                                            {
                                                root.selectedGroups.push(modelData.name)
                                            }
                                            else if (!checked && root.selectedGroups.includes(modelData.name))
                                            {
                                                var index = root.selectedGroups.indexOf(modelData.name)
                                                if (index !== -1) root.selectedGroups.splice(index, 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CheckBox
                        {
                            text: "использовать типовые группы задач"
                            font.pixelSize: 13
                            checked: root.useDefaultGroups
                            onCheckedChanged:
                            {
                                root.useDefaultGroups = checked
                                if (!checked)
                                {
                                    root.selectedGroups = []
                                }
                                else
                                {
                                    root.selectedGroups = []
                                    for (var i = 0; i < groupsRepeater.model.length; i++)
                                    {
                                        root.selectedGroups.push(groupsRepeater.model[i].name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout
        {
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Button
            {
                text: "Отмена"
                Layout.preferredHeight: 38
                Layout.preferredWidth: 110
                font.pixelSize: 14
                onClicked: root.close()
            }

            Button
            {
                text: "Создать"
                Layout.preferredHeight: 38
                Layout.preferredWidth: 110
                font.pixelSize: 14
                onClicked: createProject()
            }
        }
    }

    property int calendarYear: startDate.getFullYear()
    property int calendarMonth: startDate.getMonth()
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

    Component.onCompleted:
    {
        updateCalendarModel()
        nameField.forceActiveFocus()
    }

    Labs.FileDialog
    {
        id: saveFileDialog
        title: "Выберите место сохранения"
        fileMode: Labs.FileDialog.SaveFile
        defaultSuffix: "gantt"
        nameFilters: ["Файлы графиков (*.gantt)", "Все файлы (*)"]
        onAccepted:
        {
            var localPath = file.toString()
            if (localPath.startsWith("file://")) localPath = localPath.substring(7)
            filePathField.text = localPath
            root.filePath = localPath
        }
    }
}
