#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include <QObject>
#include "ProjectData.h"
#include "ResourceManager.h"
#include "SettingsManager.h"
#include "ExportManager.h"

class ProjectController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ProjectData* projectData READ get_projectData CONSTANT)
    Q_PROPERTY(ResourceManager* resourceManager READ get_resourceManager CONSTANT)
    Q_PROPERTY(SettingsManager* settingsManager READ get_settingsManager CONSTANT)
    Q_PROPERTY(ExportManager* exportManager READ get_exportManager CONSTANT)
    Q_PROPERTY(bool inEditMode READ get_inEditMode WRITE set_InEditMode NOTIFY inEditModeChanged)

public:
    explicit ProjectController(QObject *parent = nullptr);

    ProjectData* get_projectData() const;
    ResourceManager* get_resourceManager() const;
    SettingsManager* get_settingsManager() const;
    ExportManager* get_exportManager() const;

    bool get_inEditMode() const;
    void set_InEditMode(bool editMode);

    Q_INVOKABLE void createNewProject(const QString& projectName, const QString& projectType,
                                      const QDate& startDate, const QString& filePath,
                                      const QStringList& selectedTaskGroups);
    Q_INVOKABLE void openProject(const QString& filePath);
    Q_INVOKABLE void saveProject();
    Q_INVOKABLE void saveProjectAs(const QString& filePath);
    Q_INVOKABLE void exportToPng(const QString& filePath, int width, int height);
    Q_INVOKABLE void exportToPdf(const QString& filePath);

    Q_INVOKABLE void addTask(const QString& groupId, const QString& title,
                             const QString& responsible, const QDate& startDate, const QDate& endDate);
    Q_INVOKABLE void removeTask(const QString& taskId);
    Q_INVOKABLE void updateTaskDates(const QString& taskId, const QDate& newStart, const QDate& newEnd);
    Q_INVOKABLE void addDependency(const QString& predecessorId, const QString& successorId);
    Q_INVOKABLE void removeDependency(const QString& dependencyId);

signals:
    void inEditModeChanged();
    void projectLoaded();
    void projectSaved();
    void errorOccurred(const QString& message);
    void cascadeUpdateRequired(const QString& taskId);

private slots:
    void onTaskDatesChanged(const QString& taskId);
    void updateDependentTasks(const QString& taskId, const QDate& newEndDate);

private:
    ProjectData* m_projectData;
    ResourceManager* m_resourceManager;
    SettingsManager* m_settingsManager;
    ExportManager* m_exportManager;
    bool m_inEditMode;
    QSet<QString> m_updatingTasks;
};

#endif
