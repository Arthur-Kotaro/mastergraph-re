#ifndef GLOBALDEFINES_H
#define GLOBALDEFINES_H

#include <QString>
#include <QColor>
#include <QDate>

namespace GanttDefines {

enum class TaskStatus {
    Planned = 0,
    Completed,
    HasRisks,
    Blocked
};

enum class MilestoneStatus {
    Planned = 0,
    Completed,
    Rescheduled
};

enum class DependencyType {
    FinishToStart = 0
};

enum class ZoomLevel {
    Daily = 0,
    Weekly,
    Yearly
};

enum ModelRoles {
    IdRole = Qt::UserRole + 1,
    TitleRole,
    ResponsibleRole,
    StartDateRole,
    EndDateRole,
    StatusRole,
    GroupIdRole,
    ColorRole,
    DurationRole,
    HistoryRole
};

inline QColor getTaskStatusColor(TaskStatus status) {
    switch(status) {
        case TaskStatus::Planned:   return QColor(255, 255, 0);
        case TaskStatus::Completed: return QColor(0, 255, 0);
        case TaskStatus::HasRisks:  return QColor(255, 165, 0);
        case TaskStatus::Blocked:   return QColor(255, 0, 0);
        default: return QColor(200, 200, 200);
    }
}

inline QColor getMilestoneStatusColor(MilestoneStatus status) {
    switch(status) {
        case MilestoneStatus::Planned:    return QColor(255, 255, 0);
        case MilestoneStatus::Completed:  return QColor(0, 255, 0);
        case MilestoneStatus::Rescheduled: return QColor(128, 128, 128);
        default: return QColor(200, 200, 200);
    }
}

inline QString taskStatusToString(TaskStatus status) {
    switch(status) {
        case TaskStatus::Planned:   return "Запланировано";
        case TaskStatus::Completed: return "Выполнено";
        case TaskStatus::HasRisks:  return "Имеются риски";
        case TaskStatus::Blocked:   return "Блокировано";
        default: return "Неизвестно";
    }
}

inline TaskStatus stringToTaskStatus(const QString& str) {
    if (str == "Запланировано") return TaskStatus::Planned;
    if (str == "Выполнено") return TaskStatus::Completed;
    if (str == "Имеются риски") return TaskStatus::HasRisks;
    if (str == "Блокировано") return TaskStatus::Blocked;
    return TaskStatus::Planned;
}

} // namespace GanttDefines

#endif
