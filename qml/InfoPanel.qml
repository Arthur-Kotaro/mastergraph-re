import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle {
    id: root
    height: 30
    color: "#d0d0d0"
    
    function getGroupsCount()
    {
        return (projectController && projectController.projectData && projectController.projectData.groupModel) 
               ? projectController.projectData.groupModel.count : 0
    }
    
    function getTasksCount()
    {
        return (projectController && projectController.projectData && projectController.projectData.taskModel) 
               ? projectController.projectData.taskModel.count : 0
    }
    
    function isModified()
    {
        return (projectController && projectController.projectData) ? projectController.projectData.modified : false
    }
    
    Row
    {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 20
        Text { text: "Групп: " + getGroupsCount(); anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Задач: " + getTasksCount(); anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 10; height: 10; radius: 5; color: isModified() ? "orange" : "green"; anchors.verticalCenter: parent.verticalCenter }
        Text { text: isModified() ? "Изменён" : "Сохранён"; anchors.verticalCenter: parent.verticalCenter }
    }
}
