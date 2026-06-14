#include "MilestoneModel.h"
#include <QUuid>
#include <QDebug>
#include <algorithm>

#define DEBUG_MILESTONES

MilestoneModel::MilestoneModel(QObject *parent) : QAbstractListModel(parent) {}

int MilestoneModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_milestones.count();
}

QHash<int, QByteArray> MilestoneModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Qt::DisplayRole] = "abbreviation";
    roles[Qt::UserRole + 1] = "milestoneId";
    roles[Qt::UserRole + 2] = "fullName";
    roles[Qt::UserRole + 3] = "plannedDate";
    roles[Qt::UserRole + 4] = "actualDate";
    roles[Qt::UserRole + 5] = "status";
    roles[Qt::UserRole + 6] = "color";
    roles[Qt::UserRole + 7] = "rescheduleHistory";
    return roles;
}

QVariant MilestoneModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_milestones.size())
        return QVariant();

    const Milestone &ms = m_milestones[index.row()];
    switch (role)
    {
        case Qt::DisplayRole: return ms.abbreviation;
        case Qt::UserRole + 1: return ms.id;
        case Qt::UserRole + 2: return ms.fullName;
        case Qt::UserRole + 3: return ms.plannedDate;
        case Qt::UserRole + 4: return ms.actualDate;
        case Qt::UserRole + 5: return static_cast<int>(ms.status);
        case Qt::UserRole + 7: { QVariantList history; for (const QDate& d : ms.rescheduleHistory) history.append(d.toString("dd.MM.yyyy")); return history; }
        case Qt::UserRole + 6: return GanttDefines::getMilestoneStatusColor(ms.status);
        default: return QVariant();
    }
}

QString MilestoneModel::generateId() const
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

int MilestoneModel::findMilestoneIndex(const QString& milestoneId) const
{
    for (int i = 0; i < m_milestones.size(); ++i)
    {
        if (m_milestones[i].id == milestoneId)
            return i;
    }
    return -1;
}

void MilestoneModel::addMilestone(const QString& abbreviation, const QString& fullName, const QDate& plannedDate)
{
    beginInsertRows(QModelIndex(), m_milestones.size(), m_milestones.size());
    Milestone ms;
    ms.id = generateId();
    ms.abbreviation = abbreviation;
    ms.fullName = fullName;
    ms.plannedDate = plannedDate;
    ms.status = GanttDefines::MilestoneStatus::Planned;
    m_milestones.append(ms);
    endInsertRows();
    emit milestonesChanged();
}

void MilestoneModel::removeMilestone(const QString& milestoneId)
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0)
    {
        beginRemoveRows(QModelIndex(), index, index);
        m_milestones.removeAt(index);
        endRemoveRows();
        emit milestonesChanged();
    }
}

void MilestoneModel::setMilestoneCompleted(const QString& milestoneId)
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0)
    {
        for (int i = 0; i < index; ++i)
        {
            if (m_milestones[i].status != GanttDefines::MilestoneStatus::Completed)
            {
                qDebug() << "Cannot complete milestone - previous milestone not completed";
                return;
            }
        }
        m_milestones[index].status = GanttDefines::MilestoneStatus::Completed;
        m_milestones[index].actualDate = QDate::currentDate();
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
        emit milestoneStatusChanged(milestoneId);
        emit milestonesChanged();
    }
}

void MilestoneModel::rescheduleMilestone(const QString& milestoneId, const QDate& newDate)
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0 && m_milestones[index].status != GanttDefines::MilestoneStatus::Completed)
    {
        m_milestones[index].rescheduleHistory.append(m_milestones[index].plannedDate);
        m_milestones[index].plannedDate = newDate;
        m_milestones[index].status = GanttDefines::MilestoneStatus::Rescheduled;
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
        emit milestoneDateChanged(milestoneId);
        emit milestonesChanged();
    }
}

void MilestoneModel::addRescheduleHistory(const QString& milestoneId, const QDate& date)
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0)
    {
        m_milestones[index].rescheduleHistory.append(date);
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
        emit milestonesChanged();
    }
}

void MilestoneModel::setRescheduleHistory(const QString& milestoneId, const QVariantList& history)
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0)
    {
        m_milestones[index].rescheduleHistory.clear();
        for (const auto& h : history)
        {
            QDate d = QDate::fromString(h.toString(), "dd.MM.yyyy");
            if (d.isValid())
                m_milestones[index].rescheduleHistory.append(d);
        }
        QModelIndex modelIndex = createIndex(index, 0);
        emit dataChanged(modelIndex, modelIndex);
        emit milestonesChanged();
    }
}

QDate MilestoneModel::adjustToNextMonday(QDate date)
{
    int dayOfWeek = date.dayOfWeek(); // Qt: 1=пн, 6=сб, 7=вс
    if (dayOfWeek == 6)
    {
        return date.addDays(2);
    }
    else if (dayOfWeek == 7)
    {
        return date.addDays(1);
    }
    return date;
}

void MilestoneModel::loadFromTemplate(const QVariantList& templates, const QDate& projectStartDate) {
    beginResetModel();
    m_milestones.clear();

    qDebug() << "loadFromTemplate called, templates count:" << templates.size();

    for (const QVariant& item : templates)
    {
        QVariantMap tpl = item.toMap();
        Milestone ms;
        ms.id = generateId();
        ms.abbreviation = tpl["abbreviation"].toString();
        ms.fullName = tpl["m_name"].toString();
        ms.tooltip = tpl["tooltip"].toString();
        ms.weekOffset = tpl["m_week"].toInt();

        // Расчёт даты: projectStartDate + (weekOffset * 7) дней
        QDate plannedDate = projectStartDate.addDays(ms.weekOffset * 7);
        // Корректировка на понедельник если выпадает на выходной
        ms.plannedDate = adjustToNextMonday(plannedDate);

        ms.status = GanttDefines::MilestoneStatus::Planned;
        m_milestones.append(ms);

        qDebug() << "Added milestone:" << ms.abbreviation
        << "weekOffset:" << ms.weekOffset
        << "plannedDate:" << ms.plannedDate.toString("dd.MM.yyyy");
    }

    std::sort(m_milestones.begin(), m_milestones.end(), [](const Milestone& a, const Milestone& b)
              {
                  return a.plannedDate < b.plannedDate;
              });
    endResetModel();
    emit milestonesChanged();
    qDebug() << "loadFromTemplate completed, total milestones:" << m_milestones.size();
}

QVariantMap MilestoneModel::getMilestone(const QString& milestoneId) const
{
    int index = findMilestoneIndex(milestoneId);
    if (index >= 0)
    {
        const Milestone& ms = m_milestones[index];
        QVariantMap map;
        map["id"] = ms.id;
        map["abbreviation"] = ms.abbreviation;
        map["fullName"] = ms.fullName;
        map["plannedDate"] = ms.plannedDate;
        map["actualDate"] = ms.actualDate;
        QVariantList history;
        for (const QDate& d : ms.rescheduleHistory)
            history.append(d.toString("dd.MM.yyyy"));
        map["rescheduleHistory"] = history;
    qDebug() << "Milestone" << ms.abbreviation << "history count:" << history.size();
        map["status"] = static_cast<int>(ms.status);
        return map;
    }
    return QVariantMap();
}

QVariantList MilestoneModel::getAllMilestones() const
{
    QVariantList result;
    // qDebug() << "getAllMilestones called, count:" << m_milestones.size();
    for (const auto& ms : m_milestones)
    {
        QVariantMap map;
        map["milestoneId"] = ms.id;
        map["abbreviation"] = ms.abbreviation;
        map["fullName"] = ms.fullName;
        map["tooltip"] = ms.tooltip;
        map["plannedDate"] = ms.plannedDate;
        QVariantList history;
        for (const QDate& d : ms.rescheduleHistory)
            history.append(d.toString("dd.MM.yyyy"));
        map["rescheduleHistory"] = history;
    qDebug() << "Milestone" << ms.abbreviation << "history count:" << history.size();
        map["status"] = static_cast<int>(ms.status);
        map["actualDate"] = ms.actualDate;
        result.append(map);
        qDebug() << "  Milestone:" << ms.abbreviation << ms.plannedDate.toString("dd.MM.yyyy");
    }
    return result;
}

QDate MilestoneModel::getFirstMilestoneDate()
{
    if (m_milestones.isEmpty()) return QDate::currentDate();
    QDate first = m_milestones[0].plannedDate;
    for (const auto& ms : m_milestones) {
        if (ms.plannedDate < first) first = ms.plannedDate;
    }
    return first;
}

QDate MilestoneModel::getLastMilestoneDate()
{
    if (m_milestones.isEmpty())
    {
        // qDebug() << "getLastMilestoneDate: milestones is EMPTY!";
        return QDate::currentDate();
    }
    QDate last = m_milestones[0].plannedDate;
    for (const auto& ms : m_milestones)
    {
        if (ms.plannedDate > last) last = ms.plannedDate;
        // qDebug() << "  milestone:" << ms.abbreviation << ms.plannedDate.toString("dd.MM.yyyy");
    }
    // qDebug() << "getLastMilestoneDate returning:" << last.toString("dd.MM.yyyy");
    return last;
}

void MilestoneModel::clear()
{
    beginResetModel();
    m_milestones.clear();
    endResetModel();
    emit milestonesChanged();
}
