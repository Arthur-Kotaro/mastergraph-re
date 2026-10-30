import QtQuick 6.0
import QtQuick.Controls 6.0
import "utils/GridRange.js" as GridRange
import "utils/GridLayoutBuilder.js" as GridLayoutBuilder

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
    property var taskContextMenu: null
    property var timeLineRef: currentTimeLine

    property bool showTargetStartLine: false
    property bool showTargetEndLine: false
    property real targetStartLineX: 0
    property real targetEndLineX: 0
    property bool targetStartLineArrows: true
    property bool targetEndLineArrows: true
    property bool targetStartLineIsPredecessor: false

    property int effectiveRows: totalRows

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

    TargetDatesLine
    {
        id: targetStartLine
        visible: root.isLocalMode && root.showTargetStartLine
        x: root.targetStartLineX
        showArrows: root.targetStartLineArrows
        arrowDirection: "right"
        lineColor: root.targetStartLineIsPredecessor ? "#FF4444" : "#2266cc"
    }

    TargetDatesLine
    {
        id: targetEndLine
        visible: root.isLocalMode && root.showTargetEndLine
        x: root.targetEndLineX
        showArrows: root.targetEndLineArrows
        arrowDirection: "left"
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
        function onLinkedPredecessorEndDateChanged() { updateData() }
    }

    function currentViewMode()
    {
        if (isLocalMode) return 0
        return projectController && projectController.settingsManager ? projectController.settingsManager.viewMode : 0
    }

    function updateTargetDateLines()
    {
        showTargetStartLine = false
        showTargetEndLine = false
        targetStartLineX = 0
        targetEndLineX = 0
        targetStartLineArrows = true
        targetEndLineArrows = true
        targetStartLineIsPredecessor = false

        if (!isLocalMode) return
        if (!projectController || !projectController.projectData) return

        var linkedStart = projectController.projectData.getLinkedTargetStart()
        var linkedEnd = projectController.projectData.getLinkedTargetEnd()
        var predEnd = projectController.projectData.getLinkedPredecessorEndDate()

        if (GridRange.isValidDate(linkedStart) && GridRange.isValidDate(linkedEnd))
        {
            var xs = GridRange.dateToX(linkedStart, root.displayStart, root.dayWidth)
            var xe = GridRange.dateToX(linkedEnd, root.displayStart, root.dayWidth)
            if (xs >= 0) { targetStartLineX = xs; showTargetStartLine = true; targetStartLineIsPredecessor = false }
            if (xe >= 0) { targetEndLineX = xe + root.dayWidth; showTargetEndLine = true }
        }

        if (GridRange.isValidDate(predEnd))
        {
            var xp = GridRange.dateToX(predEnd, root.displayStart, root.dayWidth)
            if (xp >= 0)
            {
                targetStartLineX = xp + root.dayWidth
                showTargetStartLine = true
                targetStartLineArrows = true
                targetStartLineIsPredecessor = true
            }
        }
    }

    function updateData()
    {
        if (!projectController || !projectController.projectData) return

        var localMode = (projectController.projectData.graphKind === 1)

        // 1. Расчет диапазона дат
        if (localMode)
        {
            var linkedStart = projectController.projectData.getLinkedTargetStart()
            var linkedEnd = projectController.projectData.getLinkedTargetEnd()
            var earliest = projectController.projectData.getEarliestDate()
            var latest = projectController.projectData.getLatestDate()
            var s, e

            if (GridRange.isValidDate(linkedStart) && GridRange.isValidDate(linkedEnd))
            {
                var range = GridRange.computeLocalDisplayRange(linkedStart, linkedEnd, earliest, latest)
                s = range.start
                e = range.end
            }
            else
            {
                var now = new Date()
                s = new Date(now.getFullYear(), now.getMonth() - 1, 1)
                e = new Date(now.getFullYear(), now.getMonth() + 2, 0)
                s.setHours(0, 0, 0, 0)
                e.setHours(23, 59, 59, 999)
                if (GridRange.isValidDate(earliest) && earliest < s) s = new Date(earliest)
                if (GridRange.isValidDate(latest) && latest > e) e = new Date(latest)
                while (s.getDay() !== 1) s.setDate(s.getDate() - 1)
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

        // 2. Сбор конфликтов
        var conflictSet = {}
        if (localMode)
        {
            var conflictIds = projectController.projectData.getConflictingTaskIds()
            for (var ci = 0; ci < conflictIds.length; ci++)
                conflictSet[conflictIds[ci]] = true
        }

        // 3. Вызов Билдера для сборки items
        var items = GridLayoutBuilder.buildLayout({
            localMode: localMode,
            displayStart: displayStart,
            dayWidth: dayWidth,
            mode: currentViewMode(),
            conflictSet: conflictSet,
            projectData: projectController.projectData
        })

        // 4. Применение результатов
        visibleItems = items
        updateCounter++
        totalRows = visibleItems.length

        var rowsForHeight = (localMode) ? Math.max(totalRows, 5) : totalRows
        effectiveRows = rowsForHeight
        contentHeight = rowsForHeight * rowHeight

        root.width = gridWidth
        root.height = contentHeight

        tasksRepeater.model = visibleItems
        updateTargetDateLines()
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
            timeLineRef: root.timeLineRef
            updateCounter: root.updateCounter
            externalFlickable: root.externalFlickable
            taskContextMenu: root.taskContextMenu

            onTaskDatesChanged: function(taskId, newStart, newEnd) { root.updateTaskDates(taskId, newStart, newEnd) }
            onForecastDatesChanged: function(taskId, newStart, newEnd) { root.updateForecastDates(taskId, newStart, newEnd) }
        }
    }

    Rectangle
    {
        id: bottomLine
        width: parent.width
        height: 3
        y: parent.height - height
        color: "#666666"
        z: 50
        visible: root.contentHeight > 0
    }
}
