#include "TaskModel.h"
#include <QUuid>
#include <QDebug>

TaskModel::TaskModel(QObject *parent) : QAbstractListModel(parent) {}

int TaskModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_tasks.count();
}

QHash<int, QByteArray> TaskModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[GanttDefines::IdRole] = "taskId";
    roles[GanttDefines::TitleRole] = "title";
    roles[GanttDefines::ResponsibleRole] = "responsible";
    roles[GanttDefines::StartDateRole] = "startDate";
    roles[GanttDefines::EndDateRole] = "endDate";
    roles[GanttDefines::StatusRole] = "status";
    roles[GanttDefines::GroupIdRole] = "groupId";
    return roles;
}

QVariant TaskModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_tasks.size()) return QVariant();

    const Task &task = m_tasks[index.row()];
    switch (role)
    {
        case GanttDefines::IdRole: return task.id;
        case GanttDefines::TitleRole: return task.title;
        case GanttDefines::ResponsibleRole: return task.responsible;
        case GanttDefines::StartDateRole: return task.startDate;
        case GanttDefines::EndDateRole: return task.endDate;
        case GanttDefines::StatusRole: return static_cast<int>(task.status);
        case GanttDefines::GroupIdRole: return task.groupId;
        default: return QVariant();
    }
}

QString TaskModel::generateId() const
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

int TaskModel::findTaskIndex(const QString& taskId) const
{
    for (int i = 0; i < m_tasks.size(); ++i)
    {
        if (m_tasks[i].id == taskId) return i;
    }
    return -1;
}

void TaskModel::addTask(const QString& groupId, const QString& title, const QString& responsible,
                        const QDate& startDate, const QDate& endDate)
{
    beginInsertRows(QModelIndex(), m_tasks.size(), m_tasks.size());
    Task task;
    task.id = generateId();
    task.title = title;
    task.responsible = responsible;
    task.startDate = startDate;
    task.endDate = endDate;
    task.status = GanttDefines::TaskStatus::Planned;
    task.groupId = groupId;
    m_tasks.append(task);
    endInsertRows();
    emit countChanged();
}

void TaskModel::addTaskWithId(const QString& taskId, const QString& groupId, const QString& title, const QString& responsible,
                        const QDate& startDate, const QDate& endDate, int status)
{
    beginInsertRows(QModelIndex(), m_tasks.size(), m_tasks.size());
    Task task;
    task.id = taskId;
    task.title = title;
    task.responsible = responsible;
    task.startDate = startDate;
    task.endDate = endDate;
    task.status = static_cast<GanttDefines::TaskStatus>(status);
    task.groupId = groupId;
    m_tasks.append(task);
    endInsertRows();
    emit countChanged();
}

void TaskModel::removeTask(const QString& taskId)
{
    int index = findTaskIndex(taskId);
    if (index >= 0) {
        beginRemoveRows(QModelIndex(), index, index);
        for (auto* entry : m_tasks[index].history) delete entry;
        m_tasks.removeAt(index);
        endRemoveRows();
        emit countChanged();
    }
}

void TaskModel::updateTask(const QString& taskId, const QString& title, const QString& responsible,
                           const QDate& startDate, const QDate& endDate, int status)
{
    int index = findTaskIndex(taskId);
    if (index >= 0)
    {
        Task& task = m_tasks[index];
        task.title = title;
        task.responsible = responsible;
        task.startDate = startDate;
        task.endDate = endDate;
        task.status = static_cast<GanttDefines::TaskStatus>(status);
        
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
    }
}

void TaskModel::updateTaskDates(const QString& taskId, const QDate& newStart, const QDate& newEnd, bool addToHistory) {
    int index = findTaskIndex(taskId);
    if (index >= 0 && newStart <= newEnd)
    {
        Task& task = m_tasks[index];
        
        if (addToHistory && (newStart > task.startDate || newEnd > task.endDate))
        {
            HistoryEntry* entry = new HistoryEntry(
                taskId, task.startDate, task.endDate, newStart, newEnd, this);
            task.history.append(entry);
        }
        
        task.startDate = newStart;
        task.endDate = newEnd;
        
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
        emit taskDatesChanged(taskId);
    }
}

void TaskModel::setTaskStatus(const QString& taskId, GanttDefines::TaskStatus status)
{
    int index = findTaskIndex(taskId);
    if (index >= 0)
    {
        m_tasks[index].status = status;
        if (status == GanttDefines::TaskStatus::Completed)
        {
            m_tasks[index].endDate = QDate::currentDate();
        }
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
    }
}

QStringList TaskModel::getTasksForGroup(const QString& groupId) const
{
    QStringList result;
    for (const auto& task : m_tasks)
    {
        if (task.groupId == groupId) result.append(task.id);
    }
    return result;
}

QVariantMap TaskModel::getTask(const QString& taskId) const
{
    int index = findTaskIndex(taskId);
    if (index >= 0) {
        const Task& task = m_tasks[index];
        QVariantMap map;
        map["id"] = task.id;
        map["title"] = task.title;
        map["responsible"] = task.responsible;
        map["startDate"] = task.startDate;
        map["endDate"] = task.endDate;
        map["status"] = static_cast<int>(task.status);
        map["groupId"] = task.groupId;
        return map;
    }
    return QVariantMap();
}

void TaskModel::moveTask(const QString& taskId, int newPosition)
{
    int oldIndex = findTaskIndex(taskId);
    if (oldIndex < 0 || oldIndex == newPosition || newPosition < 0 || newPosition >= m_tasks.size()) return;
    
    beginMoveRows(QModelIndex(), oldIndex, oldIndex, QModelIndex(), newPosition > oldIndex ? newPosition + 1 : newPosition);
    m_tasks.move(oldIndex, newPosition);
    endMoveRows();
}

void TaskModel::moveTaskToGroup(const QString& taskId, const QString& newGroupId, int newPosition)
{
    int index = findTaskIndex(taskId);
    if (index >= 0)
    {
        m_tasks[index].groupId = newGroupId;
        moveTask(taskId, newPosition);
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
    }
}

QList<HistoryEntry*> TaskModel::getTaskHistory(const QString& taskId) const
{
    int index = findTaskIndex(taskId);
    if (index >= 0) return m_tasks[index].history;
    return QList<HistoryEntry*>();
}

QVariantList TaskModel::getAllTasks() const
{
    QVariantList result;
    qDebug() << "TaskModel::getAllTasks() called, m_tasks.size()=" << m_tasks.size();
    for (const auto& task : m_tasks)
    {
        QVariantMap map;
        map["id"] = task.id;
        map["title"] = task.title;
        map["responsible"] = task.responsible;
        map["startDate"] = task.startDate;
        map["endDate"] = task.endDate;
        map["status"] = static_cast<int>(task.status);
        map["groupId"] = task.groupId;
        result.append(map);
        qDebug() << "  Task:" << task.title << task.startDate.toString("dd.MM.yyyy") << task.endDate.toString("dd.MM.yyyy");
    }
    return result;
}

void TaskModel::clear()
{
    beginResetModel();
    for (auto& task : m_tasks)
    {
        for (auto* entry : task.history) delete entry;
    }
    m_tasks.clear();
    endResetModel();
    emit countChanged();
}