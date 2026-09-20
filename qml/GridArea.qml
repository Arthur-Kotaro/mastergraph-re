import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root

    color: "white"

    property int rowHeight: 40
    property var externalFlickable: null
    property bool showDependencies: true
    property bool showComments: true
    property bool showTaskHistory: true
    onShowDependenciesChanged: overlayCanvas.requestPaint()
    property date displayStart: new Date()
    property date displayEnd: new Date()
    property int dayWidth: projectController && projectController.settingsManager.zoomLevel === 1 ? 10 : 30
    onDayWidthChanged: { updateData(); backgroundCanvas.requestPaint(); overlayCanvas.requestPaint() }
    property int totalDays: 1
    property real gridWidth: totalDays * dayWidth
    property int totalRows: 1
    property real contentHeight: 0

    property var visibleItems: []
    property int updateCounter: 0

    property var nodeXByTaskTarget: ({})
    property var nodeXByTaskForecast: ({})

    readonly property bool isLocalMode: {
        return projectController && projectController.projectData
               && projectController.projectData.graphKind === 1
    }

    Component.onCompleted: updateData()

    CurrentTimeLine
    {
        id: currentTimeLine
        displayStart: root.displayStart
        dayWidth: root.dayWidth
    }

    Connections
    {
        target: projectController
        function onProjectDataChanged() { updateData() }
        function onProjectLoaded() { updateData() }
    }

    Connections
    {
        target: projectController?.settingsManager
        function onViewModeChanged() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData
        function onGraphKindChanged() { updateData() }
    }

    function currentViewMode()
    {
        if (isLocalMode) return 0
        return projectController && projectController.settingsManager
               ? projectController.settingsManager.viewMode : 0
    }

    function isValidDate(d)
    {
        return d !== undefined && d !== null && !isNaN(new Date(d).getTime())
    }

    function hasTaskDates(taskData)
    {
        return taskData && isValidDate(taskData.startDate) && isValidDate(taskData.endDate)
    }

    function hasTaskForecast(taskData)
    {
        return taskData && isValidDate(taskData.forecastStart) && isValidDate(taskData.forecastEnd)
    }

    function daysFromStart(dateValue)
    {
        return Math.floor((new Date(dateValue) - root.displayStart) / 86400000)
    }

    function computeNodePositions(allTasks)
    {
        var taskById = {}
        for (var i = 0; i < allTasks.length; i++)
            taskById[allTasks[i].id] = allTasks[i]

        var targetNodes = {}
        var forecastNodes = {}

        for (var k = 0; k < allTasks.length; k++)
        {
            var task = allTasks[k]
            if (hasTaskDates(task)) continue
            if (hasTaskForecast(task)) continue

            targetNodes[task.id] = computeNodeX(task.id, "target", taskById, targetNodes)
            forecastNodes[task.id] = computeNodeX(task.id, "forecast", taskById, forecastNodes)
        }

        root.nodeXByTaskTarget = targetNodes
        root.nodeXByTaskForecast = forecastNodes
    }

    function computeNodeX(taskId, kind, taskById, nodes)
    {
        if (nodes[taskId] !== undefined) return nodes[taskId]

        var preds = projectController.projectData.dependencyModel.getPredecessors(taskId)
        var maxPredEnd = null
        var maxPredNodeX = -1

        for (var i = 0; i < preds.length; i++)
        {
            var pid = preds[i]
            var predTask = taskById[pid]
            if (!predTask) continue

            var pEnd = null

            if (kind === "target")
            {
                if (hasTaskDates(predTask))
                    pEnd = new Date(predTask.endDate)
            }
            else // "forecast"
            {
                if (hasTaskForecast(predTask))
                    pEnd = new Date(predTask.forecastEnd)
                else if (hasTaskDates(predTask))
                    pEnd = new Date(predTask.endDate)
            }

            if (pEnd !== null)
            {
                if (maxPredEnd === null || pEnd > maxPredEnd)
                    maxPredEnd = pEnd
            }
            else
            {
                var pNodeX = computeNodeX(pid, kind, taskById, nodes)
                if (pNodeX > maxPredNodeX) maxPredNodeX = pNodeX
            }
        }

        var result
        if (maxPredEnd !== null)
            result = (daysFromStart(maxPredEnd) + 1) * dayWidth + dayWidth / 2
        else if (maxPredNodeX >= 0)
            result = maxPredNodeX + 3 * dayWidth
        else
            result = dayWidth / 2

        if (result < dayWidth / 2) result = dayWidth / 2
        nodes[taskId] = result
        return result
    }

    function updateData()
    {
        if (!projectController || !projectController.projectData) return

        var localMode = (projectController.projectData.graphKind === 1)

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
            totalDays = Math.max(1, Math.floor((e - s) / 86400000) + 1)
            gridWidth = totalDays * dayWidth
        }
        else
        {
            var earliest = projectController.projectData.getEarliestDate()
            var latest = projectController.projectData.getLatestDate()

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
        }

        var allTasks = []
        var ids = projectController.projectData.taskModel.getAllTasks()
        for (var ai = 0; ai < ids.length; ai++)
        {
            var t = projectController.projectData.taskModel.getTask(ids[ai].id)
            if (t) allTasks.push(t)
        }

        computeNodePositions(allTasks)

        var mode = currentViewMode()
        var items = []
        var taskCounter = 0

        if (localMode)
        {
            for (var li = 0; li < allTasks.length; li++)
            {
                var tdL = allTasks[li]
                var isCompletedL = (tdL.status === 1)
                var hasDatesL = hasTaskDates(tdL)
                var hasFcL = hasTaskForecast(tdL)
                var isUnapprovedL = !hasDatesL && hasFcL
                var nodeXL = 0
                if (!hasDatesL && !isUnapprovedL)
                    nodeXL = root.nodeXByTaskTarget[tdL.id] !== undefined
                             ? root.nodeXByTaskTarget[tdL.id] : dayWidth / 2

                items.push({
                    type: "task",
                    rowKind: "target",
                    taskId: tdL.id,
                    rowIndex: taskCounter,
                    taskTitle: tdL.title,
                    taskResponsible: tdL.responsible,
                    taskStart: tdL.startDate,
                    taskEnd: tdL.endDate,
                    forecastStart: tdL.forecastStart,
                    forecastEnd: tdL.forecastEnd,
                    taskStatus: tdL.status,
                    taskComment: tdL.comment,
                    isCompleted: isCompletedL,
                    hasDates: hasDatesL,
                    hasForecast: hasFcL,
                    isUnapproved: isUnapprovedL,
                    nodeX: nodeXL,
                    localGraphState: tdL.localGraphState
                })
                taskCounter++
            }
        }
        else
        {
            var groups = projectController.projectData.groupModel

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
                        var hasDates = hasTaskDates(taskData)
                        var hasFc = hasTaskForecast(taskData)
                        var isUnapproved = !hasDates && hasFc

                        function pushRow(kind, startDate, endDate, rowHasDates, rowIsUnapproved)
                        {
                            var nodeXVal = 0
                            if (!rowHasDates && !rowIsUnapproved)
                            {
                                if (kind === "target")
                                    nodeXVal = root.nodeXByTaskTarget[tasks[j]] !== undefined
                                               ? root.nodeXByTaskTarget[tasks[j]] : dayWidth / 2
                                else
                                    nodeXVal = root.nodeXByTaskForecast[tasks[j]] !== undefined
                                               ? root.nodeXByTaskForecast[tasks[j]] : dayWidth / 2
                            }

                            items.push({
                                type: "task",
                                rowKind: kind,
                                taskId: tasks[j],
                                rowIndex: taskCounter,
                                taskTitle: taskData.title,
                                taskResponsible: taskData.responsible,
                                taskStart: startDate,
                                taskEnd: endDate,
                                forecastStart: taskData.forecastStart,
                                forecastEnd: taskData.forecastEnd,
                                taskStatus: taskData.status,
                                taskComment: taskData.comment,
                                isCompleted: isCompleted,
                                hasDates: rowHasDates,
                                hasForecast: hasFc,
                                isUnapproved: rowIsUnapproved,
                                nodeX: nodeXVal,
                                localGraphState: taskData.localGraphState
                            })
                            taskCounter++
                        }

                        if (mode === 0)
                        {
                            pushRow("target", taskData.startDate, taskData.endDate, hasDates, isUnapproved)
                        }
                        else if (mode === 1)
                        {
                            if (isCompleted || !hasFc)
                                pushRow("target", taskData.startDate, taskData.endDate, hasDates, isUnapproved)
                            else
                            {
                                var fHasDates1 = isValidDate(taskData.forecastStart) && isValidDate(taskData.forecastEnd)
                                pushRow("forecast", taskData.forecastStart, taskData.forecastEnd, fHasDates1, isUnapproved)
                            }
                        }
                        else
                        {
                            pushRow("target", taskData.startDate, taskData.endDate, hasDates, isUnapproved)
                            if (!isCompleted)
                            {
                                var fHasDates2 = isValidDate(taskData.forecastStart) && isValidDate(taskData.forecastEnd)
                                pushRow("forecast", taskData.forecastStart, taskData.forecastEnd, fHasDates2, isUnapproved)
                            }
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
            var minH = root.externalFlickable ? root.externalFlickable.height : (rowHeight * 5)
            contentHeight = Math.max(minH, totalRows * rowHeight)

            root.width = gridWidth
            root.height = contentHeight

            groupsRepeater.model = visibleItems
            backgroundCanvas.requestPaint()
            overlayCanvas.requestPaint()
            if (currentTimeLine) currentTimeLine.updateLinePosition()
        }
    }

    function updateTaskDates(taskId, newStart, newEnd)
    {
        if (projectController)
            projectController.updateTaskDates(taskId, newStart, newEnd)
    }

    function updateForecastDates(taskId, newStart, newEnd)
    {
        if (projectController)
            projectController.updateForecastDates(taskId, newStart, newEnd)
    }

    Connections
    {
        target: projectController?.projectData?.taskModel
        function onDataChanged() { updateData() }
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
        function onModelReset() { updateData() }
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
        function onModelReset() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.dependencyModel
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
        function onModelReset() { updateData() }
    }

    width: gridWidth
    height: contentHeight

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

    function getDependencyAnchorX(rowIndex, isOutgoing)
    {
        if (rowIndex < 0 || rowIndex >= visibleItems.length) return -1
        var item = visibleItems[rowIndex]
        if (!item) return -1

        if (item.hasDates)
        {
            if (isOutgoing)
            {
                var endDays = Math.floor((new Date(item.taskEnd) - displayStart) / 86400000)
                return endDays * dayWidth + dayWidth
            }
            else
            {
                var startDays = Math.floor((new Date(item.taskStart) - displayStart) / 86400000)
                return startDays * dayWidth
            }
        }
        else if (item.isUnapproved)
        {
            if (isOutgoing)
            {
                var feDays = Math.floor((new Date(item.forecastEnd) - displayStart) / 86400000)
                return feDays * dayWidth + dayWidth
            }
            else
            {
                var fsDays = Math.floor((new Date(item.forecastStart) - displayStart) / 86400000)
                return fsDays * dayWidth
            }
        }
        else
        {
            var nodeCenter = item.nodeX
            return isOutgoing ? nodeCenter + 15 : nodeCenter - 15
        }
    }

    function drawDependencyLine(ctx, fromRow, toRow)
    {
        if (fromRow < 0 || toRow < 0) return

        var fromX = getDependencyAnchorX(fromRow, true)
        var toX = getDependencyAnchorX(toRow, false)
        if (fromX < 0 || toX < 0) return

        var fromY = fromRow * rowHeight + rowHeight / 2
        var toY = toRow * rowHeight + rowHeight / 2

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
        id: backgroundCanvas
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

            ctx.beginPath()
            ctx.lineWidth = 2
            ctx.strokeStyle = "#888888"
            var groupRows = []
            for (var vi = 0; vi < visibleItems.length; vi++)
            {
                if (visibleItems[vi].type === "group")
                    groupRows.push(vi)
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

    Canvas
    {
        id: overlayCanvas
        anchors.fill: parent
        z: 5

        onPaint:
        {
            if (totalDays <= 0 || width <= 0 || height <= 0) return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (!showDependencies) return
            if (!projectController || !projectController.projectData || !projectController.projectData.dependencyModel)
                return

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
                    root.drawDependencyLine(ctx, predRows.targetRow, succRows.targetRow)
                }
                else if (mode === 1)
                {
                    var predSrc = predCompleted ? predRows.targetRow : predRows.forecastRow
                    var succDst = succCompleted ? succRows.targetRow : succRows.forecastRow
                    if (predSrc < 0) predSrc = predRows.targetRow
                    if (succDst < 0) succDst = succRows.targetRow
                    root.drawDependencyLine(ctx, predSrc, succDst)
                }
                else
                {
                    root.drawDependencyLine(ctx, predRows.targetRow, succRows.targetRow)

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

            function isForecastLocked()
            {
                if (!modelData) return false
                if (modelData.rowKind !== "forecast") return false
                var lgs = modelData.localGraphState !== undefined ? modelData.localGraphState : 0
                return (lgs === 2 || lgs === 3)
            }

            Text
            {
                visible: modelData && modelData.type === "group"
                text: modelData ? (modelData.name || "") : ""
                x:
                {
                    if (currentTimeLine && currentTimeLine.visible)
                        return currentTimeLine.x + 10
                    return 10
                }
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                font.pixelSize: 14
                z: 3
            }

            Rectangle
            {
                id: nodeCircle
                visible: modelData && modelData.type === "task" && !modelData.hasDates && !modelData.isUnapproved
                x: modelData ? (modelData.nodeX - 15) : 0
                y: rowContainer.height / 2 - 15
                width: 30
                height: 30
                radius: 15
                color:
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
                z: 4

                MouseArea
                {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    hoverEnabled: true
                    onClicked: function(mouse)
                    {
                        if (mouse.button === Qt.RightButton && modelData)
                        {
                            taskContextMenu.taskId = modelData.taskId
                            taskContextMenu.popup()
                        }
                    }
                }
            }

            Rectangle
            {
                id: ganttBar
                visible: modelData && modelData.type === "task" && (modelData.hasDates || modelData.isUnapproved)

                x:
                {
                    if (!modelData) return 0
                    var startVal = modelData.hasDates ? modelData.taskStart : modelData.forecastStart
                    if (!startVal || !root.displayStart) return 0
                    var daysDiff = Math.floor((new Date(startVal) - root.displayStart) / 86400000)
                    return Math.max(0, daysDiff * root.dayWidth)
                }

                width:
                {
                    if (!modelData) return 10
                    var sVal = modelData.hasDates ? modelData.taskStart : modelData.forecastStart
                    var eVal = modelData.hasDates ? modelData.taskEnd : modelData.forecastEnd
                    if (!sVal || !eVal) return 10
                    var daysDiff = Math.floor((new Date(eVal) - new Date(sVal)) / 86400000) + 1
                    return Math.max(10, daysDiff * root.dayWidth)
                }

                height: parent.height - 8
                y: 4
                clip: true

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

                Canvas
                {
                    id: stripesCanvas
                    anchors.fill: parent
                    visible: modelData && modelData.isUnapproved

                    onPaint:
                    {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (!modelData || !modelData.isUnapproved) return
                        if (width <= 0 || height <= 0) return

                        var stripeWidth = 12
                        var gap = 12
                        var step = stripeWidth + gap

                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = stripeWidth
                        ctx.beginPath()

                        var diagonal = height
                        for (var i = -diagonal; i < width + diagonal; i += step)
                        {
                            ctx.moveTo(i, height)
                            ctx.lineTo(i + diagonal, 0)
                        }
                        ctx.stroke()
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                }

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
                        var duration = Math.floor((new Date(modelData.taskEnd) - new Date(modelData.taskStart)) / (24 * 60 * 60 * 1000)) + 1
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
                        if (mouse.button === Qt.RightButton)
                        {
                            taskContextMenu.taskId = modelData.taskId
                            taskContextMenu.popup()
                            return
                        }

                        if (rowContainer.isForecastLocked())
                        {
                            drag.target = null
                            return
                        }

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
                    }

                    onPositionChanged:
                    {
                        if (rowContainer.isForecastLocked())
                        {
                            drag.target = null
                            return
                        }
                        if (projectController && projectController.settingsManager.editingLocked)
                        {
                            drag.target = null
                            return
                        }
                        drag.target = parent
                        if (drag.active)
                            parent.x = Math.round(parent.x / root.dayWidth) * root.dayWidth
                    }

                    onReleased:
                    {
                        if (root.externalFlickable) root.externalFlickable.interactive = true
                        if (drag.active)
                            parent.updateDates()
                    }
                }

                Rectangle
                {
                    width: 10
                    height: parent.height
                    anchors.right: parent.right
                    color: Qt.darker(parent.color, 1.5)
                    radius: 2
                    visible: moveArea.containsMouse && !rowContainer.isForecastLocked()
                    enabled: !(modelData && modelData.isCompleted) && !rowContainer.isForecastLocked()

                    MouseArea
                    {
                        id: resizeArea
                        enabled: !(modelData && modelData.isCompleted) && !rowContainer.isForecastLocked()
                        anchors.fill: parent
                        cursorShape: rowContainer.isForecastLocked() ? Qt.ArrowCursor : Qt.SizeHorCursor

                        property real startWidth: 0
                        property real startMouseX: 0

                        onPressed:
                        {
                            if (rowContainer.isForecastLocked()) return
                            if (projectController && projectController.settingsManager.editingLocked) return
                            if (modelData && modelData.isCompleted) return

                            if (root.externalFlickable) root.externalFlickable.interactive = false
                            startWidth = ganttBar.width
                            startMouseX = mapToItem(ganttBar, mouseX, 0).x
                        }

                        onPositionChanged:
                        {
                            if (rowContainer.isForecastLocked()) return
                            if (projectController && projectController.settingsManager.editingLocked) return
                            if (modelData && modelData.isCompleted) return

                            if (pressed)
                            {
                                var currentX = mapToItem(ganttBar, mouseX, 0).x
                                var delta = currentX - startMouseX
                                var newWidth = startWidth + delta
                                newWidth = Math.max(10, Math.round(newWidth / root.dayWidth) * root.dayWidth)
                                if (newWidth !== ganttBar.width)
                                    ganttBar.width = newWidth
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
                    visible: root.showComments && (modelData && modelData.type === "task")
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
                    if (modelData && modelData.type === "task" && modelData.rowKind === "target"
                        && modelData.hasDates && root.showTaskHistory)
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
                    z: -1
                }
            }
        }
    }

    TaskContextMenu
    {
        id: taskContextMenu
    }
}
