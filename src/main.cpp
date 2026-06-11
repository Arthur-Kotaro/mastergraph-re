#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "ProjectController.h"
#include "TaskModel.h"
#include "GroupModel.h"
#include "MilestoneModel.h"
#include "DependencyModel.h"
#include "ProjectData.h"
#include "ResourceManager.h"
#include "SettingsManager.h"
#include "ExportManager.h"
#include "HistoryEntry.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName("GanttProject");
    
    //qmlRegisterType<ProjectController>("GanttProject", 1, 0, "ProjectController");

    qmlRegisterType<TaskModel>("GanttProject", 1, 0, "TaskModel");
    qmlRegisterType<GroupModel>("GanttProject", 1, 0, "GroupModel");
    qmlRegisterType<MilestoneModel>("GanttProject", 1, 0, "MilestoneModel");
    qmlRegisterType<DependencyModel>("GanttProject", 1, 0, "DependencyModel");
    qmlRegisterType<ProjectData>("GanttProject", 1, 0, "ProjectData");
    qmlRegisterType<ResourceManager>("GanttProject", 1, 0, "ResourceManager");
    qmlRegisterType<SettingsManager>("GanttProject", 1, 0, "SettingsManager");
    qmlRegisterType<ExportManager>("GanttProject", 1, 0, "ExportManager");
    qmlRegisterType<HistoryEntry>("GanttProject", 1, 0, "HistoryEntry");
    
    QQmlApplicationEngine engine;
    
    ProjectController controller;
    engine.rootContext()->setContextProperty("projectController", &controller);
    
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject *obj, const QUrl &objUrl)
    { if (!obj && url == objUrl) QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    
    engine.load(url);
    return app.exec();
}