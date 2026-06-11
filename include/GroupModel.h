#ifndef GROUPMODEL_H
#define GROUPMODEL_H

#include <QAbstractListModel>
#include <QList>

class GroupModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    struct Group {
        QString id;
        QString name;
        bool expanded;
        QList<QString> taskIds;
    };

    explicit GroupModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addGroup(const QString& name);
    Q_INVOKABLE void addGroupAt(int position, const QString& name);
    Q_INVOKABLE void removeGroup(const QString& groupId);
    Q_INVOKABLE void renameGroup(const QString& groupId, const QString& newName);
    Q_INVOKABLE void setGroupExpanded(const QString& groupId, bool expanded);
    Q_INVOKABLE void moveGroup(const QString& groupId, int newPosition);
    Q_INVOKABLE QVariantMap getGroup(const QString& groupId) const;
    Q_INVOKABLE QStringList getGroupIds() const;
    Q_INVOKABLE void setTaskOrder(const QString& groupId, const QStringList& taskIds);
    Q_INVOKABLE void addTaskToGroup(const QString& groupId, const QString& taskId);
    Q_INVOKABLE void removeTaskFromGroup(const QString& groupId, const QString& taskId);
    Q_INVOKABLE void moveTaskInGroup(const QString& groupId, const QString& taskId, int newPosition);
    
    // Новые методы для доступа из QML
    Q_INVOKABLE QString getGroupId(int index) const;
    Q_INVOKABLE QString getGroupName(int index) const;
    Q_INVOKABLE bool isExpanded(int index) const;

    void clear();

signals:
    void countChanged();
    void groupExpandedChanged(const QString& groupId);

private:
    QList<Group> m_groups;
    QString generateId() const;
    int findGroupIndex(const QString& groupId) const;
};

#endif
