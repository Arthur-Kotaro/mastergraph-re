#ifndef PROJECTDATA_H
#define PROJECTDATA_H

#include <QObject>
#include <QDate>
#include <QDateTime>
#include <QString>
#include "TaskModel.h"
#include "GroupModel.h"
#include "MilestoneModel.h"
#include "DependencyModel.h"

class ProjectData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString projectName READ get_projectName WRITE set_ProjectName NOTIFY projectNameChanged)
    Q_PROPERTY(QString projectType READ get_projectType WRITE set_ProjectType NOTIFY projectTypeChanged)
    Q_PROPERTY(QDate startDate READ get_startDate WRITE set_StartDate NOTIFY startDateChanged)
    Q_PROPERTY(QDate endDate READ get_endDate NOTIFY endDateChanged)
    Q_PROPERTY(QString filePath READ get_filePath WRITE set_FilePath NOTIFY filePathChanged)
    Q_PROPERTY(bool modified READ get_modified WRITE set_Modified NOTIFY modifiedChanged)
    Q_PROPERTY(TaskModel* taskModel READ get_taskModel CONSTANT)
    Q_PROPERTY(GroupModel* groupModel READ get_groupModel CONSTANT)
    Q_PROPERTY(MilestoneModel* milestoneModel READ get_milestoneModel CONSTANT)
    Q_PROPERTY(DependencyModel* dependencyModel READ get_dependencyModel CONSTANT)

    Q_PROPERTY(QDateTime creationDateTime READ get_creationDateTime WRITE set_CreationDateTime NOTIFY creationDateTimeChanged)
    Q_PROPERTY(QDateTime lastModifiedDateTime READ get_lastModifiedDateTime WRITE set_LastModifiedDateTime NOTIFY lastModifiedDateTimeChanged)


public:
    explicit ProjectData(QObject *parent = nullptr);

    QString get_projectName() const;
    void set_ProjectName(const QString& name);

    QString get_projectType() const;
    void set_ProjectType(const QString& type);

    QDate get_startDate() const;
    void set_StartDate(const QDate& date);

    QDate get_endDate() const;
    void recalculateEndDate();

    QString get_filePath() const;
    void set_FilePath(const QString& path);

    QDateTime get_creationDateTime() const;
    void set_CreationDateTime(const QDateTime& dt);

    QDateTime get_lastModifiedDateTime() const;
    void set_LastModifiedDateTime(const QDateTime& dt);

    bool get_modified() const;
    void set_Modified(bool mod);

    TaskModel* get_taskModel() const;
    GroupModel* get_groupModel() const;
    MilestoneModel* get_milestoneModel() const;
    DependencyModel* get_dependencyModel() const;

    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariantMap toJson() const;
    Q_INVOKABLE bool fromJson(const QVariantMap& json);
    Q_INVOKABLE void updateLastModified();

signals:
    void projectNameChanged();
    void projectTypeChanged();
    void startDateChanged();
    void endDateChanged();
    void filePathChanged();
    void modifiedChanged();
    void dataCleared();
    void creationDateTimeChanged();
    void lastModifiedDateTimeChanged();

private:
    QString m_projectName;
    QString m_projectType;
    QDate m_startDate;
    QDate m_endDate;
    QString m_filePath;
    bool m_modified;
    QDateTime m_creationDateTime;
    QDateTime m_lastModifiedDateTime;

    TaskModel* m_taskModel;
    GroupModel* m_groupModel;
    MilestoneModel* m_milestoneModel;
    DependencyModel* m_dependencyModel;
};

#endif
