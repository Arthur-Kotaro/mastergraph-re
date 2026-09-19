import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root
    property alias milestoneBar: milestoneBar
    color: "#f8f8f8"
    width: parent?.width || 1000
    height: 240

    property date firstMilestoneDate: new Date()
    property date lastMilestoneDate: new Date()

    property date displayStart: new Date()
    property date displayEnd: new Date()

    readonly property bool isLocalMode: {
        return projectController && projectController.projectData
               && projectController.projectData.graphKind === 1
    }

    function isValidDate(d)
    {
        return d !== undefined && d !== null && !isNaN(new Date(d).getTime())
    }

    function getSecondSundayAfter(date)
    {
        var d = new Date(date)
        if (isNaN(d.getTime())) return new Date()
        while (d.getDay() !== 0) d.setDate(d.getDate() + 1)
        d.setDate(d.getDate() + 14)
        d.setHours(23, 59, 59, 999)
        return d
    }

    function getMondayBefore(date, weeks)
    {
        var d = new Date(date)
        while (d.getDay() !== 1) d.setDate(d.getDate() - 1)
        d.setDate(d.getDate() - weeks * 7)
        d.setHours(0, 0, 0, 0)
        return d
    }

    function updateDisplayRange()
    {
        var localMode = (projectController && projectController.projectData
                         && projectController.projectData.graphKind === 1)

        if (localMode)
        {
            var linkedStart = projectController.projectData.getLinkedTargetStart()
            var linkedEnd = projectController.projectData.getLinkedTargetEnd()

            var s, e
            if (isValidDate(linkedStart) && isValidDate(linkedEnd))
            {
                s = new Date(linkedStart)
                s.setDate(s.getDate() - 14)
                s.setHours(0, 0, 0, 0)
                e = new Date(linkedEnd)
                e.setDate(e.getDate() + 14)
                e.setHours(23, 59, 59, 999)
            }
            else
            {
                var now = new Date()
                s = new Date(now.getFullYear(), now.getMonth() - 1, 1)
                e = new Date(now.getFullYear(), now.getMonth() + 2, 0)
                e.setHours(23, 59, 59, 999)
            }

            displayStart = s
            displayEnd = e
            return
        }

        var earliest = projectController?.projectData?.getEarliestDate()
        var latest = projectController?.projectData?.getLatestDate()
        if (!earliest || !latest) return
        var start = getMondayBefore(earliest, 4)
        var end = getSecondSundayAfter(latest)
        if (displayStart.toDateString() !== start.toDateString()) displayStart = start
        if (displayEnd.toDateString() !== end.toDateString()) displayEnd = end
    }

    property int dayWidth: projectController && projectController.settingsManager.zoomLevel === 1 ? 10 : 30
    onDayWidthChanged: { if (milestoneBar) milestoneBar.dayWidth = dayWidth }
    property int totalDays: Math.max(1, Math.floor((displayEnd - displayStart) / 86400000) + 1)
    property real contentWidth: totalDays * dayWidth

    property int rowHeight: 40
    property var yearData: []
    property var monthData: []
    property var weekData: []
    property var dayNumbers: []

    signal calendarWidthChanged()

    onContentWidthChanged: calendarWidthChanged()

    function rebuildData()
    {
        if (totalDays <= 0) return

        var years = [], months = [], weeks = [], dayNums = []
        var currentDate = new Date(displayStart)
        for (var i = 0; i < totalDays; i++)
        {
            dayNums.push(currentDate.getDate())
            currentDate.setDate(currentDate.getDate() + 1)
        }

        currentDate = new Date(displayStart)
        var currentYear = currentDate.getFullYear()
        var yearStartIdx = 0, yearDays = 0
        var currentMonth = currentDate.getMonth()
        var monthStartIdx = 0, monthDays = 0

        for (var j = 0; j < totalDays; j++)
        {
            var year = currentDate.getFullYear()
            var month = currentDate.getMonth()

            if (year !== currentYear)
            {
                years.push({year: currentYear, startIdx: yearStartIdx, days: yearDays})
                currentYear = year; yearStartIdx = j; yearDays = 0
            }
            if (month !== currentMonth)
            {
                months.push({name: ["Янв","Фев","Мар","Апр","Май","Июн","Июл","Авг","Сен","Окт","Ноя","Дек"][currentMonth],
                            startIdx: monthStartIdx, days: monthDays})
                currentMonth = month; monthStartIdx = j; monthDays = 0
            }
            yearDays++; monthDays++
            currentDate.setDate(currentDate.getDate() + 1)
        }
        years.push({year: currentYear, startIdx: yearStartIdx, days: yearDays})
        months.push({name: ["Янв","Фев","Мар","Апр","Май","Июн","Июл","Авг","Сен","Окт","Ноя","Дек"][currentMonth],
                    startIdx: monthStartIdx, days: monthDays})

        var weekStart = new Date(displayStart)
        for (var w = 0; w < Math.ceil(totalDays / 7); w++)
        {
            var firstThu = new Date(weekStart)
            firstThu.setDate(firstThu.getDate() + 3 - ((firstThu.getDay() + 6) % 7))
            var firstJan = new Date(firstThu.getFullYear(), 0, 4)
            var wn = 1 + Math.round(((firstThu - firstJan) / 86400000 - 3 + ((firstJan.getDay() + 6) % 7)) / 7)
            weeks.push({num: wn, startIdx: w * 7})
            weekStart.setDate(weekStart.getDate() + 7)
        }

        yearData = years; monthData = months; weekData = weeks; dayNumbers = dayNums
    }

    function refresh()
    {
        updateDisplayRange()
        rebuildData()
    }

    Component.onCompleted: refresh()

    Connections
    {
        target: projectController
        function onProjectDataChanged() { refresh() }
        function onProjectLoaded() { refresh() }
    }

    Connections
    {
        target: projectController?.projectData
        function onGraphKindChanged() { refresh() }
        function onDataCleared() { refresh() }
    }

    Connections
    {
        target: projectController?.projectData?.milestoneModel
        enabled: target !== null
        function onMilestonesChanged() { refresh() }
        function onModelReset() { refresh() }
    }

    Connections
    {
        target: projectController?.projectData?.taskModel
        enabled: target !== null
        function onRowsInserted() { refresh() }
        function onRowsRemoved() { refresh() }
        function onDataChanged() { refresh() }
    }

    onDisplayStartChanged: rebuildData()
    onDisplayEndChanged: rebuildData()

    Column
    {
        spacing: 0

        Rectangle
        {
            width: contentWidth; height: rowHeight; color: "#e0e0e0"; border.color: "#888888"; border.width: 1
            Row { Repeater { model: yearData
                Rectangle { x: modelData.startIdx * dayWidth; width: modelData.days * dayWidth; height: rowHeight; border.color: "#aaaaaa"; border.width: 1; color: "transparent"
                    Text { text: modelData.year; anchors.centerIn: parent; font.bold: true; font.pixelSize: 14 } } } }
        }

        Rectangle
        {
            width: contentWidth; height: rowHeight; color: "#e8e8e8"; border.color: "#888888"; border.width: 1
            Row { Repeater { model: monthData
                Rectangle { x: modelData.startIdx * dayWidth; width: modelData.days * dayWidth; height: rowHeight; border.color: "#aaaaaa"; border.width: 1; color: "transparent"
                    Text { text: modelData.name; anchors.centerIn: parent; font.pixelSize: 12 } } } }
        }

        Rectangle
        {
            width: contentWidth; height: rowHeight; color: "#f0f0f0"; border.color: "#aaaaaa"; border.width: 1
            Row { Repeater { model: weekData
                Rectangle { x: modelData.startIdx * dayWidth; width: 7 * dayWidth; height: rowHeight; border.color: "#aaaaaa"; border.width: 1; color: "transparent"
                    Text { text: "КН" + modelData.num; anchors.centerIn: parent; font.pixelSize: 10 } } } }
        }

        Rectangle
        {
            width: contentWidth; height: rowHeight; color: "#f8f8f8"; border.color: "#aaaaaa"; border.width: 1
            Row { Repeater { model: totalDays
                Rectangle { x: index * dayWidth; width: dayWidth; height: rowHeight; border.color: "#aaaaaa"; border.width: 1;
                    color: { var dow = ((displayStart.getDay() + index) % 7 + 6) % 7; return (dow === 5 || dow === 6) ? "#ffe0e0" : (index % 2 === 0 ? "#ffffff" : "#f8f8f8") }
                    Column { anchors.centerIn: parent; spacing: 2
                        visible: root.dayWidth >= 15
                        Text { text: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"][((displayStart.getDay() + index) % 7 + 6) % 7]; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 10; font.bold: true }
                        Text { text: root.dayNumbers[index] || ""; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 11 } } } } }
        }

        MilestoneBar
        {
            id: milestoneBar
            visible: !root.isLocalMode
            width: contentWidth; height: rowHeight
            milestonesModel: projectController?.projectData?.milestoneModel
            startDate: displayStart; dayWidth: dayWidth
        }

        Rectangle
        {
            width: contentWidth
            height: rowHeight
            color: "#f5f5f5"
            border.color: "#dddddd"
            border.width: 1
            Row
            {
                anchors.fill: parent
                anchors.leftMargin: 10
                spacing: 20
                Text
                {
                    text: "Создан: " + (projectController?.projectData?.creationDateTime?.toLocaleString() || "не указано")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 11
                }
                Text
                {
                    text: "Изменён: " + (projectController?.projectData?.lastModifiedDateTime?.toLocaleString() || "не указано")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 11
                }
            }
        }
    }
}
