#include "ProjectData.h"

ProjectData::ProjectData(QObject *parent): QObject(parent), m_modified(false), m_creationDateTime(QDateTime::currentDateTime()), m_lastModifiedDateTime(QDateTime::currentDateTime())
{
    m_taskModel = new TaskModel(this);
    m_groupModel = new GroupModel(this);
    m_milestoneModel = new MilestoneModel(this);
    m_dependencyModel = new DependencyModel(this);
}

QString ProjectData::get_projectName() const { return m_projectName; }
void ProjectData::set_ProjectName(const QString& name)
{
    if (m_projectName != name)
    {
        m_projectName = name;
        emit projectNameChanged();
        set_Modified(true);
    }
}

QString ProjectData::get_projectType() const { return m_projectType; }
void ProjectData::set_ProjectType(const QString& type)
{
    if (m_projectType != type)
    {
        m_projectType = type;
        emit projectTypeChanged();
        set_Modified(true);
    }
}

QDate ProjectData::get_startDate() const { return m_startDate; }
void ProjectData::set_StartDate(const QDate& date)
{
    if (m_startDate != date)
    {
        m_startDate = date;
        emit startDateChanged();
        recalculateEndDate();
        set_Modified(true);
    }
}

QDate ProjectData::get_endDate() const { return m_endDate; }

void ProjectData::recalculateEndDate()
{
    QDate maxEnd = m_startDate;
    for (int i = 0; i < m_taskModel->rowCount(); ++i)
    {
        QModelIndex idx = m_taskModel->index(i);
        QDate taskEnd = idx.data(GanttDefines::EndDateRole).toDate();
        QDate forecastEnd = idx.data(GanttDefines::ForecastEndRole).toDate();
        if (taskEnd.isValid() && taskEnd > maxEnd) maxEnd = taskEnd;
        if (forecastEnd.isValid() && forecastEnd > maxEnd) maxEnd = forecastEnd;
    }
    if (m_endDate != maxEnd)
    {
        m_endDate = maxEnd;
        emit endDateChanged();
    }
}

QString ProjectData::get_filePath() const { return m_filePath; }
void ProjectData::set_FilePath(const QString& path)
{
    if (m_filePath != path)
    {
        m_filePath = path;
        emit filePathChanged();
    }
}

bool ProjectData::get_modified() const { return m_modified; }
void ProjectData::set_Modified(bool mod)
{
    if (m_modified != mod)
    {
        m_modified = mod;
        emit modifiedChanged();
    }
}

QDateTime ProjectData::get_creationDateTime() const { return m_creationDateTime; }
void ProjectData::set_CreationDateTime(const QDateTime& dt)
{
    if (m_creationDateTime != dt)
    {
        m_creationDateTime = dt;
        emit creationDateTimeChanged();
    }
}

QDateTime ProjectData::get_lastModifiedDateTime() const { return m_lastModifiedDateTime; }
void ProjectData::set_LastModifiedDateTime(const QDateTime& dt)
{
    if (m_lastModifiedDateTime != dt)
    {
        m_lastModifiedDateTime = dt;
        emit lastModifiedDateTimeChanged();
    }
}

void ProjectData::updateLastModified()
{
    set_LastModifiedDateTime(QDateTime::currentDateTime());
    set_Modified(false);
}

void ProjectData::refreshAll()
{
    emit m_taskModel->countChanged();
    emit m_groupModel->countChanged();
    emit m_milestoneModel->milestonesChanged();
    if (m_taskModel->rowCount() > 0)
        emit m_taskModel->dataChanged(m_taskModel->index(0), m_taskModel->index(m_taskModel->rowCount() - 1));
    if (m_groupModel->rowCount() > 0)
        emit m_groupModel->dataChanged(m_groupModel->index(0), m_groupModel->index(m_groupModel->rowCount() - 1));
}

TaskModel* ProjectData::get_taskModel() const { return m_taskModel; }
GroupModel* ProjectData::get_groupModel() const { return m_groupModel; }
MilestoneModel* ProjectData::get_milestoneModel() const { return m_milestoneModel; }
DependencyModel* ProjectData::get_dependencyModel() const { return m_dependencyModel; }

void ProjectData::clear()
{
    m_taskModel->clear();
    m_groupModel->clear();
    m_milestoneModel->clear();
    m_dependencyModel->clear();
    m_projectName.clear();
    m_projectType.clear();
    m_startDate = QDate();
    m_endDate = QDate();
    m_filePath.clear();

    m_creationDateTime = QDateTime();
    m_lastModifiedDateTime = QDateTime();

    set_Modified(false);
    emit dataCleared();
}

QVariantMap ProjectData::toJson() const
{
    QVariantMap result;
    result["projectName"] = m_projectName;
    result["projectType"] = m_projectType;
    result["startDate"] = m_startDate.toString("dd.MM.yyyy");
    result["creationDateTime"] = m_creationDateTime.toString("dd.MM.yyyy hh:mm:ss");
    result["lastModifiedDateTime"] = m_lastModifiedDateTime.toString("dd.MM.yyyy hh:mm:ss");

    QVariantList groups;
    for (int i = 0; i < m_groupModel->rowCount(); ++i)
    {
        QVariantMap group;
        QModelIndex idx = m_groupModel->index(i);
        group["id"] = idx.data(Qt::UserRole + 1).toString();
        group["name"] = idx.data(Qt::DisplayRole).toString();
        group["expanded"] = idx.data(Qt::UserRole + 2).toBool();
        groups.append(group);
    }
    result["groups"] = groups;

    QVariantList tasks;
    for (int i = 0; i < m_taskModel->rowCount(); ++i)
    {
        QModelIndex idx = m_taskModel->index(i);
        QVariantMap task;
        task["id"] = idx.data(GanttDefines::IdRole).toString();
        task["title"] = idx.data(GanttDefines::TitleRole).toString();
        task["responsible"] = idx.data(GanttDefines::ResponsibleRole).toString();

        QDate startDate = idx.data(GanttDefines::StartDateRole).toDate();
        QDate endDate = idx.data(GanttDefines::EndDateRole).toDate();
        QDate forecastStart = idx.data(GanttDefines::ForecastStartRole).toDate();
        QDate forecastEnd = idx.data(GanttDefines::ForecastEndRole).toDate();
        int status = idx.data(GanttDefines::StatusRole).toInt();

        if (startDate.isValid()) task["startDate"] = startDate.toString("dd.MM.yyyy");
        if (endDate.isValid())   task["endDate"] = endDate.toString("dd.MM.yyyy");

        task["status"] = status;
        task["groupId"] = idx.data(GanttDefines::GroupIdRole).toString();
        task["comment"] = idx.data(GanttDefines::CommentRole).toString();
        task["dateHistory"] = m_taskModel->getTask(task["id"].toString())["dateHistory"].toList();

        bool isCompleted = (status == static_cast<int>(GanttDefines::TaskStatus::Completed));
        bool forecastDiffers = (forecastStart != startDate) || (forecastEnd != endDate);
        if (!isCompleted && forecastStart.isValid() && forecastEnd.isValid() && forecastDiffers)
        {
            task["forecastStart"] = forecastStart.toString("dd.MM.yyyy");
            task["forecastEnd"] = forecastEnd.toString("dd.MM.yyyy");
        }

        int progressCurrent = idx.data(GanttDefines::ProgressCurrentRole).toInt();
        int progressTotal = idx.data(GanttDefines::ProgressTotalRole).toInt();
        if (progressCurrent >= 0 && progressTotal > 0)
        {
            task["progressCurrent"] = progressCurrent;
            task["progressTotal"] = progressTotal;
        }

        int lgs = idx.data(GanttDefines::LocalGraphStateRole).toInt();
        if (lgs != static_cast<int>(GanttDefines::LocalGraphState::NotRequired))
        {
            task["localGraphState"] = GanttDefines::localGraphStateToString(
                static_cast<GanttDefines::LocalGraphState>(lgs));
        }

        tasks.append(task);
    }
    result["tasks"] = tasks;

    QVariantList milestones;
    for (int i = 0; i < m_milestoneModel->rowCount(); ++i)
    {
        QModelIndex idx = m_milestoneModel->index(i);
        QVariantMap ms;
        ms["id"] = idx.data(Qt::UserRole + 1).toString();
        ms["abbreviation"] = idx.data(Qt::DisplayRole).toString();
        ms["fullName"] = idx.data(Qt::UserRole + 2).toString();
        ms["plannedDate"] = idx.data(Qt::UserRole + 3).toDate().toString("dd.MM.yyyy");
        ms["actualDate"] = idx.data(Qt::UserRole + 4).toDate().toString("dd.MM.yyyy");
        ms["status"] = idx.data(Qt::UserRole + 5).toInt();
        ms["rescheduleHistory"] = idx.data(Qt::UserRole + 7).toList();
        milestones.append(ms);
    }
    result["milestones"] = milestones;

    QVariantList dependencies;
    for (int i = 0; i < m_dependencyModel->rowCount(); ++i)
    {
        QModelIndex idx = m_dependencyModel->index(i);
        QVariantMap dep;
        dep["id"] = idx.data(Qt::UserRole + 1).toString();
        dep["predecessorId"] = idx.data(Qt::UserRole + 2).toString();
        dep["successorId"] = idx.data(Qt::UserRole + 3).toString();
        dep["type"] = idx.data(Qt::UserRole + 4).toInt();
        dependencies.append(dep);
    }
    result["dependencies"] = dependencies;

    return result;
}

bool ProjectData::fromJson(const QVariantMap& json)
{
    clear();

    set_ProjectName(json["projectName"].toString());
    set_ProjectType(json["projectType"].toString());
    m_startDate = QDate::fromString(json["startDate"].toString(), "dd.MM.yyyy");

    m_creationDateTime = QDateTime::fromString(json["creationDateTime"].toString(), "dd.MM.yyyy hh:mm:ss");
    m_lastModifiedDateTime = QDateTime::fromString(json["lastModifiedDateTime"].toString(), "dd.MM.yyyy hh:mm:ss");

    QVariantList groups = json["groups"].toList();
    for (const auto& g : groups)
    {
        QVariantMap groupMap = g.toMap();
        m_groupModel->addGroupWithId(groupMap["id"].toString(), groupMap["name"].toString());
    }

    QVariantList tasks = json["tasks"].toList();
    for (const auto& t : tasks)
    {
        QVariantMap taskMap = t.toMap();
        QDate startDate = QDate::fromString(taskMap["startDate"].toString(), "dd.MM.yyyy");
        QDate endDate = QDate::fromString(taskMap["endDate"].toString(), "dd.MM.yyyy");
        QDate forecastStart = QDate::fromString(taskMap["forecastStart"].toString(), "dd.MM.yyyy");
        QDate forecastEnd = QDate::fromString(taskMap["forecastEnd"].toString(), "dd.MM.yyyy");
        int status = taskMap["status"].toInt();
        int progressCurrent = taskMap.contains("progressCurrent") ? taskMap["progressCurrent"].toInt() : -1;
        int progressTotal = taskMap.contains("progressTotal") ? taskMap["progressTotal"].toInt() : -1;
        GanttDefines::LocalGraphState lgs = GanttDefines::stringToLocalGraphState(
            taskMap["localGraphState"].toString());

        QString taskId = taskMap["id"].toString();
        QString groupId = taskMap["groupId"].toString();

        m_taskModel->addTaskWithId(taskId, groupId,
                                   taskMap["title"].toString(),
                                   taskMap["responsible"].toString(),
                                   startDate, endDate,
                                   forecastStart, forecastEnd,
                                   status,
                                   progressCurrent, progressTotal,
                                   static_cast<int>(lgs));

        if (!taskMap["comment"].toString().isEmpty())
            m_taskModel->setTaskComment(taskId, taskMap["comment"].toString());

        QVariantList dateHistory = taskMap["dateHistory"].toList();
        for (const auto& dh : dateHistory)
        {
            QVariantMap dates = dh.toMap();
            QDate oldStart = QDate::fromString(dates["start"].toString(), "dd.MM.yyyy");
            QDate oldEnd = QDate::fromString(dates["end"].toString(), "dd.MM.yyyy");
            if (oldStart.isValid() && oldEnd.isValid())
                m_taskModel->addDateHistory(taskId, oldStart, oldEnd);
        }
    }
    emit m_taskModel->countChanged();
    emit m_groupModel->countChanged();

    QVariantList milestones = json["milestones"].toList();
    for (const auto& m : milestones)
    {
        QVariantMap msMap = m.toMap();
        QDate plannedDate = QDate::fromString(msMap["plannedDate"].toString(), "dd.MM.yyyy");
        m_milestoneModel->addMilestone(msMap["abbreviation"].toString(), msMap["fullName"].toString(), plannedDate);

        int lastIdx = m_milestoneModel->rowCount() - 1;
        QString msId = m_milestoneModel->data(m_milestoneModel->index(lastIdx), Qt::UserRole + 1).toString();

        int status = msMap["status"].toInt();
        if (status == 1)
        {
            m_milestoneModel->setMilestoneCompleted(msId);
        }

        QVariantList history = msMap["rescheduleHistory"].toList();
        if (!history.isEmpty())
        {
            m_milestoneModel->setRescheduleHistory(msId, history);
        }
    }

    QVariantList dependencies = json["dependencies"].toList();
    for (const auto& d : dependencies)
    {
        QVariantMap depMap = d.toMap();
        m_dependencyModel->addDependency(depMap["predecessorId"].toString(), depMap["successorId"].toString());
    }
    recalculateEndDate();
    set_Modified(false);
    return true;
}

QDate ProjectData::getEarliestDate() const
{
    QDate earliest = QDate::currentDate();

    for (int i = 0; i < m_milestoneModel->rowCount(); ++i)
    {
        QModelIndex idx = m_milestoneModel->index(i);
        QDate plannedDate = idx.data(Qt::UserRole + 3).toDate();
        if (plannedDate.isValid() && plannedDate < earliest)
            earliest = plannedDate;

        QVariantList history = idx.data(Qt::UserRole + 7).toList();
        for (const auto& h : history)
        {
            QDate d = QDate::fromString(h.toString(), "dd.MM.yyyy");
            if (d.isValid() && d < earliest)
                earliest = d;
        }
    }

    for (int i = 0; i < m_taskModel->rowCount(); ++i)
    {
        QModelIndex idx = m_taskModel->index(i);

        QDate startDate = idx.data(GanttDefines::StartDateRole).toDate();
        if (startDate.isValid() && startDate < earliest)
            earliest = startDate;

        QDate forecastStart = idx.data(GanttDefines::ForecastStartRole).toDate();
        if (forecastStart.isValid() && forecastStart < earliest)
            earliest = forecastStart;

        QString taskId = idx.data(GanttDefines::IdRole).toString();
        QVariantMap task = m_taskModel->getTask(taskId);
        QVariantList dateHistory = task["dateHistory"].toList();
        for (const auto& dh : dateHistory)
        {
            QVariantMap dates = dh.toMap();
            QDate oldStart = QDate::fromString(dates["start"].toString(), "dd.MM.yyyy");
            if (oldStart.isValid() && oldStart < earliest)
                earliest = oldStart;
        }
    }

    return earliest;
}

QDate ProjectData::getLatestDate() const
{
    QDate latest = QDate(1900, 1, 1);

    for (int i = 0; i < m_milestoneModel->rowCount(); ++i)
    {
        QModelIndex idx = m_milestoneModel->index(i);
        QDate plannedDate = idx.data(Qt::UserRole + 3).toDate();
        if (plannedDate.isValid() && plannedDate > latest)
            latest = plannedDate;

        QVariantList history = idx.data(Qt::UserRole + 7).toList();
        for (const auto& h : history)
        {
            QDate d = QDate::fromString(h.toString(), "dd.MM.yyyy");
            if (d.isValid() && d > latest)
                latest = d;
        }
    }

    for (int i = 0; i < m_taskModel->rowCount(); ++i)
    {
        QModelIndex idx = m_taskModel->index(i);

        QDate endDate = idx.data(GanttDefines::EndDateRole).toDate();
        if (endDate.isValid() && endDate > latest)
            latest = endDate;

        QDate forecastEnd = idx.data(GanttDefines::ForecastEndRole).toDate();
        if (forecastEnd.isValid() && forecastEnd > latest)
            latest = forecastEnd;

        QString taskId = idx.data(GanttDefines::IdRole).toString();
        QVariantMap task = m_taskModel->getTask(taskId);
        QVariantList dateHistory = task["dateHistory"].toList();
        for (const auto& dh : dateHistory)
        {
            QVariantMap dates = dh.toMap();
            QDate oldEnd = QDate::fromString(dates["end"].toString(), "dd.MM.yyyy");
            if (oldEnd.isValid() && oldEnd > latest)
                latest = oldEnd;
        }
    }

    return latest;
}
