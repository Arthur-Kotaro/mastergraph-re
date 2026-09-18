import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle {
    id: root
    height: 30
    color: "#d0d0d0"

    property var stats: ({})

    function refreshStats()
    {
        if (projectController && projectController.projectData)
            stats = projectController.projectData.getTaskStatistics()
        else
            stats = ({})
    }

    function getGroupsCount()
    {
        return (projectController && projectController.projectData && projectController.projectData.groupModel)
               ? projectController.projectData.groupModel.count : 0
    }

    function isModified()
    {
        return (projectController && projectController.projectData) ? projectController.projectData.modified : false
    }

    Component.onCompleted: refreshStats()

    Connections
    {
        target: projectController?.projectData?.taskModel
        function onCountChanged() { refreshStats() }
        function onDataChanged() { refreshStats() }
        function onRowsInserted() { refreshStats() }
        function onRowsRemoved() { refreshStats() }
        function onModelReset() { refreshStats() }
    }

    Connections
    {
        target: projectController
        function onProjectLoaded() { refreshStats() }
    }

    Row
    {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 20

        Text { text: "Групп: " + getGroupsCount(); anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Всего задач: " + (stats.total !== undefined ? stats.total : 0); anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Со сроками: " + (stats.withDates !== undefined ? stats.withDates : 0); anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Без сроков: " + (stats.withoutDates !== undefined ? stats.withoutDates : 0); anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Неутверждённых: " + (stats.unapprovedForecasts !== undefined ? stats.unapprovedForecasts : 0); anchors.verticalCenter: parent.verticalCenter }

        Rectangle { width: 10; height: 10; radius: 5; color: isModified() ? "orange" : "green"; anchors.verticalCenter: parent.verticalCenter }
        Text { text: isModified() ? "Изменён" : "Сохранён"; anchors.verticalCenter: parent.verticalCenter }
    }
}
