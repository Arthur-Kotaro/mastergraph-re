import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root
    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel)
        {
            if (wheel.modifiers & Qt.ControlModifier)
            {
                if (wheel.angleDelta.y > 0) projectController.settingsManager.setZoomLevel(0)
                else projectController.settingsManager.setZoomLevel(1)
                wheel.accepted = true
            }
        }
    }
    color: "white"

    property int rowHeight: 40
    property var externalFlickable: null
    property bool showDependencies: true
    property bool showComments: true
    property bool showTaskHistory: true
    onShowDependenciesChanged: gridCanvas.requestPaint()
    property date displayStart: new Date()
    property date displayEnd: new Date()
    property int dayWidth: projectController && projectController.settingsManager.zoomLevel === 1 ? 10 : 30
    onDayWidthChanged: { updateData(); gridCanvas.requestPaint() }
    property int totalDays: 1
    property real gridWidth: totalDays * dayWidth
    property int totalRows: 1
    property real contentHeight: 0

    property var visibleItems: []
    property int updateCounter: 0

    Component.onCompleted: updateData()

    CurrentTimeLine
    {
        id: currentTimeLine
        displayStart: root.displayStart
        dayWidth: root.dayWidth
    }

    Connections
    {
        target: projectController?.settingsManager
        function onViewModeChanged() { updateData() }
    }

    function currentViewMode()
    {
        return projectController && projectController.settingsManager
               ? projectController.settingsManager.viewMode : 0
    }

    function updateData()
    {
        if (!projectController || !projectController.projectData) return

        var earliest = projectController && projectController.projectData ? projectController.projectData.getEarliestDate() : new Date()
        var latest = projectController && projectController.projectData ? projectController.projectData.getLatestDate() : new Date()

        if (earliest && latest)
        {
            var start = new Date(earliest)
            while (start.getDay() !== 1) start.setDate(start.getDate() - 1)
            start.setDate(start.getDate() - 28)
            start.setHours(0, 0, 0, 0)
            displayStart = start

            var end = new Date(latest)
            while (end.getDay() !== 0) end.setDate(end.getDate() + 1)
            end.setDate(end.getDate() + 14)
            end.setHours(23, 59, 59, 999)
            displayEnd = end

            totalDays = Math.max(1, Math.floor((end - start) / 86400000) + 1)
            gridWidth = totalDays * dayWidth
        }

        var mode = currentViewMode()
        var items = []
        var groups = projectController.projectData.groupModel
        var taskCounter = 0

        if (groups)
        {
            for (var i = 0; i < groups.rowCount(); i++)
            {
                var groupId = groups.getGroupId(i)
                var groupName = groups.getGroupName(i)
                var expanded = groups.isExpanded(i)

                items.push({type: "group", id: groupId, name: groupName})

                if (expanded)
                {
                    var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
                    for (var j = 0; j < tasks.length; j++)
                    {
                        var taskData = projectController.projectData.taskModel.getTask(tasks[j])
                        if (!taskData) continue

                        var isCompleted = (taskData.status === 1)

                        function pushRow(kind, startDate, endDate)
                        {
                            items.push({
                                type: "task",
                                rowKind: kind,
                                taskId: tasks[j],
                                rowIndex: taskCounter,
                                taskTitle: taskData.title,
                                taskResponsible: taskData.responsible,
                                taskStart: startDate,
                                taskEnd: endDate,
                                taskStatus: taskData.status,
                                taskComment: taskData.comment,
                                isCompleted: isCompleted
                            })
                            taskCounter++
                        }

                        if (mode === 0)
                        {
                            pushRow("target", taskData.startDate, taskData.endDate)
                        }
                        else if (mode === 1)
                        {
                            if (isCompleted)
                                pushRow("target", taskData.startDate, taskData.endDate)
                            else
                                pushRow("forecast", taskData.forecastStart, taskData.forecastEnd)
                        }
                        else
                        {
                            pushRow("target", taskData.startDate, taskData.endDate)
                            if (!isCompleted)
                                pushRow("forecast", taskData.forecastStart, taskData.forecastEnd)
                        }
                    }
                }
            }
        }

        if (root.showTaskHistory)
        {
            visibleItems = items
            updateCounter++
            totalRows = visibleItems.length
            contentHeight = totalRows * rowHeight

            root.width = gridWidth
            root.height = contentHeight

            groupsRepeater.model = visibleItems
            gridCanvas.requestPaint()
            if (currentTimeLine) currentTimeLine.updateLinePosition()
        }
    }

    function updateTaskDates(taskId, newStart, newEnd)
    {
        if (projectController)
        {
            projectController.updateTaskDates(taskId, newStart, newEnd)
        }
    }

    function updateForecastDates(taskId, newStart, newEnd)
    {
        if (projectController)
        {
            projectController.updateForecastDates(taskId, newStart, newEnd)
        }
    }

    Connections
    {
        target: projectController?.projectData?.taskModel
        function onDataChanged() { updateData() }
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.groupModel
        function onDataChanged() { updateData() }
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
        function onCountChanged() { updateData() }
        function onModelReset() { updateData() }
        function onGroupExpandedChanged() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.milestoneModel
        function onMilestonesChanged() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.dependencyModel
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
    }

    width: gridWidth
    height: contentHeight

    // Возвращает { targetRow, forecastRow } — индексы строк в visibleItems
    function getRowIndicesForTask(taskId)
    {
        var result = { targetRow: -1, forecastRow: -1 }
        for (var i = 0; i < visibleItems.length; i++)
        {
            var it = visibleItems[i]
            if (it.type !== "task" || it.taskId !== taskId) continue
            if (it.rowKind === "target") result.targetRow = i
            else if (it.rowKind === "forecast") result.forecastRow = i
        }
        return result
    }

    function drawDependencyLine(ctx, fromRow, toRow)
    {
        if (fromRow < 0 || toRow < 0) return
        var fromData = visibleItems[fromRow]
        var toData = visibleItems[toRow]

        var fromEnd = new Date(fromData.taskEnd)
        var fromDays = Math.floor((fromEnd - displayStart) / 86400000)
        var fromX = fromDays * dayWidth + dayWidth

        var fromY = fromRow * rowHeight + rowHeight / 2
        var toY = toRow * rowHeight + rowHeight / 2
        var toStart = new Date(toData.taskStart)
        var toDays = Math.floor((toStart - displayStart) / 86400000)
        var toX = toDays * dayWidth

        ctx.beginPath()
        ctx.strokeStyle = "#9966cc"
        ctx.lineWidth = 2
        ctx.moveTo(fromX, fromY)
        ctx.lineTo(fromX + 10, fromY)
        ctx.lineTo(toX - 10, toY)
        ctx.lineTo(toX, toY)
        ctx.stroke()
    }

    Canvas
    {
        id: gridCanvas
        anchors.fill: parent
        z: 0

        onPaint:
        {
            if (totalDays <= 0 || width <= 0 || height <= 0) return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            for (var d = 0; d < totalDays; d++)
            {
                var checkDate = new Date(displayStart)
                checkDate.setDate(checkDate.getDate() + d)
                var dow = (checkDate.getDay() + 6) % 7
                if (dow === 5 || dow === 6)
                {
                    ctx.fillStyle = "#ffe0e0"
                    ctx.fillRect(d * dayWidth, 0, dayWidth, height)
                }
            }

            ctx.beginPath()
            ctx.setLineDash([2, 4])
            ctx.strokeStyle = "#cccccc"
            ctx.lineWidth = 1
            for (var dd = 1; dd < totalDays; dd++)
            {
                var xd = dd * dayWidth
                if (xd < width)
                {
                    ctx.moveTo(xd, 0)
                    ctx.lineTo(xd, height)
                }
            }
            ctx.stroke()

            ctx.beginPath()
            ctx.setLineDash([])
            ctx.strokeStyle = "#aaaaaa"
            for (var w = 1; w < totalDays / 7; w++)
            {
                var xw = w * dayWidth * 7
                if (xw < width)
                {
                    ctx.moveTo(xw, 0)
                    ctx.lineTo(xw, height)
                }
            }
            ctx.stroke()

            ctx.beginPath()
            ctx.lineWidth = 2
            ctx.strokeStyle = "#888888"
            var currentDate = new Date(displayStart)
            var xm = 0
            while (currentDate <= displayEnd)
            {
                var nextMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                var daysInMonth = Math.ceil((nextMonth - currentDate) / 86400000)
                xm += daysInMonth * dayWidth
                if (xm < width && xm > 0)
                {
                    ctx.moveTo(xm, 0)
                    ctx.lineTo(xm, height)
                }
                currentDate = nextMonth
            }
            ctx.stroke()

            ctx.beginPath()
            ctx.lineWidth = 1
            ctx.strokeStyle = "#dddddd"
            for (var r = 1; r < totalRows; r++)
            {
                var y = r * rowHeight
                if (y < height)
                {
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                }
            }
            ctx.stroke()

            if (showDependencies)
            {
                if (projectController && projectController.projectData && projectController.projectData.dependencyModel)
                {
                    var mode = root.currentViewMode()
                    var depModel = projectController.projectData.dependencyModel

                    for (var di = 0; di < depModel.rowCount(); di++)
                    {
                        var idx = depModel.index(di, 0)
                        var predId = depModel.data(idx, Qt.UserRole + 2)
                        var succId = depModel.data(idx, Qt.UserRole + 3)
                        if (!predId || !succId) continue

                        var predTask = projectController.projectData.taskModel.getTask(predId)
                        var succTask = projectController.projectData.taskModel.getTask(succId)
                        if (!predTask || !succTask) continue

                        var predCompleted = (predTask.status === 1)
                        var succCompleted = (succTask.status === 1)

                        var predRows = root.getRowIndicesForTask(predId)
                        var succRows = root.getRowIndicesForTask(succId)

                        if (mode === 0)
                        {
                            // Только целевые
                            root.drawDependencyLine(ctx, predRows.targetRow, succRows.targetRow)
                        }
                        else if (mode === 1)
                        {
                            // Одна строка на задачу: завершённые — target, незавершённые — forecast
                            var predSrc = predCompleted ? predRows.targetRow : predRows.forecastRow
                            var succDst = succCompleted ? succRows.targetRow : succRows.forecastRow
                            if (predSrc < 0) predSrc = predRows.targetRow
                            if (succDst < 0) succDst = succRows.targetRow
                            root.drawDependencyLine(ctx, predSrc, succDst)
                        }
                        else // mode === 2, Combined
                        {
                            // target-линия — всегда
                            root.drawDependencyLine(ctx, predRows.targetRow, succRows.targetRow)

                            // forecast-линия — только если у последователя есть forecast-строка
                            if (succRows.forecastRow >= 0)
                            {
                                var predForecastSrc = predCompleted ? predRows.targetRow : predRows.forecastRow
                                if (predForecastSrc >= 0)
                                    root.drawDependencyLine(ctx, predForecastSrc, succRows.forecastRow)
                            }
                        }
                    }
                }
            }

            ctx.beginPath()
            ctx.lineWidth = 2
            ctx.strokeStyle = "#888888"
            var groupRows = []
            for (var vi = 0; vi < visibleItems.length; vi++)
            {
                if (visibleItems[vi].type === "group")
                {
                    groupRows.push(vi)
                }
            }
            for (var gi = 0; gi < groupRows.length; gi++)
            {
                var gy = groupRows[gi] * rowHeight
                if (gy < height && gy > 0)
                {
                    ctx.moveTo(0, gy)
                    ctx.lineTo(width, gy)
                }
            }
            ctx.stroke()

            ctx.beginPath()
            ctx.lineWidth = 3
            ctx.strokeStyle = "#666666"
            var lastY = totalRows * rowHeight
            if (lastY <= height && lastY > 0)
            {
                ctx.moveTo(0, lastY)
                ctx.lineTo(width, lastY)
            }
            ctx.stroke()
        }
    }

    Repeater
    {
        id: groupsRepeater
        model: visibleItems

        delegate: Rectangle
        {
            id: rowContainer
            y: index * rowHeight
            width: parent.width
            height: rowHeight
            color: "transparent"

            Text
            {
                visible: modelData && modelData.type === "group"
                text: modelData ? (modelData.name || "") : ""
                x:
                {
                    if (currentTimeLine && currentTimeLine.visible)
                    {
                        return currentTimeLine.x + 10
                    }
                    return 10
                }
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                font.pixelSize: 14
                z: 3
            }

            Rectangle
            {
                id: ganttBar
                visible: modelData && modelData.type === "task"

                x:
                {
                    if (!modelData || !modelData.taskStart || !root.displayStart) return 0
                    var daysDiff = Math.floor((modelData.taskStart - root.displayStart) / (1000 * 60 * 60 * 24))
                    return Math.max(0, daysDiff * root.dayWidth)
                }

                width:
                {
                    if (!modelData || !modelData.taskStart || !modelData.taskEnd) return 10
                    var daysDiff = Math.floor((modelData.taskEnd - modelData.taskStart) / (1000 * 60 * 60 * 24)) + 1
                    return Math.max(10, daysDiff * root.dayWidth)
                }

                height: parent.height - 8
                y: 4

                function getStatusColor()
                {
                    if (!modelData) return "#FFD700"
                    switch (modelData.taskStatus)
                    {
                        case 0: return "#FFD700"
                        case 1: return "#32CD32"
                        case 2: return "#FF8C00"
                        case 3: return "#FF4444"
                        default: return "#FFD700"
                    }
                }

                function getBarColor()
                {
                    if (modelData && modelData.rowKind === "forecast")
                        return Qt.lighter(getStatusColor(), 1.2)
                    return getStatusColor()
                }

                function getBarOpacity()
                {
                    if (modelData && modelData.rowKind === "forecast")
                        return 0.6
                    return 1.0
                }

                color: getBarColor()
                opacity: getBarOpacity()
                radius: 4
                border.color: Qt.darker(color, 1.2)
                border.width: 1

                function updateDates()
                {
                    var newStartDays = Math.round(x / root.dayWidth)
                    var newStart = new Date(root.displayStart)
                    newStart.setDate(newStart.getDate() + newStartDays)

                    var newEndDays = Math.round((x + width) / root.dayWidth)
                    var newEnd = new Date(root.displayStart)
                    newEnd.setDate(newEnd.getDate() + newEndDays - 1)

                    if (newStart < newEnd)
                    {
                        if (modelData && modelData.rowKind === "forecast")
                            root.updateForecastDates(modelData.taskId, newStart, newEnd)
                        else
                            root.updateTaskDates(modelData.taskId, newStart, newEnd)
                    }
                }

                ToolTip
                {
                    visible: moveArea.containsMouse
                    text:
                    {
                        if (!modelData) return ""
                        var label = (modelData.rowKind === "forecast") ? "Прогноз: " : ""
                        var duration = Math.floor((modelData.taskEnd - modelData.taskStart) / (24 * 60 * 60 * 1000)) + 1
                        var commentText = (modelData.taskComment && modelData.taskComment !== "") ? modelData.taskComment : "-"
                        return label + modelData.taskTitle +
                               "\nДлительность: " + duration + " дней" +
                               "\nОтветственный: " + modelData.taskResponsible +
                               "\nКомментарий: " + commentText
                    }
                    delay: 500
                }

                MouseArea
                {
                    id: moveArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: rowContainer.width - parent.width
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed: function(mouse)
                    {
                        if (projectController && projectController.settingsManager.editingLocked)
                        {
                            drag.target = null
                            return
                        }
                        drag.target = parent

                        if (modelData && modelData.isCompleted)
                        {
                            mouse.accepted = false
                            return
                        }

                        if (root.externalFlickable) root.externalFlickable.interactive = false

                        if (mouse.button === Qt.RightButton)
                        {
                            taskContextMenu.taskId = modelData.taskId
                            taskContextMenu.popup()
                        }
                    }

                    onPositionChanged:
                    {
                        if (projectController && projectController.settingsManager.editingLocked)
                        {
                            drag.target = null
                            return
                        }
                        drag.target = parent
                        if (drag.active)
                        {
                            parent.x = Math.round(parent.x / root.dayWidth) * root.dayWidth
                        }
                    }

                    onReleased:
                    {
                        if (root.externalFlickable) root.externalFlickable.interactive = true
                        if (drag.active)
                        {
                            parent.updateDates()
                        }
                    }
                }

                Rectangle
                {
                    width: 10
                    height: parent.height
                    anchors.right: parent.right
                    color: Qt.darker(parent.color, 1.5)
                    radius: 2
                    visible: moveArea.containsMouse
                    enabled: !(modelData && modelData.isCompleted)

                    MouseArea
                    {
                        id: resizeArea
                        enabled: !(modelData && modelData.isCompleted)
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor

                        property real startWidth: 0
                        property real startMouseX: 0

                        onPressed:
                        {
                            if (projectController && projectController.settingsManager.editingLocked) return
                            if (modelData && modelData.isCompleted) return

                            if (root.externalFlickable) root.externalFlickable.interactive = false
                            startWidth = ganttBar.width
                            startMouseX = mapToItem(ganttBar, mouseX, 0).x
                        }

                        onPositionChanged:
                        {
                            if (projectController && projectController.settingsManager.editingLocked) return
                            if (modelData && modelData.isCompleted) return

                            if (pressed)
                            {
                                var currentX = mapToItem(ganttBar, mouseX, 0).x
                                var delta = currentX - startMouseX
                                var newWidth = startWidth + delta
                                newWidth = Math.max(10, Math.round(newWidth / root.dayWidth) * root.dayWidth)
                                if (newWidth !== ganttBar.width)
                                {
                                    ganttBar.width = newWidth
                                }
                            }
                        }

                        onReleased:
                        {
                            if (root.externalFlickable) root.externalFlickable.interactive = true
                            ganttBar.updateDates()
                        }
                    }
                }

                Text
                {
                    visible: root.showComments && (modelData && modelData.type === "task" && modelData.rowKind === "target")
                    text:
                    {
                        if (!modelData) return ""
                        var forceUpdate = root.updateCounter
                        return modelData.taskComment ? modelData.taskComment : ""
                    }
                    x: parent.width + 14
                    y: 4
                    font.pixelSize: 14
                    color: "#666666"
                    elide: Text.ElideRight
                    width: Math.min(350, rowContainer.width - ganttBar.x - ganttBar.width - 10)
                }
            }

            Repeater
            {
                model:
                {
                    if (modelData && modelData.type === "task" && modelData.rowKind === "target" && root.showTaskHistory)
                    {
                        var task = projectController?.projectData?.taskModel?.getTask(modelData.taskId)
                        return task && task.dateHistory ? task.dateHistory : []
                    }
                    return []
                }
                delegate: Rectangle
                {
                    x:
                    {
                        var ps = modelData.start.split(".")
                        if (ps.length === 3)
                        {
                            var d = new Date(parseInt(ps[2]), parseInt(ps[1]) - 1, parseInt(ps[0]))
                            return Math.max(0, Math.floor((d - root.displayStart) / 86400000) * root.dayWidth)
                        }
                        return 0
                    }
                    width:
                    {
                        var ps = modelData.start.split(".")
                        var pe = modelData.end.split(".")
                        if (ps.length === 3 && pe.length === 3)
                        {
                            var s = new Date(parseInt(ps[2]), parseInt(ps[1]) - 1, parseInt(ps[0]))
                            var e = new Date(parseInt(pe[2]), parseInt(pe[1]) - 1, parseInt(pe[0]))
                            return Math.max(10, (Math.floor((e - s) / 86400000) + 1) * root.dayWidth)
                        }
                        return 10
                    }
                    height: ganttBar.height
                    y: ganttBar.y
                    color: "#cccccc"
                    opacity: 0.7
                    radius: 4
                    z: ganttBar.z - 1
                }
            }
        }
    }

    TaskContextMenu
    {
        id: taskContextMenu
    }
}
