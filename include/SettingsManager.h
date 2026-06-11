#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include "GlobalDefines.h"

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString resourcesPath READ resourcesPath WRITE setResourcesPath NOTIFY resourcesPathChanged)
    Q_PROPERTY(GanttDefines::ZoomLevel zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)
    Q_PROPERTY(bool tracingEnabled READ tracingEnabled WRITE setTracingEnabled NOTIFY tracingEnabledChanged)
    Q_PROPERTY(bool editingLocked READ editingLocked WRITE setEditingLocked NOTIFY editingLockedChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    QString resourcesPath() const;
    void setResourcesPath(const QString& path);

    GanttDefines::ZoomLevel zoomLevel() const;
    void setZoomLevel(GanttDefines::ZoomLevel level);
    Q_INVOKABLE void setZoomLevel(int level);

    bool tracingEnabled() const;
    void setTracingEnabled(bool enabled);

    bool editingLocked() const;
    void setEditingLocked(bool locked);

    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void loadSettings();

signals:
    void resourcesPathChanged();
    void zoomLevelChanged();
    void tracingEnabledChanged();
    void editingLockedChanged();

private:
    QSettings* m_settings;
    QString m_resourcesPath;
    GanttDefines::ZoomLevel m_zoomLevel;
    bool m_tracingEnabled;
    bool m_editingLocked;
};

#endif
