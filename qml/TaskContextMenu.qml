import QtQuick 6.0
import QtQuick.Controls 6.0

Menu
{
    id: root
    property string taskId: ""

    signal addTaskAbove(string tId)
    signal addTaskBelow(string tId)

    MenuItem
    {
        text: "Переименовать"
        onTriggered:
        {
            if (root.taskId && typeof mainWindow !== "undefined" && mainWindow.editTaskDialog)
                mainWindow.editTaskDialog.openForTask(root.taskId)
        }
    }

    MenuItem
    {
        text: "Назначить ответственного"
    }

    Menu
    {
        title: "Изменить статус"
        MenuItem { text: "🟡 Запланировано"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(root.taskId, 0) }
        MenuItem { text: "🟢 Выполнено"; onTriggered: if(projectController) projectController.projectData.taskModel.setTaskStatus(root.taskId, 1) }
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
        }

        MenuItem
        {
            text: "Удалить восходящую зависимость"
        }
    }

    MenuSeparator {}

    MenuItem
    {
        text: "Добавить задачу сверху"
        onTriggered: root.addTaskAbove(root.taskId)
    }

    MenuItem
    {
        text: "Добавить задачу снизу"
        onTriggered: root.addTaskBelow(root.taskId)
    }

    MenuItem
    {
        text: "Удалить"
        onTriggered:
        {
            if(root.taskId && projectController)
                projectController.removeTask(root.taskId)
        }
    }
}