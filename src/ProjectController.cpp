#include "ProjectController.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

ProjectController::ProjectController(QObject *parent): QObject(parent)
    , m_projectData(nullptr)
    , m_inEditMode(false)
{
    m_projectData = new ProjectData(this);
    m_resourceManager = new ResourceManager(this);
    m_settingsManager = new SettingsManager(this);
    m_exportManager = new ExportManager(this);

    m_resourceManager->setResourcesPath(m_settingsManager->resourcesPath());

    connect(m_projectData->get_taskModel(), &TaskModel::taskDatesChanged,
            this, &ProjectController::onTaskDatesChanged);
    connect(m_projectData->get_taskModel(), &TaskModel::taskForecastDatesChanged,
            this, &ProjectController::onTaskForecastDatesChanged);
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
    m_projectData->clear();
    m_projectData->set_ProjectName(projectName);
    m_projectData->set_ProjectType(projectType);
    m_projectData->set_StartDate(startDate);
    m_projectData->set_FilePath(filePath);

    m_projectData->set_CreationDateTime(QDateTime::currentDateTime());
    m_projectData->set_LastModifiedDateTime(QDateTime::currentDateTime());

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

    QVariantList taskGroups = m_resourceManager->loadTaskGroups();
    for (const auto& groupData : taskGroups)
    {
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
    if (projectData.isEmpty())
    {
        emit errorOccurred("Не удалось загрузить проект");
        return;
    }

    if (!m_projectData->fromJson(projectData))
    {
        emit errorOccurred("Ошибка загрузки данных проекта");
        return;
    }

    m_projectData->set_FilePath(filePath);
    refreshAllLocalGraphForecasts();
    m_projectData->set_Modified(false);
    set_InEditMode(true);
    emit projectLoaded();
    m_projectData->refreshAll();
}

bool ProjectController::openLocalGraphFile(const QString& filePath)
{
    QVariantMap projectData = m_resourceManager->loadProjectFromFile(filePath);
    if (projectData.isEmpty())
    {
        emit errorOccurred("Не удалось загрузить локальный график");
        return false;
    }

    if (!m_projectData->fromJson(projectData))
    {
        emit errorOccurred("Ошибка загрузки данных локального графика");
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
    if (m_projectData->get_filePath().isEmpty())
    {
        emit errorOccurred("Путь к файлу не указан");
        return;
    }

    QVariantMap data = m_projectData->toJson();
    if (m_resourceManager->saveProjectToFile(data, m_projectData->get_filePath()))
    {
        m_projectData->set_Modified(false);
        m_projectData->updateLastModified();
        emit projectSaved();
    }
    else
    {
        emit errorOccurred("Ошибка сохранения проекта");
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
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    m_projectData->get_taskModel()->addTask(groupId, title, responsible, startDate, endDate);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::addTaskWithoutDates(const QString& groupId, const QString& title,
                                            const QString& responsible)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }
    m_projectData->get_taskModel()->addTaskWithoutDates(groupId, title, responsible);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::removeTask(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
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
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя редактировать выполненную задачу");
        return;
    }
    if (newStart > newEnd)
    {
        emit errorOccurred("Дата завершения не может быть раньше даты начала");
        return;
    }

    m_projectData->get_taskModel()->updateTaskDates(taskId, newStart, newEnd, true);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::updateForecastDates(const QString& taskId, const QDate& newForecastStart, const QDate& newForecastEnd)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя редактировать прогноз завершённой задачи");
        return;
    }
    if (newForecastStart > newForecastEnd)
    {
        emit errorOccurred("Дата завершения прогноза не может быть раньше даты начала");
        return;
    }

    m_projectData->get_taskModel()->updateForecastDates(taskId, newForecastStart, newForecastEnd);
    m_projectData->set_Modified(true);
}

void ProjectController::acceptForecastAsTarget(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty()) return;

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя утвердить прогноз завершённой задачи");
        return;
    }

    QDate forecastStart = task["forecastStart"].toDate();
    QDate forecastEnd = task["forecastEnd"].toDate();
    QDate targetStart = task["startDate"].toDate();
    QDate targetEnd = task["endDate"].toDate();

    if (!forecastStart.isValid() || !forecastEnd.isValid()) return;
    if (forecastStart == targetStart && forecastEnd == targetEnd) return;

    m_projectData->get_taskModel()->updateTaskDates(taskId, forecastStart, forecastEnd, true);
    m_projectData->recalculateEndDate();
    m_projectData->set_Modified(true);
}

void ProjectController::addDependency(const QString& predecessorId, const QString& successorId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }

    QVariantMap predTask = m_projectData->get_taskModel()->getTask(predecessorId);
    QVariantMap succTask = m_projectData->get_taskModel()->getTask(successorId);
    if (predTask.isEmpty() || succTask.isEmpty())
    {
        emit errorOccurred("Задача не найдена");
        return;
    }

    bool predHasDates = predTask["startDate"].toDate().isValid() && predTask["endDate"].toDate().isValid();
    bool succHasDates = succTask["startDate"].toDate().isValid() && succTask["endDate"].toDate().isValid();

    if (!predHasDates && succHasDates)
    {
        emit errorOccurred("Задача без сроков не может быть предшественником задачи со сроками");
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
    if (m_settingsManager->editingLocked())
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

        if (!successorStart.isValid() || !successorEnd.isValid())
            continue;

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

QDate ProjectController::endOfPredecessor(const QVariantMap& predTask) const
{
    int status = predTask["status"].toInt();
    if (status == static_cast<int>(GanttDefines::TaskStatus::Completed))
        return predTask["endDate"].toDate();
    return predTask["forecastEnd"].toDate();
}

void ProjectController::onTaskForecastDatesChanged(const QString& taskId)
{
    QSet<QString> visited;
    updateDependentForecasts(taskId, visited);
}

void ProjectController::updateDependentForecasts(const QString& taskId, QSet<QString>& visited)
{
    if (visited.contains(taskId)) return;
    visited.insert(taskId);

    QStringList successors = m_projectData->get_dependencyModel()->getSuccessors(taskId);
    for (const QString& successorId : successors)
    {
        QVariantMap successor = m_projectData->get_taskModel()->getTask(successorId);
        if (successor.isEmpty()) continue;

        int succStatus = successor["status"].toInt();
        if (succStatus == static_cast<int>(GanttDefines::TaskStatus::Completed))
            continue;

        QStringList predecessors = m_projectData->get_dependencyModel()->getPredecessors(successorId);
        QDate requiredStart;
        for (const QString& predId : predecessors)
        {
            QVariantMap predTask = m_projectData->get_taskModel()->getTask(predId);
            if (predTask.isEmpty()) continue;

            QDate predEnd = endOfPredecessor(predTask);
            if (!predEnd.isValid()) continue;

            QDate candidate = predEnd.addDays(1);
            if (!requiredStart.isValid() || candidate > requiredStart)
                requiredStart = candidate;
        }

        if (!requiredStart.isValid()) continue;

        QDate succStart = successor["forecastStart"].toDate();
        QDate succEnd = successor["forecastEnd"].toDate();
        if (!succStart.isValid() || !succEnd.isValid()) continue;

        if (succStart >= requiredStart) continue;

        int duration = succStart.daysTo(succEnd);
        QDate newStart = requiredStart;
        QDate newEnd = newStart.addDays(duration);

        m_projectData->get_taskModel()->updateForecastDates(successorId, newStart, newEnd);
        updateDependentForecasts(successorId, visited);
    }
}

// ---------------- Локальные графики ----------------

QString ProjectController::localGraphDirectory() const
{
    QString masterPath = m_projectData->get_filePath();
    if (masterPath.isEmpty()) return QString();

    QFileInfo fi(masterPath);
    QString baseName = fi.completeBaseName();
    return fi.absolutePath() + "/subGraph_" + baseName;
}

QString ProjectController::getLocalGraphPath(const QString& taskId) const
{
    QString dirPath = localGraphDirectory();
    if (dirPath.isEmpty()) return QString();

    QString masterPath = m_projectData->get_filePath();
    QFileInfo fi(masterPath);
    QString baseName = fi.completeBaseName();
    return dirPath + "/" + taskId + "-" + baseName + ".gantt";
}

bool ProjectController::localGraphFileExists(const QString& taskId) const
{
    QString path = getLocalGraphPath(taskId);
    if (path.isEmpty()) return false;
    return QFile::exists(path);
}

void ProjectController::markTaskRequiresLocalGraph(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty()) return;

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя пометить завершённую задачу");
        return;
    }

    int currentState = task["localGraphState"].toInt();
    if (currentState != static_cast<int>(GanttDefines::LocalGraphState::NotRequired))
        return;

    m_projectData->get_taskModel()->setLocalGraphState(taskId,
        static_cast<int>(GanttDefines::LocalGraphState::Required));
    m_projectData->set_Modified(true);
}

bool ProjectController::createLocalGraph(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return false;
    }

    if (m_projectData->get_filePath().isEmpty())
    {
        emit errorOccurred("Сначала сохраните мастерграфик");
        return false;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty())
    {
        emit errorOccurred("Задача не найдена");
        return false;
    }

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя создать ЛГ для завершённой задачи");
        return false;
    }

    int currentState = task["localGraphState"].toInt();
    if (currentState != static_cast<int>(GanttDefines::LocalGraphState::Required)
        && currentState != static_cast<int>(GanttDefines::LocalGraphState::Missing))
    {
        emit errorOccurred("Сначала пометьте задачу как требующую локальный график");
        return false;
    }

    QString path = getLocalGraphPath(taskId);
    if (path.isEmpty())
    {
        emit errorOccurred("Не удалось вычислить путь локального графика");
        return false;
    }

    if (QFile::exists(path))
    {
        emit errorOccurred("Файл локального графика уже существует");
        return false;
    }

    QString dirPath = localGraphDirectory();
    QDir dir;
    if (!dir.exists(dirPath))
    {
        if (!dir.mkpath(dirPath))
        {
            emit errorOccurred("Не удалось создать каталог: " + dirPath);
            return false;
        }
    }

    QVariantMap localDoc;
    localDoc["projectName"] = task["title"].toString();
    localDoc["projectType"] = "local";
    localDoc["graphKind"] = "local";
    localDoc["linkedMasterTaskId"] = taskId;

    QDate targetStart = task["startDate"].toDate();
    QDate targetEnd = task["endDate"].toDate();
    if (targetStart.isValid() && targetEnd.isValid())
    {
        localDoc["linkedTargetStart"] = targetStart.toString("dd.MM.yyyy");
        localDoc["linkedTargetEnd"] = targetEnd.toString("dd.MM.yyyy");
    }

    QDateTime now = QDateTime::currentDateTime();
    localDoc["creationDateTime"] = now.toString("dd.MM.yyyy hh:mm:ss");
    localDoc["lastModifiedDateTime"] = now.toString("dd.MM.yyyy hh:mm:ss");
    localDoc["tasks"] = QVariantList();
    localDoc["dependencies"] = QVariantList();

    if (!m_resourceManager->saveProjectToFile(localDoc, path))
    {
        emit errorOccurred("Не удалось сохранить локальный график");
        return false;
    }

    m_projectData->get_taskModel()->setLocalGraphState(taskId,
        static_cast<int>(GanttDefines::LocalGraphState::Attached));
    m_projectData->set_Modified(true);
    return true;
}

bool ProjectController::createLocalGraphOverwrite(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return false;
    }

    if (m_projectData->get_filePath().isEmpty())
    {
        emit errorOccurred("Сначала сохраните мастерграфик");
        return false;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty())
    {
        emit errorOccurred("Задача не найдена");
        return false;
    }

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя создать ЛГ для завершённой задачи");
        return false;
    }

    QString path = getLocalGraphPath(taskId);
    if (path.isEmpty())
    {
        emit errorOccurred("Не удалось вычислить путь локального графика");
        return false;
    }

    QString dirPath = localGraphDirectory();
    QDir dir;
    if (!dir.exists(dirPath))
    {
        if (!dir.mkpath(dirPath))
        {
            emit errorOccurred("Не удалось создать каталог: " + dirPath);
            return false;
        }
    }

    QVariantMap localDoc;
    localDoc["projectName"] = task["title"].toString();
    localDoc["projectType"] = "local";
    localDoc["graphKind"] = "local";
    localDoc["linkedMasterTaskId"] = taskId;

    QDate targetStart = task["startDate"].toDate();
    QDate targetEnd = task["endDate"].toDate();
    if (targetStart.isValid() && targetEnd.isValid())
    {
        localDoc["linkedTargetStart"] = targetStart.toString("dd.MM.yyyy");
        localDoc["linkedTargetEnd"] = targetEnd.toString("dd.MM.yyyy");
    }

    QDateTime now = QDateTime::currentDateTime();
    localDoc["creationDateTime"] = now.toString("dd.MM.yyyy hh:mm:ss");
    localDoc["lastModifiedDateTime"] = now.toString("dd.MM.yyyy hh:mm:ss");
    localDoc["tasks"] = QVariantList();
    localDoc["dependencies"] = QVariantList();

    if (!m_resourceManager->saveProjectToFile(localDoc, path))
    {
        emit errorOccurred("Не удалось сохранить локальный график");
        return false;
    }

    m_projectData->get_taskModel()->setLocalGraphState(taskId,
        static_cast<int>(GanttDefines::LocalGraphState::Attached));
    m_projectData->set_Modified(true);
    return true;
}

bool ProjectController::attachExistingLocalGraph(const QString& taskId)
{
    if (m_settingsManager->editingLocked())
    {
        emit errorOccurred("Редактирование заблокировано");
        return false;
    }

    QString path = getLocalGraphPath(taskId);
    if (path.isEmpty() || !QFile::exists(path))
    {
        emit errorOccurred("Файл локального графика не найден");
        return false;
    }

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty())
    {
        emit errorOccurred("Задача не найдена");
        return false;
    }

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
    {
        emit errorOccurred("Нельзя привязать ЛГ к завершённой задаче");
        return false;
    }

    m_projectData->get_taskModel()->setLocalGraphState(taskId,
        static_cast<int>(GanttDefines::LocalGraphState::Attached));
    m_projectData->set_Modified(true);
    return true;
}

void ProjectController::refreshLocalGraphForecast(const QString& taskId, const QString& localGraphPath, bool markModified)
{
    if (taskId.isEmpty() || localGraphPath.isEmpty()) return;

    QVariantMap task = m_projectData->get_taskModel()->getTask(taskId);
    if (task.isEmpty()) return;

    if (task["status"].toInt() == static_cast<int>(GanttDefines::TaskStatus::Completed))
        return;

    QFile file(localGraphPath);
    if (!file.open(QIODevice::ReadOnly)) return;

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull() || !doc.isObject()) return;

    QVariantMap localMap = doc.object().toVariantMap();
    QVariantList localTasks = localMap["tasks"].toList();

    if (localTasks.isEmpty()) return;

    QDate minStart;
    QDate maxEnd;
    int completedCount = 0;

    for (const auto& lt : localTasks)
    {
        QVariantMap ltm = lt.toMap();
        QDate s = QDate::fromString(ltm["startDate"].toString(), "dd.MM.yyyy");
        QDate e = QDate::fromString(ltm["endDate"].toString(), "dd.MM.yyyy");
        int status = ltm["status"].toInt();

        if (s.isValid() && (!minStart.isValid() || s < minStart))
            minStart = s;
        if (e.isValid() && (!maxEnd.isValid() || e > maxEnd))
            maxEnd = e;
        if (status == static_cast<int>(GanttDefines::TaskStatus::Completed))
            completedCount++;
    }

    if (!minStart.isValid() || !maxEnd.isValid()) return;

    m_projectData->get_taskModel()->updateForecastDates(taskId, minStart, maxEnd);
    m_projectData->get_taskModel()->setTaskProgress(taskId, completedCount, localTasks.size());

    if (completedCount == localTasks.size() && localTasks.size() > 0)
        m_projectData->get_taskModel()->setTaskStatus(taskId,
                                                      GanttDefines::TaskStatus::Completed);

        m_projectData->recalculateEndDate();
    if (markModified)
        m_projectData->set_Modified(true);

    qDebug() << "refreshLocalGraphForecast:" << taskId
    << "forecast" << minStart.toString("dd.MM.yyyy") << "-" << maxEnd.toString("dd.MM.yyyy")
    << "progress" << completedCount << "/" << localTasks.size();
}

void ProjectController::refreshAllLocalGraphForecasts()
{
    if (m_projectData->get_filePath().isEmpty()) return;

    QVariantList allTasks = m_projectData->get_taskModel()->getAllTasks();
    for (const auto& tv : allTasks)
    {
        QVariantMap task = tv.toMap();
        QString taskId = task["id"].toString();
        int lgs = task["localGraphState"].toInt();

        if (lgs != static_cast<int>(GanttDefines::LocalGraphState::Attached)
            && lgs != static_cast<int>(GanttDefines::LocalGraphState::Missing))
            continue;

        QString path = getLocalGraphPath(taskId);
        if (path.isEmpty() || !QFile::exists(path))
        {
            m_projectData->get_taskModel()->setLocalGraphState(taskId,
                                                               static_cast<int>(GanttDefines::LocalGraphState::Missing));
            continue;
        }

        refreshLocalGraphForecast(taskId, path, false);
        m_projectData->get_taskModel()->setLocalGraphState(taskId,
                                                           static_cast<int>(GanttDefines::LocalGraphState::Attached));
    }
}
