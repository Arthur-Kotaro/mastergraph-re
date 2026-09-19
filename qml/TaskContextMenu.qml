import QtQuick 6.0
import QtQuick.Controls 6.0

Menu
{
    id: root
    property string taskId: ""

    property var onAddTaskAboveCallback: null
    property var onAddTaskBelowCallback: null

    property bool canAcceptForecast: false
    property bool canEditForecast: true
    property int localGraphState: 0
    property bool isTaskCompleted: false

    onOpened: updateState()

    function updateState()
    {
        canAcceptForecast = false
        canEditForecast = true
        localGraphState = 0
        isTaskCompleted = false

        if (!taskId || !projectController || !projectController.projectData) return

        var task = projectController.projectData.taskModel.getTask(taskId)
        if (!task) return

        isTaskCompleted = (task.status === 1)
        localGraphState = task.localGraphState !== undefined ? task.localGraphState : 0

        // Прогноз редактируется вручную только если у задачи нет ЛГ
        canEditForecast = !(localGraphState === 2 || localGraphState === 3)

        if (projectController.settingsManager.editingLocked) return
        if (isTaskCompleted) return

        var fs = task.forecastStart
        var fe = task.forecastEnd
        var ss = task.startDate
        var se = task.endDate

        if (!fs || !fe || !ss || !se) return
        if (fs.toString() === ss.toString() && fe.toString() === se.toString()) return

        canAcceptForecast = true
    }

    MenuItem
    {
        text: "Переименовать"
        onTriggered:
        {
            if (root.taskId && mainWindow && mainWindow.renameTaskDialog)
                mainWindow.renameTaskDialog.openForTask(root.taskId)
        }
    }

    MenuItem
    {
        text: "Назначить ответственного"
        onTriggered:
        {
            if (root.taskId && mainWindow && mainWindow.responsibleDialog)
                mainWindow.responsibleDialog.openForTask(root.taskId)
        }
    }

    MenuItem
    {
        text: "Изменить комментарий"
        onTriggered:
        {
            if (root.taskId && mainWindow && mainWindow.commentDialog)
                mainWindow.commentDialog.openForTask(root.taskId)
        }
    }

    Menu
    {
        title: "Изменить статус"
        MenuItem { text: "🟡 Запланировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(root.taskId, 0) }
        MenuItem { text: "🟢 Выполнено"; onTriggered: if(mainWindow) mainWindow.completeTaskDialog.openForTask(root.taskId) }
        MenuItem { text: "🟠 Имеются риски"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(root.taskId, 2) }
        MenuItem { text: "🔴 Блокировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(root.taskId, 3) }
    }

    MenuItem
    {
        text: "Изменить сроки"
        onTriggered:
        {
            if (root.taskId && typeof mainWindow !== "undefined" && mainWindow.editTaskDialog)
                mainWindow.editTaskDialog.openForTask(root.taskId)
        }
    }

    MenuItem
    {
        text: "Изменить прогнозные сроки"
        enabled: root.canEditForecast && !root.isTaskCompleted
        onTriggered:
        {
            if (root.taskId && typeof mainWindow !== "undefined" && mainWindow.editForecastDatesDialog)
                mainWindow.editForecastDatesDialog.openForTask(root.taskId)
        }
    }

    MenuItem
    {
        text: "Утвердить прогноз"
        enabled: root.canAcceptForecast
        onTriggered:
        {
            if (root.taskId && projectController)
                projectController.acceptForecastAsTarget(root.taskId)
        }
    }

    MenuSeparator {}

    Menu
    {
        title: "Изменить зависимости"

        MenuItem
        {
            text: "Добавить нисходящую зависимость"
            onTriggered: if(mainWindow && mainWindow.dependencyDialog) mainWindow.dependencyDialog.openForTask(root.taskId, true)
        }

        MenuItem
        {
            text: "Добавить восходящую зависимость"
            onTriggered: if(mainWindow && mainWindow.dependencyDialog) mainWindow.dependencyDialog.openForTask(root.taskId, false)
        }

        MenuSeparator {}

        MenuItem
        {
            text: "Удалить нисходящую зависимость"
            onTriggered: if(projectController) projectController.projectData.dependencyModel.removeDownstreamDependency(root.taskId)
        }

        MenuItem
        {
            text: "Удалить восходящую зависимость"
            onTriggered: if(projectController) projectController.projectData.dependencyModel.removeUpstreamDependency(root.taskId)
        }
    }

    MenuSeparator {}

    Menu
    {
        title: "Локальный график"

        MenuItem
        {
            text: "Пометить как требующую ЛГ"
            enabled: !root.isTaskCompleted && root.localGraphState === 0
            onTriggered:
            {
                if (root.taskId && projectController)
                    projectController.markTaskRequiresLocalGraph(root.taskId)
            }
        }

        MenuItem
        {
            text: "Создать локальный график"
            enabled: !root.isTaskCompleted
                     && (root.localGraphState === 1 || root.localGraphState === 3)
            onTriggered:
            {
                if (!root.taskId || !projectController) return
                if (projectController.localGraphFileExists(root.taskId))
                {
                    if (mainWindow && mainWindow.localGraphExistsDialog)
                        mainWindow.localGraphExistsDialog.openForTask(root.taskId)
                }
                else
                {
                    projectController.createLocalGraph(root.taskId)
                }
            }
        }

        MenuItem
        {
            text: "Открыть локальный график"
            enabled: root.localGraphState === 2
            onTriggered:
            {
                if (root.taskId && sessionManager)
                    sessionManager.openLocalGraphSession(root.taskId)
            }
        }

        MenuItem
        {
            text: "Отвязать локальный график"
            enabled: root.localGraphState === 1
                     || root.localGraphState === 2
                     || root.localGraphState === 3
            onTriggered:
            {
                // TODO: C4.5
            }
        }
    }

    MenuSeparator {}

    MenuItem
    {
        text: "Добавить задачу сверху"
        onTriggered:
        {
            if (root.onAddTaskAboveCallback) root.onAddTaskAboveCallback(root.taskId)
        }
    }

    MenuItem
    {
        text: "Добавить задачу снизу"
        onTriggered:
        {
            if (root.onAddTaskBelowCallback) root.onAddTaskBelowCallback(root.taskId)
        }
    }

    MenuItem
    {
        text: "Удалить"
        onTriggered:
        {
            if(root.taskId && projectController) projectController.removeTask(root.taskId)
        }
    }
}
