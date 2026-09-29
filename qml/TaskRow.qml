import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root
    height: 40
    color: "transparent"

    property var rowData
    property int rowHeight: 40
    property date displayStart: new Date()
    property int dayWidth: 30
    property bool showProgress: true
    property bool showComments: true
    property bool showTaskHistory: true
    property var currentTimeLine: null
    property int updateCounter: 0
    property var externalFlickable: null
    property var taskContextMenu: null

    // Поднимаем слой строки, пока виден тултип — иначе соседние TaskRow его перекрывают
    property bool tooltipVisible: false
    z: tooltipVisible ? 50 : 0

    signal taskDatesChanged(string taskId, date newStart, date newEnd)
    signal forecastDatesChanged(string taskId, date newStart, date newEnd)

    function isForecastLocked()
    {
        if (!rowData) return false
        if (rowData.rowKind !== "forecast") return false
        var lgs = rowData.localGraphState !== undefined ? rowData.localGraphState : 0
        return (lgs === 2 || lgs === 3)
    }

    // ---------- Заголовок группы ----------
    Text
    {
        visible: rowData && rowData.type === "group"
        text: rowData ? (rowData.name || "") : ""
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        font.bold: true
        font.pixelSize: 14
        z: 3
    }

    // ---------- Узел ----------
    Rectangle
    {
        id: nodeCircle
        visible: rowData && rowData.type === "task"
                 && rowData.hasDates !== true
                 && rowData.isUnapproved !== true
        x: rowData ? ((rowData.nodeX || 0) - 15) : 0
        y: root.height / 2 - 15
        width: 30
        height: 30
        radius: 15
        color:
        {
            if (!rowData) return "#FFD700"
            switch (rowData.taskStatus)
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
            id: nodeArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            hoverEnabled: true

            onClicked: function(mouse)
            {
                if (mouse.button === Qt.RightButton && rowData && root.taskContextMenu)
                {
                    root.taskContextMenu.taskId = rowData.taskId
                    root.taskContextMenu.popup()
                }
            }
        }
    }

    // ---------- Полоса Ганта ----------
    Rectangle
    {
        id: ganttBar
        visible: rowData && rowData.type === "task"
                 && (rowData.hasDates === true || rowData.isUnapproved === true)

        x:
        {
            if (!rowData) return 0
            var startVal = (rowData.hasDates === true) ? rowData.taskStart : rowData.forecastStart
            if (!startVal || !root.displayStart) return 0
            var daysDiff = Math.floor((new Date(startVal) - root.displayStart) / 86400000)
            return Math.max(0, daysDiff * root.dayWidth)
        }

        width:
        {
            if (!rowData) return 10
            var sVal = (rowData.hasDates === true) ? rowData.taskStart : rowData.forecastStart
            var eVal = (rowData.hasDates === true) ? rowData.taskEnd : rowData.forecastEnd
            if (!sVal || !eVal) return 10
            var daysDiff = Math.floor((new Date(eVal) - new Date(sVal)) / 86400000) + 1
            return Math.max(10, daysDiff * root.dayWidth)
        }

        height: parent.height - 8
        y: 4

        function getStatusColor()
        {
            if (!rowData) return "#FFD700"
            switch (rowData.taskStatus)
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
            if (rowData && rowData.rowKind === "forecast")
                return Qt.lighter(getStatusColor(), 1.2)
            return getStatusColor()
        }

        function getBarOpacity()
        {
            if (rowData && rowData.rowKind === "forecast") return 0.6
            return 1.0
        }

        color: getBarColor()
        opacity: getBarOpacity()
        radius: 4

        Rectangle
        {
            id: progressFill
            visible: root.showProgress
                     && rowData
                     && rowData.type === "task"
                     && (rowData.progressTotal || 0) > 0
                     && (rowData.progressCurrent || 0) >= 0
                     && rowData.isUnapproved !== true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.min(1, rowData.progressCurrent / rowData.progressTotal)
            color: (rowData && rowData.rowKind === "forecast") ? Qt.lighter("#32CD32", 1.2) : "#32CD32"
            opacity: (rowData && rowData.rowKind === "forecast") ? 0.6 : 1.0
            radius: 4
            z: 1
        }

        Text
        {
            id: progressText
            visible: root.showProgress
                     && rowData
                     && rowData.type === "task"
                     && (rowData.progressTotal || 0) > 0
                     && (rowData.progressCurrent || 0) >= 0
                     && rowData.isUnapproved !== true
                     && parent.width > 90
            anchors.centerIn: parent
            text: rowData ? ("Прогресс: " + rowData.progressCurrent + "/" + rowData.progressTotal) : ""
            font.pixelSize: 11
            color: "#222222"
            z: 2
        }

        Canvas
        {
            id: stripesCanvas
            anchors.fill: parent
            visible: rowData && rowData.type === "task" && rowData.isUnapproved === true

            onPaint:
            {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (!rowData || rowData.isUnapproved !== true) return
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
                if (rowData && rowData.rowKind === "forecast")
                    root.forecastDatesChanged(rowData.taskId, newStart, newEnd)
                else
                    root.taskDatesChanged(rowData.taskId, newStart, newEnd)
            }
        }

        MouseArea
        {
            id: moveArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property bool suppressClick: false
            property bool showTooltip: false

            Timer
            {
                id: tooltipDelay
                interval: 500
                repeat: false
                onTriggered:
                {
                    moveArea.showTooltip = true
                    root.tooltipVisible = true
                }
            }

            onEntered: tooltipDelay.restart()
            onExited:
            {
                tooltipDelay.stop()
                moveArea.showTooltip = false
                root.tooltipVisible = false
            }

            onPressed: function(mouse)
            {
                if (mouse.button === Qt.RightButton)
                {
                    drag.target = null
                    suppressClick = false
                    return
                }

                if (root.isForecastLocked())
                {
                    drag.target = null
                    return
                }

                if (projectController && projectController.settingsManager.editingLocked)
                {
                    drag.target = null
                    return
                }

                if (rowData && rowData.isCompleted)
                {
                    drag.target = null
                    return
                }

                drag.target = parent
                drag.minimumX = 0
                drag.maximumX = root.width - parent.width
                if (root.externalFlickable) root.externalFlickable.interactive = false
            }

            onPositionChanged:
            {
                if (!drag.active) return

                if (root.isForecastLocked())
                {
                    drag.target = null
                    return
                }
                if (projectController && projectController.settingsManager.editingLocked)
                {
                    drag.target = null
                    return
                }

                if (drag.target !== null && drag.target !== undefined)
                {
                    suppressClick = true
                    parent.x = Math.round(parent.x / root.dayWidth) * root.dayWidth
                }
            }

            onReleased:
            {
                if (root.externalFlickable) root.externalFlickable.interactive = true
                if (drag.active)
                {
                    drag.target = null
                    parent.updateDates()
                }
            }

            onClicked: function(mouse)
            {
                if (mouse.button === Qt.RightButton && !suppressClick)
                {
                    if (rowData && root.taskContextMenu)
                    {
                        root.taskContextMenu.taskId = rowData.taskId
                        root.taskContextMenu.popup()
                    }
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
            visible: moveArea.containsMouse && !root.isForecastLocked()
            enabled: !(rowData && rowData.isCompleted) && !root.isForecastLocked()

            MouseArea
            {
                id: resizeArea
                enabled: !(rowData && rowData.isCompleted) && !root.isForecastLocked()
                anchors.fill: parent
                cursorShape: root.isForecastLocked() ? Qt.ArrowCursor : Qt.SizeHorCursor

                property real startWidth: 0
                property real startMouseX: 0

                onPressed:
                {
                    if (root.isForecastLocked()) return
                    if (projectController && projectController.settingsManager.editingLocked) return
                    if (rowData && rowData.isCompleted) return

                    if (root.externalFlickable) root.externalFlickable.interactive = false
                    startWidth = ganttBar.width
                    startMouseX = mapToItem(ganttBar, mouseX, 0).x
                }

                onPositionChanged:
                {
                    if (root.isForecastLocked()) return
                    if (projectController && projectController.settingsManager.editingLocked) return
                    if (rowData && rowData.isCompleted) return

                    if (pressed)
                    {
                        var currentX = mapToItem(ganttBar, mouseX, 0).x
                        var delta = currentX - startMouseX
                        var newWidth = startWidth + delta
                        newWidth = Math.max(10, Math.round(newWidth / root.dayWidth) * root.dayWidth)
                        if (newWidth !== ganttBar.width) ganttBar.width = newWidth
                    }
                }

                onReleased:
                {
                    if (root.externalFlickable) root.externalFlickable.interactive = true
                    ganttBar.updateDates()
                }
            }
        }
    }

    // ---------- Комментарий ----------
    Text
    {
        visible: root.showComments && (rowData && rowData.type === "task")
        text:
        {
            if (!rowData) return ""
            var forceUpdate = root.updateCounter
            return rowData.taskComment ? rowData.taskComment : ""
        }
        x: ganttBar.x + ganttBar.width + 14
        y: ganttBar.y + 4
        font.pixelSize: 14
        color: "#666666"
        elide: Text.ElideRight
        width: Math.min(350, root.width - ganttBar.x - ganttBar.width - 10)
    }

    // ---------- История переносов ----------
    Repeater
    {
        model:
        {
            if (rowData && rowData.type === "task" && rowData.rowKind === "target"
                && rowData.hasDates === true && root.showTaskHistory)
            {
                var task = projectController?.projectData?.taskModel?.getTask(rowData.taskId)
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
            border.color: "#888888"
            border.width: 1
            z: -1
        }
    }

    // ---------- Кастомный ToolTip, привязанный к курсору мыши ----------
    Rectangle
    {
        id: barTooltip
        visible: moveArea.showTooltip && rowData && rowData.type === "task"
        color: "#333333"
        radius: 4
        opacity: 0.95
        z: 100

        x: ganttBar.x + moveArea.mouseX + 16
        y: ganttBar.y + moveArea.mouseY + 12

        states: State
        {
            name: "left"
            when: (ganttBar.x + moveArea.mouseX + 16 + barTooltip.width) > root.width
            PropertyChanges
            {
                target: barTooltip
                x: ganttBar.x + moveArea.mouseX - barTooltip.width - 16
            }
        }

        width: tooltipText.implicitWidth + 24
        height: tooltipText.implicitHeight + 20

        Text
        {
            id: tooltipText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 14
            lineHeight: 1.2
            text:
            {
                if (!rowData) return ""

                var lines = []

                // Заголовок
                var label = (rowData.rowKind === "forecast") ? "Прогноз: " : ""
                lines.push(label + rowData.taskTitle)

                // Ответственный
                var resp = rowData.taskResponsible && rowData.taskResponsible !== "" ? rowData.taskResponsible : "—"
                lines.push("Ответственный: " + resp)

                // Целевые сроки
                if (rowData.hasDates === true)
                {
                    var s = Qt.formatDateTime(new Date(rowData.taskStart), "dd.MM.yyyy")
                    var e = Qt.formatDateTime(new Date(rowData.taskEnd), "dd.MM.yyyy")
                    var dur = Math.floor((new Date(rowData.taskEnd) - new Date(rowData.taskStart)) / 86400000) + 1
                    lines.push("Целевые сроки: " + s + " — " + e + " (" + dur + " дн.)")
                }

                // Прогноз
                if (rowData.hasForecast === true
                    && (rowData.rowKind === "forecast" || rowData.isUnapproved === true))
                {
                    var fs = Qt.formatDateTime(new Date(rowData.forecastStart), "dd.MM.yyyy")
                    var fe = Qt.formatDateTime(new Date(rowData.forecastEnd), "dd.MM.yyyy")
                    lines.push("Прогноз: " + fs + " — " + fe)
                }

                // Статус
                var statusText = "Запланировано"
                switch (rowData.taskStatus)
                {
                    case 0: statusText = "Запланировано"; break
                    case 1: statusText = "Выполнено"; break
                    case 2: statusText = "Имеются риски"; break
                    case 3: statusText = "Блокировано"; break
                }
                lines.push("Статус: " + statusText)

                // Прогресс
                if ((rowData.progressTotal || 0) > 0 && (rowData.progressCurrent || 0) >= 0)
                    lines.push("Прогресс: " + rowData.progressCurrent + " / " + rowData.progressTotal)

                // Локальный график
                var lgs = rowData.localGraphState !== undefined ? rowData.localGraphState : 0
                var lgsText = ""
                switch (lgs)
                {
                    case 1: lgsText = "требуется"; break
                    case 2: lgsText = "привязан"; break
                    case 3: lgsText = "отсутствует"; break
                }
                if (lgsText !== "") lines.push("Локальный график: " + lgsText)

                // Комментарий
                if (rowData.taskComment && rowData.taskComment !== "")
                    lines.push("Комментарий: " + rowData.taskComment)

                return lines.join("\n")
            }
        }
    }
}
