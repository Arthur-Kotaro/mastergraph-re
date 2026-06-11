#ifndef EXPORTMANAGER_H
#define EXPORTMANAGER_H

#include <QObject>
#include <QString>
#include <QDate>

class ProjectData;

class ExportManager : public QObject
{
    Q_OBJECT

public:
    explicit ExportManager(QObject *parent = nullptr);

    Q_INVOKABLE bool exportToPng(ProjectData* project, const QString& filePath, int width, int height);
    Q_INVOKABLE bool exportToPdf(ProjectData* project, const QString& filePath, const QDate& exportDate);

signals:
    void exportProgress(int percent);
    void exportFinished(bool success, const QString& message);

private:
    QObject* m_ganttView;
};

#endif
