#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include <QObject>
#include <QSet>
#include "ProjectData.h"
#include "ResourceManager.h"
#include "SettingsManager.h"
#include "ExportManager.h"
#include "TaskController.h"
#include "LocalGraphController.h"
#include "DependencyController.h"

class ProjectController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ProjectData* projectData READ get_projectData NOTIFY projectDataChanged)
    Q_PROPERTY(ResourceManager* resourceManager READ get_resourceManager CONSTANT)
    Q_PROPERTY(SettingsManager* settingsManager READ get_settingsManager CONSTANT)
    Q_PROPERTY(ExportManager* exportManager READ get_exportManager CONSTANT)
    Q_PROPERTY(TaskController* taskController READ get_taskController CONSTANT)
    Q_PROPERTY(LocalGraphController* localGraphController READ get_localGraphController CONSTANT)
    Q_PROPERTY(DependencyController* dependencyController READ get_dependencyController CONSTANT)
    Q_PROPERTY(bool inEditMode READ get_inEditMode WRITE set_InEditMode NOTIFY inEditModeChanged)

public:
    explicit ProjectController(QObject *parent = nullptr);

    ProjectData* get_projectData() const;
    ResourceManager* get_resourceManager() const;
    SettingsManager* get_settingsManager() const;
    ExportManager* get_exportManager() const;
    TaskController* get_taskController() const;
    LocalGraphController* get_localGraphController() const;
    DependencyController* get_dependencyController() const;

    bool get_inEditMode() const;
    void set_InEditMode(bool editMode);

    Q_INVOKABLE void notifyEditingLocked();
    Q_INVOKABLE void notifyTaskCompleted();

    Q_INVOKABLE void createNewProject(const QString& projectName, const QString& projectType, const QDate& startDate, const QString& filePath, const QStringList& selectedTaskGroups);
    Q_INVOKABLE void openProject(const QString& filePath);
    Q_INVOKABLE bool openLocalGraphFile(const QString& filePath);
    Q_INVOKABLE void saveProject();
    Q_INVOKABLE void saveProjectAs(const QString& filePath);
    Q_INVOKABLE void exportToPng(const QString& filePath);
    Q_INVOKABLE void exportToPdf(const QString& filePath);
    Q_INVOKABLE void notifyMilestoneCompleted();

signals:
    void inEditModeChanged();
    void projectLoaded();
    void projectSaved();
    void errorOccurred(const QString& message);
    void cascadeUpdateRequired(const QString& taskId);
    void projectDataChanged();
    void confirmRemoveTaskWithLocalGraph(const QString& taskId);

private:
    ProjectData* m_projectData;
    ResourceManager* m_resourceManager;
    SettingsManager* m_settingsManager;
    ExportManager* m_exportManager;
    
    TaskController* m_taskController;
    LocalGraphController* m_localGraphController;
    DependencyController* m_dependencyController;

    bool m_inEditMode;
};

#endif
