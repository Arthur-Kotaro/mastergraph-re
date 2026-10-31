#include "ProjectController.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

ProjectController::ProjectController(QObject *parent): QObject(parent), m_projectData(nullptr), m_inEditMode(false)
{
    m_projectData = new ProjectData(this);
    m_resourceManager = new ResourceManager(this);
    m_settingsManager = new SettingsManager(this);
    m_exportManager = new ExportManager(this);

    m_taskController = new TaskController(m_projectData, m_settingsManager, this);
    m_localGraphController = new LocalGraphController(m_projectData, m_resourceManager, m_settingsManager, this);
    m_dependencyController = new DependencyController(m_projectData, m_settingsManager, this);

    m_resourceManager->setResourcesPath(m_settingsManager->resourcesPath());

    // Проброс сигналов ошибок
    connect(m_taskController, &TaskController::errorOccurred, this, &ProjectController::errorOccurred);
    connect(m_localGraphController, &LocalGraphController::errorOccurred, this, &ProjectController::errorOccurred);
    connect(m_dependencyController, &DependencyController::errorOccurred, this, &ProjectController::errorOccurred);
    connect(m_taskController, &TaskController::confirmRemoveTaskWithLocalGraph, this, &ProjectController::confirmRemoveTaskWithLocalGraph);
}

ProjectData* ProjectController::get_projectData() const { return m_projectData; }
ResourceManager* ProjectController::get_resourceManager() const { return m_resourceManager; }
SettingsManager* ProjectController::get_settingsManager() const { return m_settingsManager; }
ExportManager* ProjectController::get_exportManager() const { return m_exportManager; }
TaskController* ProjectController::get_taskController() const { return m_taskController; }
LocalGraphController* ProjectController::get_localGraphController() const { return m_localGraphController; }
DependencyController* ProjectController::get_dependencyController() const { return m_dependencyController; }

bool ProjectController::get_inEditMode() const { return m_inEditMode; }
void ProjectController::set_InEditMode(bool editMode)
{
    if (m_inEditMode != editMode) {
        m_inEditMode = editMode;
        emit inEditModeChanged();
    }
}

void ProjectController::notifyEditingLocked() { emit errorOccurred("Редактирование заблокировано"); }
void ProjectController::notifyTaskCompleted() { emit errorOccurred("Редактирование завершённых задач запрещено"); }

void ProjectController::createNewProject(const QString& projectName, const QString& projectType,
                                         const QDate& startDate, const QString& filePath, const QStringList& selectedTaskGroups)
{
    m_projectData->clear();
    m_projectData->set_ProjectName(projectName);
    m_projectData->set_ProjectType(projectType);
    m_projectData->set_StartDate(startDate);
    m_projectData->set_FilePath(filePath);

    m_projectData->set_CreationDateTime(QDateTime::currentDateTime());
    m_projectData->set_LastModifiedDateTime(QDateTime::currentDateTime());

    QVariantList typologies = m_resourceManager->loadTypologies();
    QVariantMap selectedTypology;
    for (const auto& t : typologies) {
        QVariantMap map = t.toMap();
        if (map["typology_name"].toString() == projectType) { selectedTypology = map; break; }
    }

    m_projectData->get_milestoneModel()->loadFromTemplate(selectedTypology["milestones"].toList(), startDate);

    QVariantList taskGroups = m_resourceManager->loadTaskGroups();
    for (const auto& groupData : taskGroups) {
        QVariantMap groupMap = groupData.toMap();
        QString groupName = groupMap["name"].toString();
        if (selectedTaskGroups.isEmpty() || selectedTaskGroups.contains(groupName))
            m_projectData->get_groupModel()->addGroup(groupName);
    }

    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(false);
    saveProject();
    set_InEditMode(true);
}

void ProjectController::openProject(const QString& filePath)
{
    QVariantMap projectData = m_resourceManager->loadProjectFromFile(filePath);
    if (projectData.isEmpty()) { emit errorOccurred("Не удалось загрузить проект"); return; }

    if (!m_projectData->fromJson(projectData)) {
        QString logPath = filePath + ".validation.log";
        QFile logFile(logPath);
        if (logFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&logFile);
            out << "Валидация проекта не пройдена: " << filePath << "\n\n";
            for (const QString& err : m_projectData->getValidationErrors()) out << "- " << err << "\n";
            logFile.close();
        }
        emit errorOccurred("Файл проекта повреждён. Подробности в " + logPath);
        return;
    }

    m_projectData->set_FilePath(filePath);
    m_localGraphController->refreshAllLocalGraphForecasts(); // Примечание: метод private, нужно сделать public или Q_INVOKABLE
    m_projectData->set_Modified(false);
    set_InEditMode(true);
    emit projectLoaded();
    m_projectData->refreshAll();
}

bool ProjectController::openLocalGraphFile(const QString& filePath)
{
    QVariantMap projectData = m_resourceManager->loadProjectFromFile(filePath);
    if (projectData.isEmpty()) { emit errorOccurred("Не удалось загрузить локальный график"); return false; }

    if (!m_projectData->fromJson(projectData)) {
        QString logPath = filePath + ".validation.log";
        QFile logFile(logPath);
        if (logFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&logFile);
            out << "Валидация локального графика не пройдена: " << filePath << "\n\n";
            for (const QString& err : m_projectData->getValidationErrors()) out << "- " << err << "\n";
            logFile.close();
        }
        emit errorOccurred("Файл локального графика повреждён. Подробности в " + logPath);
        return false;
    }

    m_projectData->set_FilePath(filePath);
    m_projectData->set_Modified(false);
    set_InEditMode(true);
    emit projectLoaded();
    m_projectData->refreshAll();
    return true;
}

void ProjectController::saveProject()
{
    if (m_projectData->get_filePath().isEmpty()) { emit errorOccurred("Путь к файлу не указан"); return; }
    QVariantMap data = m_projectData->toJson();
    if (m_resourceManager->saveProjectToFile(data, m_projectData->get_filePath())) {
        m_projectData->set_Modified(false);
        m_projectData->updateLastModified();
        emit projectSaved();
    } else {
        emit errorOccurred("Ошибка сохранения проекта");
    }
}

void ProjectController::saveProjectAs(const QString& filePath)
{
    m_projectData->set_FilePath(filePath);
    saveProject();
}

void ProjectController::exportToPng(const QString& filePath) { m_exportManager->exportToPng(m_projectData, filePath); }
void ProjectController::exportToPdf(const QString& filePath) { m_exportManager->exportToPdf(m_projectData, filePath, QDate::currentDate()); }

void ProjectController::notifyMilestoneCompleted()
{
    emit errorOccurred("Перенос пройденной вехи запрещён");
}
