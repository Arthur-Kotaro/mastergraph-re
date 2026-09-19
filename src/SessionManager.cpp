#include "SessionManager.h"
#include "ProjectController.h"
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickWindow>
#include <QDebug>
#include <QFile>

SessionManager::SessionManager(QObject *parent) : QObject(parent) {}

SessionManager::~SessionManager() {}

void SessionManager::registerMasterSession(QQmlApplicationEngine* engine, ProjectController* controller)
{
    m_masterEngine = engine;
    m_masterController = controller;
}

bool SessionManager::isLocalGraphSessionOpen(const QString& taskId) const
{
    return m_localSessions.contains(taskId);
}

bool SessionManager::openLocalGraphSession(const QString& taskId)
{
    if (!m_masterController)
    {
        qWarning() << "SessionManager: no master session registered";
        return false;
    }

    if (m_localSessions.contains(taskId))
    {
        LocalSession& session = m_localSessions[taskId];
        if (session.window)
        {
            QQuickWindow* qw = qobject_cast<QQuickWindow*>(session.window);
            if (qw) { qw->show(); qw->raise(); qw->requestActivate(); }
        }
        return true;
    }

    QString path = m_masterController->getLocalGraphPath(taskId);
    if (path.isEmpty() || !QFile::exists(path))
    {
        qWarning() << "SessionManager: local graph file not found for task" << taskId;
        return false;
    }

    QQmlApplicationEngine* engine = new QQmlApplicationEngine();
    ProjectController* controller = new ProjectController();

    if (!controller->openLocalGraphFile(path))
    {
        qWarning() << "SessionManager: failed to open local graph file" << path;
        delete controller;
        delete engine;
        return false;
    }

    engine->rootContext()->setContextProperty("projectController", controller);
    engine->rootContext()->setContextProperty("sessionManager", this);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    engine->load(url);

    if (engine->rootObjects().isEmpty())
    {
        qWarning() << "SessionManager: failed to load QML for local graph";
        delete controller;
        delete engine;
        return false;
    }

    QObject* window = engine->rootObjects().first();

    LocalSession session;
    session.engine = engine;
    session.controller = controller;
    session.window = window;
    session.taskId = taskId;

    m_localSessions.insert(taskId, session);

    // При сохранении ЛГ уведомляем главное окно
    connect(controller, &ProjectController::projectSaved, this, [this, taskId, controller]() {
        QString path = controller->get_projectData()->get_filePath();
        emit localGraphSaved(taskId, path);
    });

    QQuickWindow* qw = qobject_cast<QQuickWindow*>(window);
    if (qw) { qw->raise(); qw->requestActivate(); }

    return true;
}

void SessionManager::closeLocalGraphSession(const QString& taskId)
{
    if (!m_localSessions.contains(taskId)) return;

    LocalSession session = m_localSessions.take(taskId);
    if (session.window)
        session.window->deleteLater();
}

void SessionManager::notifyWindowClosed(const QString& taskId)
{
    if (!m_localSessions.contains(taskId)) return;

    LocalSession session = m_localSessions.take(taskId);
    if (session.window)
        session.window->deleteLater();
    if (session.controller)
        session.controller->deleteLater();
    if (session.engine)
        session.engine->deleteLater();

    emit localGraphSessionClosed(taskId);
}

void SessionManager::notifyLocalGraphSaved(const QString& taskId, const QString& filePath)
{
    emit localGraphSaved(taskId, filePath);
}
