#ifndef TASKMODEL_H
#define TASKMODEL_H

#include <QAbstractListModel>
#include <QDate>
#include <QList>
#include "GlobalDefines.h"
#include "HistoryEntry.h"

class TaskModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    struct Task {
        QString id;
        QString title;
        QString responsible;
        QDate startDate;
        QDate endDate;
        GanttDefines::TaskStatus status;
        QString groupId;
        QList<HistoryEntry*> history;
    };

    explicit TaskModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addTask(const QString& groupId, const QString& title, const QString& responsible,
                             const QDate& startDate, const QDate& endDate);
    Q_INVOKABLE void removeTask(const QString& taskId);
    Q_INVOKABLE void updateTask(const QString& taskId, const QString& title, const QString& responsible,
                                const QDate& startDate, const QDate& endDate, int status);
    Q_INVOKABLE void updateTaskDates(const QString& taskId, const QDate& newStart, const QDate& newEnd, bool addToHistory = true);
    Q_INVOKABLE void setTaskStatus(const QString& taskId, GanttDefines::TaskStatus status);
    Q_INVOKABLE QStringList getTasksForGroup(const QString& groupId) const;
    Q_INVOKABLE QVariantMap getTask(const QString& taskId) const;
    Q_INVOKABLE void moveTask(const QString& taskId, int newPosition);
    Q_INVOKABLE void moveTaskToGroup(const QString& taskId, const QString& newGroupId, int newPosition);
    Q_INVOKABLE QList<HistoryEntry*> getTaskHistory(const QString& taskId) const;
    Q_INVOKABLE QVariantList getAllTasks() const;

    void clear();

signals:
    void countChanged();
    void taskDatesChanged(const QString& taskId);

private:
    QList<Task> m_tasks;
    QString generateId() const;
    int findTaskIndex(const QString& taskId) const;
};

#endif
