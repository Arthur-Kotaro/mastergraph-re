import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root
    property alias milestoneBar: milestoneBar
    color: "#f8f8f8"
    width: parent?.width || 1000
    height: 240

    property date firstMilestoneDate: projectController?.projectData?.milestoneModel?.getFirstMilestoneDate() || new Date()
    property date lastMilestoneDate: projectController?.projectData?.milestoneModel?.getLastMilestoneDate() || new Date()

    property date displayStart: new Date()
    property date displayEnd: new Date()

    function getThirdSundayAfter(date)
    {
        var d = new Date(date)
        if (isNaN(d.getTime())) return new Date()
        while (d.getDay() !== 0) d.setDate(d.getDate() + 1)
        d.setDate(d.getDate() + 14)
        d.setHours(23, 59, 59, 999)
        return d
    }

    function updateDisplayRange()
    {
        var first = projectController?.projectData?.milestoneModel?.getFirstMilestoneDate()
        var last = projectController?.projectData?.milestoneModel?.getLastMilestoneDate()

        if (!first || !last) return

        var start = new Date(first)
        while (start.getDay() !== 1) start.setDate(start.getDate() - 1)
        start.setDate(start.getDate() - 28)
        start.setHours(0, 0, 0, 0)

        var end = getThirdSundayAfter(last)

        var startChanged = displayStart.toDateString() !== start.toDateString()
        var endChanged = displayEnd.toDateString() !== end.toDateString()

        if (startChanged) displayStart = start
        if (endChanged) displayEnd = end
    }

    property int dayWidth: 30
    property int totalDays: Math.max(1, Math.floor((displayEnd - displayStart) / 86400000) + 1)
    property real contentWidth: totalDays * dayWidth

    property int rowHeight: 40
    property var yearData: []
    property var monthData: []
    property var weekData: []
    property var dayNumbers: []

    signal calendarWidthChanged()

    onContentWidthChanged:
    {
        calendarWidthChanged()
    }

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
        target: projectController?.projectData?.milestoneModel
        enabled: target !== null
        function onMilestonesChanged() { refresh() }
        function onModelReset() { refresh() }
    }

    onDisplayStartChanged: rebuildData()
    onDisplayEndChanged: rebuildData()

    Column
    {
        spacing: 0

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
                        Text { text: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"][((displayStart.getDay() + index) % 7 + 6) % 7]; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 10; font.bold: true }
                        Text { text: root.dayNumbers[index] || ""; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 11 } } } } }
        }

        MilestoneBar
        {
            id: milestoneBar
            width: contentWidth; height: rowHeight; milestonesModel: projectController?.projectData?.milestoneModel
            startDate: displayStart; dayWidth: dayWidth
        }
    }
}
