#include "ProjectController.h"
#include <QDebug>
#include <QFile>
#include <QDir>

ProjectController::ProjectController(QObject *parent): QObject(parent), m_inEditMode(false)
{
    m_projectData = new ProjectData(this);
    m_resourceManager = new ResourceManager(this);
    m_settingsManager = new SettingsManager(this);
    m_exportManager = new ExportManager(this);
    
    m_resourceManager->setResourcesPath(m_settingsManager->resourcesPath());
    
    connect(m_projectData->get_taskModel(), &TaskModel::taskDatesChanged,
            this, &ProjectController::onTaskDatesChanged);
}

ProjectData* ProjectController::get_projectData() const { return m_projectData; }
ResourceManager* ProjectController::get_resourceManager() const { return m_resourceManager; }
SettingsManager* ProjectController::get_settingsManager() const { return m_settingsManager; }
ExportManager* ProjectController::get_exportManager() const { return m_exportManager; }

bool ProjectController::get_inEditMode() const { return m_inEditMode; }
void ProjectController::set_InEditMode(bool editMode)
{
    if (m_inEditMode != editMode)
    {
        m_inEditMode = editMode;
        emit inEditModeChanged();
    }
}

void ProjectController::createNewProject(const QString& projectName, const QString& projectType,
                                         const QDate& startDate, const QString& filePath,
                                         const QStringList& selectedTaskGroups)
{
    qDebug() << "Creating new project:" << projectName << "at" << filePath;
    
    m_projectData->clear();
    m_projectData->set_ProjectName(projectName);
    m_projectData->set_ProjectType(projectType);
    m_projectData->set_StartDate(startDate);
    m_projectData->set_FilePath(filePath);
    

    m_projectData->set_CreationDateTime(QDateTime::currentDateTime());
    m_projectData->set_LastModifiedDateTime(QDateTime::currentDateTime());

    // Загружаем вехи из выбранной типологии
    QVariantList typologies = m_resourceManager->loadTypologies();
    QVariantMap selectedTypology;
    for (const auto& t : typologies)
    {
        QVariantMap map = t.toMap();
        if (map["typology_name"].toString() == projectType)
        {
            selectedTypology = map;
            break;
        }
    }

    QVariantList milestones = selectedTypology["milestones"].toList();
    m_projectData->get_milestoneModel()->loadFromTemplate(milestones, startDate);
    
    // Загружаем группы задач
    QVariantList taskGroups = m_resourceManager->loadTaskGroups();
    for (const auto& groupData : taskGroups)
    {
        QVariantMap groupMap = groupData.toMap();
        QString groupName = groupMap["name"].toString();
        if (selectedTaskGroups.isEmpty() || selectedTaskGroups.contains(groupName))
        {
            m_projectData->get_groupModel()->addGroup(groupName);
            qDebug() << "Added group:" << groupName;
        }
    }
    
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(false);
    
    // Сохраняем файл
    saveProject();
    set_InEditMode(true);
}

void ProjectController::openProject(const QString& filePath)
{
    QVariantMap projectData = m_resourceManager->loadProjectFromFile(filePath);
    if (projectData.isEmpty())
    {
        emit errorOccurred("Не удалось загрузить проект");
        return;
    }
    
    if (!m_projectData->fromJson(projectData))
    {
        emit errorOccurred("Ошибка загрузки данных проекта");
    qDebug() << "Project loaded successfully. Groups:" << m_projectData->get_groupModel()->rowCount() << "Tasks:" << m_projectData->get_taskModel()->rowCount() << "Milestones:" << m_projectData->get_milestoneModel()->rowCount();
        return;
    }
    
    m_projectData->set_FilePath(filePath);
    m_projectData->set_Modified(false);
    set_InEditMode(true);
    emit projectLoaded();
    m_projectData->refreshAll();
}

void ProjectController::saveProject()
{
    if (m_projectData->get_filePath().isEmpty())
    {
        emit errorOccurred("Путь к файлу не указан");
        qDebug() << "saveProject: filePath is EMPTY!";
        return;
    }

    qDebug() << "saveProject: filePath = " << m_projectData->get_filePath();

    QVariantMap data = m_projectData->toJson();
    if (m_resourceManager->saveProjectToFile(data, m_projectData->get_filePath()))
    {
        m_projectData->set_Modified(false);
        m_projectData->updateLastModified();
        emit projectSaved();
        qDebug() << "Project saved to:" << m_projectData->get_filePath();
    }
    else
    {
        emit errorOccurred("Ошибка сохранения проекта");
        qDebug() << "saveProject: FAILED to save to:" << m_projectData->get_filePath();
    }
}

void ProjectController::saveProjectAs(const QString& filePath)
{
    m_projectData->set_FilePath(filePath);
    saveProject();
}

void ProjectController::exportToPng(const QString& filePath, int width, int height)
{
    m_exportManager->exportToPng(m_projectData, filePath, width, height);
}

void ProjectController::exportToPdf(const QString& filePath)
{
    m_exportManager->exportToPdf(m_projectData, filePath, QDate::currentDate());
}

void ProjectController::addTask(const QString& groupId, const QString& title,
                                const QString& responsible, const QDate& startDate, const QDate& endDate)
{
    if (false && m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    m_projectData->get_taskModel()->addTask(groupId, title, responsible, startDate, endDate);
    QString newTaskId = m_projectData->get_taskModel()->data(m_projectData->get_taskModel()->index(m_projectData->get_taskModel()->rowCount() - 1), GanttDefines::IdRole).toString();
    m_projectData->get_groupModel()->addTaskToGroup(groupId, newTaskId);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
    qDebug() << "Task added:" << title << "to group:" << groupId;
}

void ProjectController::removeTask(const QString& taskId)
{
    qDebug() << "Removing task:" << taskId;
    if (false && m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    m_projectData->get_dependencyModel()->removeDependenciesForTask(taskId);
    m_projectData->get_taskModel()->removeTask(taskId);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::updateTaskDates(const QString& taskId, const QDate& newStart, const QDate& newEnd)
{
    if (false && m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    
    if (newStart > newEnd)
    {
        emit errorOccurred("Дата завершения не может быть раньше даты начала");
        return;
    }
    
    m_projectData->get_taskModel()->updateTaskDates(taskId, newStart, newEnd,
        m_settingsManager->tracingEnabled());
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::addDependency(const QString& predecessorId, const QString& successorId)
{
    if (false && m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    
    if (!m_projectData->get_dependencyModel()->addDependency(predecessorId, successorId))
    {
        emit errorOccurred("Невозможно создать зависимость (циклическая или уже существует)");
    }
    else
    {
        m_projectData->set_Modified(true);
    }
}

void ProjectController::removeDependency(const QString& dependencyId)
{
    if (false && m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    m_projectData->get_dependencyModel()->removeDependency(dependencyId);
    m_projectData->set_Modified(true);
}

void ProjectController::onTaskDatesChanged(const QString& taskId)
{
    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    QDate newEndDate = task["endDate"].toDate();
    updateDependentTasks(taskId, newEndDate);
}

void ProjectController::updateDependentTasks(const QString& taskId, const QDate& newEndDate)
{
    if (m_updatingTasks.contains(taskId)) return;
    m_updatingTasks.insert(taskId);
    
    QStringList successors = m_projectData->get_dependencyModel()->getSuccessors(taskId);
    for (const QString& successorId : successors)
    {
        QVariantMap successor = m_projectData->get_taskModel()->getTask(successorId);
        QDate successorStart = successor["startDate"].toDate();
        QDate successorEnd = successor["endDate"].toDate();
        int duration = successorStart.daysTo(successorEnd);
        
        if (successorStart < newEndDate)
        {
            QDate newSuccessorStart = newEndDate;
            QDate newSuccessorEnd = newSuccessorStart.addDays(duration);
            m_projectData->get_taskModel()->updateTaskDates(successorId, newSuccessorStart, newSuccessorEnd, false);
            updateDependentTasks(successorId, newSuccessorEnd);
        }
    }
    m_updatingTasks.remove(taskId);
}