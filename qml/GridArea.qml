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
    property bool showProgress: true
    property date displayStart: new Date()
    property date displayEnd: new Date()
    property int dayWidth: projectController && projectController.settingsManager.zoomLevel === 1 ? 10 : 30
    property int totalDays: 1
    property real gridWidth: totalDays * dayWidth
    property int totalRows: 1
    property real contentHeight: 0
    property var visibleItems: []
    property int updateCounter: 0
    property var nodeXByTaskTarget: ({})
    property var nodeXByTaskForecast: ({})

    onShowDependenciesChanged: dependencyCanvas.refresh()
    onDayWidthChanged:
    {
        updateData()
        backgroundCanvas.refresh()
        dependencyCanvas.refresh()
    }

    readonly property bool isLocalMode:
    {
        return projectController && projectController.projectData && projectController.projectData.graphKind === 1
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
        target: projectController?.settingsManager ?? null
        function onViewModeChanged() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData ?? null
        function onGraphKindChanged() { updateData() }
    }

    function currentViewMode()
    {
        if (isLocalMode) return 0
        return projectController && projectController.settingsManager ? projectController.settingsManager.viewMode : 0
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
                if (hasTaskDates(predTask)) pEnd = new Date(predTask.endDate)
            }
            else
            {
                if (hasTaskForecast(predTask)) pEnd = new Date(predTask.forecastEnd)
                else if (hasTaskDates(predTask))
                    pEnd = new Date(predTask.endDate)
            }

            if (pEnd !== null)
            {
                if (maxPredEnd === null || pEnd > maxPredEnd) maxPredEnd = pEnd
            }
            else
            {
                var pNodeX = computeNodeX(pid, kind, taskById, nodes)
                if (pNodeX > maxPredNodeX) maxPredNodeX = pNodeX
            }
        }

        var result
        if (maxPredEnd !== null) result = (daysFromStart(maxPredEnd) + 1) * dayWidth + dayWidth / 2
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
                    nodeXL = root.nodeXByTaskTarget[tdL.id] !== undefined ? root.nodeXByTaskTarget[tdL.id] : dayWidth / 2

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
                    localGraphState: tdL.localGraphState,
                    progressCurrent: tdL.progressCurrent,
                    progressTotal: tdL.progressTotal
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
                                    nodeXVal = root.nodeXByTaskTarget[tasks[j]] !== undefined ? root.nodeXByTaskTarget[tasks[j]] : dayWidth / 2
                                else
                                    nodeXVal = root.nodeXByTaskForecast[tasks[j]] !== undefined ? root.nodeXByTaskForecast[tasks[j]] : dayWidth / 2
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
                                localGraphState: taskData.localGraphState,
                                progressCurrent: taskData.progressCurrent,
                                progressTotal: taskData.progressTotal
                            })
                            taskCounter++
                        }

                        if (mode === 0)
                        {
                            pushRow("target", taskData.startDate, taskData.endDate, hasDates, isUnapproved)
                        }
                        else if (mode === 1)
                        {
                            if (isCompleted || !hasFc) pushRow("target", taskData.startDate, taskData.endDate, hasDates, isUnapproved)
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

        visibleItems = items
        updateCounter++
        totalRows = visibleItems.length
        var minH = root.externalFlickable ? root.externalFlickable.height : (rowHeight * 5)
        contentHeight = Math.max(minH, totalRows * rowHeight)

        root.width = gridWidth
        root.height = contentHeight

        tasksRepeater.model = visibleItems
        backgroundCanvas.refresh()
        dependencyCanvas.refresh()
        if (currentTimeLine) currentTimeLine.updateLinePosition()
    }

    function updateTaskDates(taskId, newStart, newEnd)
    {
        if (projectController) projectController.updateTaskDates(taskId, newStart, newEnd)
    }

    function updateForecastDates(taskId, newStart, newEnd)
    {
        if (projectController) projectController.updateForecastDates(taskId, newStart, newEnd)
    }

    Connections
    {
        target: projectController?.projectData?.taskModel ?? null
        function onDataChanged(topLeft, bottomRight, roles) { updateData() }
        function onRowsInserted(parent, first, last) { updateData() }
        function onRowsRemoved(parent, first, last) { updateData() }
        function onModelReset() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.groupModel ?? null
        function onDataChanged(topLeft, bottomRight, roles) { updateData() }
        function onRowsInserted(parent, first, last) { updateData() }
        function onRowsRemoved(parent, first, last) { updateData() }
        function onCountChanged() { updateData() }
        function onModelReset() { updateData() }
        function onGroupExpandedChanged(groupId) { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.milestoneModel ?? null
        function onMilestonesChanged() { updateData() }
        function onModelReset() { updateData() }
    }

    Connections
    {
        target: projectController?.projectData?.dependencyModel ?? null
        function onRowsInserted(parent, first, last) { updateData() }
        function onRowsRemoved(parent, first, last) { updateData() }
        function onModelReset() { updateData() }
    }

    width: gridWidth
    height: contentHeight

    BackgroundCanvas
    {
        id: backgroundCanvas
        anchors.fill: parent
        z: 0

        displayStart: root.displayStart
        displayEnd: root.displayEnd
        totalDays: root.totalDays
        totalRows: root.totalRows
        dayWidth: root.dayWidth
        rowHeight: root.rowHeight
        visibleItems: root.visibleItems
    }

    DependencyCanvas
    {
        id: dependencyCanvas
        anchors.fill: parent
        z: 5

        visibleItems: root.visibleItems
        displayStart: root.displayStart
        dayWidth: root.dayWidth
        rowHeight: root.rowHeight
        showDependencies: root.showDependencies
        viewMode: root.currentViewMode()
    }

    Repeater
    {
        id: tasksRepeater
        model: []

        delegate: TaskRow
        {
            width: root.width
            y: index * root.rowHeight
            height: root.rowHeight

            rowData: modelData
            rowHeight: root.rowHeight
            displayStart: root.displayStart
            dayWidth: root.dayWidth
            showProgress: root.showProgress
            showComments: root.showComments
            showTaskHistory: root.showTaskHistory
            currentTimeLine: currentTimeLine
            updateCounter: root.updateCounter
            externalFlickable: root.externalFlickable
            taskContextMenu: taskContextMenu

            onTaskDatesChanged: function(taskId, newStart, newEnd) { root.updateTaskDates(taskId, newStart, newEnd) }
            onForecastDatesChanged: function(taskId, newStart, newEnd) { root.updateForecastDates(taskId, newStart, newEnd) }
        }
    }

    TaskContextMenu
    {
        id: taskContextMenu
    }
}
