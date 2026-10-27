.pragma library

// Строит список строк для задачи в левой панели и в сетке Ганта
// с учётом режима отображения (0 = target, 1 = forecast, 2 = combined).
//
// Возвращает массив объектов:
//   { taskId, rowKind: "target"|"forecast", data: <QVariantMap>, isCompleted: bool }

function buildGroupRows(taskModel, taskIds, mode)
{
    var rows = []
    for (var i = 0; i < taskIds.length; i++)
    {
        var taskData = taskModel.getTask(taskIds[i])
        if (!taskData) continue
        var isCompleted = (taskData.status === 1)

        if (mode === 0)
        {
            rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: isCompleted})
        }
        else if (mode === 1)
        {
            if (isCompleted)
                rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: true})
            else
                rows.push({taskId: taskIds[i], rowKind: "forecast", data: taskData, isCompleted: false})
        }
        else
        {
            rows.push({taskId: taskIds[i], rowKind: "target", data: taskData, isCompleted: isCompleted})
            if (!isCompleted)
                rows.push({taskId: taskIds[i], rowKind: "forecast", data: taskData, isCompleted: false})
        }
    }
    return rows
}

// Для GridArea: возвращает true, если для задачи в данном режиме
// должна быть только одна строка target (для completed в режиме 1).
function isCompletedTargetOnly(taskData, mode)
{
    return mode === 1 && taskData && taskData.status === 1
}
