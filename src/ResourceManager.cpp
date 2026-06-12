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
    qDebug() << "loadJsonFile called for:" << fileName << "fullPath:" << (m_resourcesPath + fileName);
    
    // 1. Пробуем qrc
    QFile qrcFile(":/" + fileName);
    qDebug() << "Trying qrc:" << qrcFile.fileName() << "exists:" << qrcFile.exists();
    if (qrcFile.open(QIODevice::ReadOnly)) {
        QByteArray data = qrcFile.readAll();
        qDebug() << "qrc data size:" << data.size();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isNull()) {
            qDebug() << "Successfully loaded from qrc:" << fileName;
            return doc.object().toVariantMap();
        }
    }
    
    // 2. Пробуем файловую систему
    QString fullPath = m_resourcesPath + fileName;
    qDebug() << "Trying file:" << fullPath;
    QFile file(fullPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Failed to open file:" << fullPath << "error:" << file.errorString();
        emit errorOccurred("Не удалось открыть файл: " + fullPath);
        return QVariantMap();
    }
    
    QByteArray data = file.readAll();
    qDebug() << "File data size:" << data.size();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        qDebug() << "Failed to parse JSON from:" << fullPath;
        emit errorOccurred("Ошибка парсинга JSON: " + fullPath);
        return QVariantMap();
    }
    
    qDebug() << "Successfully loaded from file:" << fileName;
    return doc.object().toVariantMap();
}

bool ResourceManager::saveJsonFile(const QString& fileName, const QVariantMap& data) {
    QString fullPath = fileName;
    
    qDebug() << "saveJsonFile: trying to save to" << fullPath;
    
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
    qDebug() << "loadTypologies: m_resourcesPath =" << m_resourcesPath;
    QVariantMap data = loadJsonFile("default_typologies.json");
    QVariantList result = data["typologies"].toList();
    qDebug() << "loadTypologies: result count =" << result.size();
    return result;
}

QVariantList ResourceManager::loadTaskGroups() {
    qDebug() << "loadTaskGroups: m_resourcesPath =" << m_resourcesPath;
    QVariantMap data = loadJsonFile("default_tasks.json");
    QVariantList result = data["task_groups"].toList();
    qDebug() << "loadTaskGroups: result count =" << result.size();
    return result;
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
