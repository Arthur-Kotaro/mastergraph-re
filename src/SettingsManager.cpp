#include "SettingsManager.h"
#include <QCoreApplication>
#include <QDebug>

SettingsManager::SettingsManager(QObject *parent): QObject(parent)
    , m_zoomLevel(GanttDefines::ZoomLevel::Daily)
    , m_tracingEnabled(false)
    , m_editingLocked(false)
    , m_viewMode(GanttDefines::ViewMode::Target)
{
    m_settings = new QSettings(QCoreApplication::organizationName(), QCoreApplication::applicationName(), this);
    loadSettings();
    qDebug() << "SettingsManager initialized, zoomLevel:" << static_cast<int>(m_zoomLevel)
             << "viewMode:" << static_cast<int>(m_viewMode);
}

QString SettingsManager::resourcesPath() const { return m_resourcesPath; }

void SettingsManager::setResourcesPath(const QString& path) {
    if (m_resourcesPath != path) {
        m_resourcesPath = path;
        emit resourcesPathChanged();
        saveSettings();
    }
}

GanttDefines::ZoomLevel SettingsManager::zoomLevel() const { return m_zoomLevel; }

void SettingsManager::setZoomLevel(GanttDefines::ZoomLevel level) {
    if (m_zoomLevel != level) {
        m_zoomLevel = level;
        emit zoomLevelChanged();
        saveSettings();
    }
}

void SettingsManager::setZoomLevel(int level) {
    if (level >= 0 && level <= 2) {
        setZoomLevel(static_cast<GanttDefines::ZoomLevel>(level));
    }
}

bool SettingsManager::tracingEnabled() const { return m_tracingEnabled; }

void SettingsManager::setTracingEnabled(bool enabled) {
    if (m_tracingEnabled != enabled) {
        m_tracingEnabled = enabled;
        emit tracingEnabledChanged();
        saveSettings();
    }
}

bool SettingsManager::editingLocked() const { return m_editingLocked; }

void SettingsManager::setEditingLocked(bool locked) {
    if (m_editingLocked != locked) {
        m_editingLocked = locked;
        emit editingLockedChanged();
        saveSettings();
    }
}

GanttDefines::ViewMode SettingsManager::viewMode() const { return m_viewMode; }

void SettingsManager::setViewMode(GanttDefines::ViewMode mode) {
    if (m_viewMode != mode) {
        m_viewMode = mode;
        emit viewModeChanged();
        saveSettings();
    }
}

void SettingsManager::setViewMode(int mode) {
    if (mode >= 0 && mode <= 2) {
        setViewMode(static_cast<GanttDefines::ViewMode>(mode));
    }
}

void SettingsManager::saveSettings() {
    m_settings->setValue("resourcesPath", m_resourcesPath);
    m_settings->setValue("zoomLevel", static_cast<int>(m_zoomLevel));
    m_settings->setValue("tracingEnabled", m_tracingEnabled);
    m_settings->setValue("editingLocked", m_editingLocked);
    m_settings->setValue("viewMode", static_cast<int>(m_viewMode));
    m_settings->sync();
}

void SettingsManager::loadSettings() {
    m_resourcesPath = m_settings->value("resourcesPath",
        QCoreApplication::applicationDirPath() + "/").toString();
    m_zoomLevel = static_cast<GanttDefines::ZoomLevel>(
        m_settings->value("zoomLevel", 2).toInt());
    m_tracingEnabled = m_settings->value("tracingEnabled", false).toBool();
    m_editingLocked = m_settings->value("editingLocked", false).toBool();
    m_viewMode = static_cast<GanttDefines::ViewMode>(
        m_settings->value("viewMode", 0).toInt());
}
