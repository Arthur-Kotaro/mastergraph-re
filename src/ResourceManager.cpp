#include "ResourceManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QCoreApplication>
#include <QDebug>
#include <QFileInfo>
#include <QStandardPaths>

ResourceManager::ResourceManager(QObject *parent) : QObject(parent)
{
    m_resourcesPath = getDefaultResourcesPath();
}

QString ResourceManager::resourcesPath() const { return m_resourcesPath; }

void ResourceManager::setResourcesPath(const QString& path) {
    if (m_resourcesPath != path) {
        m_resourcesPath = path;
        emit resourcesPathChanged();
    }
}

QString ResourceManager::getDefaultResourcesPath() const {
    return QCoreApplication::applicationDirPath() + "/";
}

QVariantMap ResourceManager::loadJsonFile(const QString& fileName) {
    QString fullPath = m_resourcesPath + fileName;
    QFile file(fullPath);
    if (!file.open(QIODevice::ReadOnly)) {
        emit errorOccurred("Не удалось открыть файл: " + fullPath);
        return QVariantMap();
    }
    
    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        emit errorOccurred("Ошибка парсинга JSON: " + fullPath);
        return QVariantMap();
    }
    
    return doc.object().toVariantMap();
}

bool ResourceManager::saveJsonFile(const QString& fileName, const QVariantMap& data) {
    QString fullPath = fileName;
    
    qDebug() << "saveJsonFile: trying to save to" << fullPath;
    
    // Проверяем, можем ли мы писать в директорию
    QFileInfo fileInfo(fullPath);
    QDir dir = fileInfo.absoluteDir();
    
    qDebug() << "saveJsonFile: directory = " << dir.absolutePath();
    
    if (!dir.exists()) {
        qDebug() << "saveJsonFile: directory does not exist, creating...";
        if (!dir.mkpath(".")) {
            emit errorOccurred("Не удалось создать директорию: " + dir.absolutePath());
            qDebug() << "saveJsonFile: FAILED to create directory!";
            return false;
        }
        qDebug() << "saveJsonFile: directory created successfully";
    }
    
    // Проверяем права на запись в директорию
    if (!dir.isReadable()) {
        emit errorOccurred("Нет прав на чтение директории: " + dir.absolutePath());
        qDebug() << "saveJsonFile: directory not readable!";
        return false;
    }
    
    QFile file(fullPath);
    if (!file.open(QIODevice::WriteOnly)) {
        emit errorOccurred("Не удалось создать файл: " + fullPath);
        qDebug() << "saveJsonFile: FAILED to open file for writing! Error:" << file.errorString();
        return false;
    }
    
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    qint64 bytesWritten = file.write(doc.toJson());
    file.close();
    
    if (bytesWritten > 0) {
        qDebug() << "saveJsonFile: SUCCESS! Written" << bytesWritten << "bytes";
        return true;
    } else {
        qDebug() << "saveJsonFile: FAILED to write data!";
        return false;
    }
}

QVariantList ResourceManager::loadTypologies() {
    QVariantMap data = loadJsonFile("default_typologies.json");
    return data["typologies"].toList();
}

QVariantList ResourceManager::loadTaskGroups() {
    QVariantMap data = loadJsonFile("default_tasks.json");
    return data["task_groups"].toList();
}

bool ResourceManager::saveProjectToFile(const QVariantMap& projectData, const QString& filePath) {
    qDebug() << "saveProjectToFile:" << filePath;
    return saveJsonFile(filePath, projectData);
}

QVariantMap ResourceManager::loadProjectFromFile(const QString& filePath) {
    QString fullPath = filePath;
    QFile file(fullPath);
    if (!file.open(QIODevice::ReadOnly)) {
        emit errorOccurred("Не удалось открыть файл проекта: " + fullPath);
        return QVariantMap();
    }
    
    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        emit errorOccurred("Ошибка парсинга файла проекта: " + fullPath);
        return QVariantMap();
    }
    
    return doc.object().toVariantMap();
}
