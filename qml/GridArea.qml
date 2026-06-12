import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle {
    id: root
    color: "white"
    
    property int rowHeight: 40
    property date displayStart: new Date()
    property date displayEnd: new Date()
    property int dayWidth: 30
    property int totalDays: 1
    property real gridWidth: totalDays * dayWidth
    property int totalRows: 1
    property real contentHeight: totalRows * rowHeight
    
    property var visibleItems: []
    
    function getThirdSundayAfter(date) {
        var d = new Date(date)
        while (d.getDay() !== 0) d.setDate(d.getDate() + 1)
        d.setDate(d.getDate() + 14)
        d.setHours(23, 59, 59, 999)
        return d
    }
    
    function updateData() {
        if (!projectController || !projectController.projectData) return
        
        var firstMilestone = projectController.projectData.milestoneModel.getFirstMilestoneDate()
        var lastMilestone = projectController.projectData.milestoneModel.getLastMilestoneDate()
        
        if (firstMilestone && lastMilestone) {
            var start = new Date(firstMilestone)
            while (start.getDay() !== 1) start.setDate(start.getDate() - 1)
            start.setDate(start.getDate() - 28)
            start.setHours(0, 0, 0, 0)
            displayStart = start
            
            var end = getThirdSundayAfter(lastMilestone)
            displayEnd = end
            
            totalDays = Math.max(1, Math.floor((end - start) / 86400000) + 1)
            gridWidth = totalDays * dayWidth
        }
        
        var items = []
        var groups = projectController.projectData.groupModel
        var taskCounter = 0
        
        if (groups) {
            for (var i = 0; i < groups.rowCount(); i++) {
                var groupId = groups.getGroupId(i)
                var groupName = groups.getGroupName(i)
                var expanded = groups.isExpanded(i)
                
                items.push({type: "group", id: groupId, name: groupName})
                
                if (expanded) {
                    var tasks = projectController.projectData.taskModel.getTasksForGroup(groupId)
                    for (var j = 0; j < tasks.length; j++) {
                        var taskData = projectController.projectData.taskModel.getTask(tasks[j])
                        if (taskData) {
                            items.push({
                                type: "task",
                                taskId: tasks[j],
                                rowIndex: taskCounter,
                                taskTitle: taskData.title,
                                taskResponsible: taskData.responsible,
                                taskStart: taskData.startDate,
                                taskEnd: taskData.endDate,
                                taskStatus: taskData.status
                            })
                            taskCounter++
                        }
                    }
                }
            }
        }
        
        visibleItems = items
        totalRows = visibleItems.length + 1
        contentHeight = totalRows * rowHeight
        
        root.width = gridWidth
        root.height = contentHeight
        
        groupsRepeater.model = visibleItems
        gridCanvas.requestPaint()
        if (currentTimeLine) currentTimeLine.updateLinePosition()
    }
    
    function updateTaskDates(taskId, newStart, newEnd) {
        if (projectController) {
            projectController.updateTaskDates(taskId, newStart, newEnd)
        }
    }
    
    Component.onCompleted: updateData()
    
    Connections {
        target: (projectController && projectController.projectData) ? projectController.projectData.taskModel : null
            enabled: target !== null
        function onDataChanged() { updateData() }
        function onRowsInserted() { updateData() }
        function onRowsRemoved() { updateData() }
    }
    
    Connections {
        target: (projectController && projectController.projectData) ? projectController.projectData.groupModel : null
            enabled: target !== null
        function onDataChanged() { updateData() }
        function onRowsInserted() { updateData() }
        function onGroupExpandedChanged() { updateData() }
    }
    
    Connections {
        target: (projectController && projectController.projectData) ? projectController.projectData.milestoneModel : null
            enabled: target !== null
        function onMilestonesChanged() { updateData() }
    }
    
    width: gridWidth
    height: contentHeight
    
    Canvas {
        id: gridCanvas
        anchors.fill: parent
        z: 0
        
        onPaint: {
            if (totalDays <= 0 || width <= 0 || height <= 0) return
            
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            ctx.beginPath()
            ctx.setLineDash([2, 4])
            ctx.strokeStyle = "#cccccc"
            ctx.lineWidth = 1
            for (var d = 1; d < totalDays; d++) {
                var xd = d * dayWidth
                if (xd < width) {
                    ctx.moveTo(xd, 0)
                    ctx.lineTo(xd, height)
                }
            }
            ctx.stroke()
            
            ctx.beginPath()
            ctx.setLineDash([])
            ctx.strokeStyle = "#aaaaaa"
            for (var w = 1; w < totalDays / 7; w++) {
                var xw = w * dayWidth * 7
                if (xw < width) {
                    ctx.moveTo(xw, 0)
                    ctx.lineTo(xw, height)
                }
            }
            ctx.stroke()
            
            ctx.beginPath()
            ctx.lineWidth = 2
            ctx.strokeStyle = "#888888"
            var currentDate = new Date(displayStart)
            var x = 0
            while (currentDate <= displayEnd) {
                var nextMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                var daysInMonth = Math.ceil((nextMonth - currentDate) / 86400000)
                x += daysInMonth * dayWidth
                if (x < width && x > 0) {
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                }
                currentDate = nextMonth
            }
            ctx.stroke()
            
            ctx.beginPath()
            ctx.lineWidth = 1
            ctx.strokeStyle = "#dddddd"
            for (var r = 1; r < totalRows; r++) {
                var y = r * rowHeight
                if (y < height) {
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                }
            }
            ctx.stroke()
            
            ctx.beginPath()
            ctx.lineWidth = 3
            ctx.strokeStyle = "#666666"
            var lastY = totalRows * rowHeight
            if (lastY <= height && lastY > 0) {
                ctx.moveTo(0, lastY)
                ctx.lineTo(width, lastY)
            }
            ctx.stroke()
        }
    }
    
    Rectangle {
        id: infoRow
        width: parent.width
        height: rowHeight
        color: "#f5f5f5"
        border.color: "#dddddd"
        border.width: 1
        z: 2
        
        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 20
            Text { 
                text: "Создан: " + (projectController?.projectData?.creationDateTime?.toLocaleString() || "не указано")
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11
            }
            Text { 
                text: "Изменён: " + (projectController?.projectData?.lastModifiedDateTime?.toLocaleString() || "не указано")
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11
            }
        }
    }
    
    Repeater {
        id: groupsRepeater
        model: visibleItems
        
        delegate: Rectangle {
            id: rowContainer
            y: infoRow.height + (index * rowHeight)
            width: parent.width
            height: rowHeight
            color: "transparent"
            
            Text {
                visible: modelData && modelData.type === "group"
                text: (modelData && modelData.name) ? modelData.name : ""
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                font.pixelSize: 12
            }
            
            Rectangle {
                id: ganttBar
                visible: modelData && modelData.type === "task"
                
                x: {
                    if (modelData && (!modelData.taskStart || !root.displayStart)) return 0
                    var daysDiff = Math.floor((modelData.taskStart - root.displayStart) / (1000 * 60 * 60 * 24))
                    return Math.max(0, daysDiff * root.dayWidth)
                }
                
                width: {
                    if (modelData && (!modelData.taskStart || !modelData.taskEnd)) return 10
                    var daysDiff = Math.floor((modelData.taskEnd - modelData.taskStart) / (1000 * 60 * 60 * 24)) + 1
                    return Math.max(10, daysDiff * root.dayWidth)
                }
                
                height: parent.height - 8
                y: 4
                
                function getStatusColor() {
                    var task = projectController?.projectData?.taskModel?.getTask(modelData.taskId)
                    if (task) {
                        switch(task.status) {
                            case 0: return "#FFD700"
                            case 1: return "#32CD32"
                            case 2: return "#FF8C00"
                            case 3: return "#FF4444"
                            default: return "#FFD700"
                        }
                    }
                    return "#FFD700"
                }
                
                color: getStatusColor()
                radius: 4
                border.color: Qt.darker(color, 1.2)
                border.width: 1
                
                function updateDates() {
                    var newStartDays = Math.round(x / root.dayWidth)
                    var newStart = new Date(root.displayStart)
                    newStart.setDate(newStart.getDate() + newStartDays)
                    
                    var newEndDays = Math.round((x + width) / root.dayWidth)
                    var newEnd = new Date(root.displayStart)
                    newEnd.setDate(newEnd.getDate() + newEndDays - 1)
                    
                    if (newStart < newEnd) {
                        root.updateTaskDates(modelData.taskId, newStart, newEnd)
                    }
                }
                
                ToolTip {
                    visible: moveArea.containsMouse
                    text: {
                        var task = projectController?.projectData?.taskModel?.getTask(modelData.taskId)
                        if (!task) return ""
                        var duration = Math.floor((task.endDate - task.startDate) / (24 * 60 * 60 * 1000)) + 1
                        return task.title + "\nДлительность: " + duration + 
                               " дней\nОтветственный: " + task.responsible
                    }
                    delay: 500
                }
                
                MouseArea {
                    id: moveArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: rowContainer.width - parent.width
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            taskContextMenu.taskId = modelData.taskId
                            taskContextMenu.popup()
                            mouse.accepted = true
                        }
                    }
                    
                    onPositionChanged: {
                        if (drag.active) {
                            parent.x = Math.round(parent.x / root.dayWidth) * root.dayWidth
                        }
                    }
                    
                    onReleased: {
                        if (drag.active) {
                            parent.updateDates()
                        }
                    }
                }
                
                Rectangle {
                    width: 10
                    height: parent.height
                    anchors.right: parent.right
                    color: Qt.darker(parent.color, 1.5)
                    radius: 2
                    visible: moveArea.containsMouse
                    
                    MouseArea {
                        id: resizeArea
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startWidth: 0
                        property real startMouseX: 0
                        
                        onPressed: {
                            startWidth = ganttBar.width
                            startMouseX = mouseX
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouseX - startMouseX
                                var newWidth = startWidth + delta
                                newWidth = Math.max(10, Math.round(newWidth / root.dayWidth) * root.dayWidth)
                                if (newWidth !== ganttBar.width) {
                                    ganttBar.width = newWidth
                                }
                            }
                        }
                        
                        onReleased: {
                            ganttBar.updateDates()
                        }
                    }
                }
                
                Connections {
                    target: (projectController && projectController.projectData) ? projectController.projectData.taskModel : null
            enabled: target !== null
                    function onDataChanged() {
                        ganttBar.color = ganttBar.getStatusColor()
                    }
                }
            }
        }
    }
    
    Menu {
        id: taskContextMenu
        property string taskId: ""
        
        MenuItem { 
            text: "Переименовать"
            onTriggered: { 
                if(taskContextMenu.taskId) editTaskDialog.open(taskContextMenu.taskId) 
            }
        }
        MenuItem { text: "Назначить ответственного" }
        Menu {
            title: "Изменить статус"
            MenuItem { 
                text: "🟡 Запланировано"
                onTriggered: { 
                    if(taskContextMenu.taskId && projectController) 
                        projectController.projectData.taskModel.setTaskStatus(taskContextMenu.taskId, 0) 
                }
            }
            MenuItem { 
                text: "🟢 Выполнено"
                onTriggered: { 
                    if(taskContextMenu.taskId && projectController) 
                        projectController.projectData.taskModel.setTaskStatus(taskContextMenu.taskId, 1) 
                }
            }
            MenuItem { 
                text: "🟠 Имеются риски"
                onTriggered: { 
                    if(taskContextMenu.taskId && projectController) 
                        projectController.projectData.taskModel.setTaskStatus(taskContextMenu.taskId, 2) 
                }
            }
            MenuItem { 
                text: "🔴 Блокировано"
                onTriggered: { 
                    if(taskContextMenu.taskId && projectController) 
                        projectController.projectData.taskModel.setTaskStatus(taskContextMenu.taskId, 3) 
                }
            }
        }
        MenuItem { 
            text: "Изменить сроки"
            onTriggered: { 
                if(taskContextMenu.taskId) editTaskDialog.open(taskContextMenu.taskId) 
            }
        }
        MenuSeparator {}
        MenuItem { text: "Добавить задачу сверху" }
        MenuItem { text: "Добавить задачу снизу" }
        MenuItem { 
            text: "Удалить"
            onTriggered:
            {
                if(taskContextMenu.taskId && projectController) 
                    projectController.removeTask(taskContextMenu.taskId) 
                }
            }
        }
    
    CurrentTimeLine
    {
        id: currentTimeLine
        displayStart: root.displayStart
        dayWidth: root.dayWidth
    }
}
