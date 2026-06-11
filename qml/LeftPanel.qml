import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle {
    id: root
    color: "#fafafa"
    border.color: "#cccccc"
    border.width: 1
    
    property int rowHeight: 40
    
    Column {
        anchors.fill: parent
        spacing: 0
        
        Row {
            width: parent.width
            height: 200
            
            Rectangle {
                width: parent.width - 65
                height: parent.height
                color: "#f0f0f0"
                border.color: "#cccccc"
                border.width: 1
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    
                    Text {
                        text: "Название проекта:"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#555555"
                    }
                    Text {
                        text: projectController.projectData?.projectName || ""
                        font.pixelSize: 22
                        font.bold: true
                        wrapMode: Text.WordWrap
                        width: parent.width
                        color: "#222222"
                    }
                }
            }
            
            Rectangle {
                width: 65
                height: parent.height
                color: "#e8e8e8"
                border.color: "#cccccc"
                border.width: 1
                
                Column {
                    anchors.fill: parent
                    
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        border.color: "#cccccc"
                        border.width: 1
                        Text { text: "Год"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 12 }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        border.color: "#cccccc"
                        border.width: 1
                        Text { text: "Месяц"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        border.color: "#cccccc"
                        border.width: 1
                        Text { text: "Неделя"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        border.color: "#cccccc"
                        border.width: 1
                        Text { text: "День"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 12 }
                    }
                    Rectangle {
                        width: parent.width
                        height: rowHeight
                        border.color: "#cccccc"
                        border.width: 1
                        Text { text: "Веха"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 12 }
                    }
                }
            }
        }
        
        Rectangle {
            width: parent.width
            height: rowHeight
            color: "#e8e8e8"
            border.color: "#cccccc"
            border.width: 1
            
            Row {
                anchors.fill: parent
                
                Rectangle {
                    width: parent.width * 0.35
                    height: parent.height
                    border.color: "#cccccc"
                    border.width: 1
                    Text { text: "Название"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 11 }
                }
                Rectangle {
                    width: parent.width * 0.20
                    height: parent.height
                    border.color: "#cccccc"
                    border.width: 1
                    Text { text: "Ответственный"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                }
                Rectangle {
                    width: parent.width * 0.22
                    height: parent.height
                    border.color: "#cccccc"
                    border.width: 1
                    Text { text: "Дата начала"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                }
                Rectangle {
                    width: parent.width * 0.23
                    height: parent.height
                    border.color: "#cccccc"
                    border.width: 1
                    Text { text: "Дата завершения"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                }
            }
        }
        
        ScrollView {
            width: parent.width
            height: parent.height - 200 - rowHeight
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            
            ListView {
                id: groupsListView
                width: parent.width
                model: projectController.projectData?.groupModel
                delegate: GroupDelegate {
                    width: groupsListView.width
                }
                interactive: true
            }
        }
    }
}
