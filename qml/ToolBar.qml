import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: toolBar
    height: 40
    color: "#e0e0e0"
    z: 10

    // Свойства для доступа к диалогам из main.qml
    //property var newProjectDialog
    //property var openFileDialog
    //property var saveAsDialog
    //property var settingsDialog

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 5

        Button {
            text: "Файл"
            onClicked: fileMenu.popup()
            Menu
            {
                id: fileMenu
                //MenuItem { text: "Создать"; onTriggered: newProjectDialog.open() }
                //MenuItem { text: "Открыть"; onTriggered: openFileDialog.open() }
                //MenuSeparator {}
                //MenuItem { text: "Сохранить"; onTriggered: if(projectController && projectController.inEditMode) projectController.saveProject() }
                //MenuItem { text: "Сохранить как"; onTriggered: if(projectController && projectController.inEditMode) saveAsDialog.open() }
                MenuSeparator {}
                MenuItem { text: "Выход"; onTriggered: Qt.quit() }
            }
        }

        Button
        {
            text: "Вид"
            onClicked: viewMenu.popup()
            Menu {
                id: viewMenu
                MenuItem { text: "Показать полностью" }
                MenuSeparator {}
                // MenuItem
                // {
                //     text: "Трассировка"
                //     checkable: true
                //     checked: projectController ? projectController.settingsManager.tracingEnabled : false
                //     onTriggered: if(projectController) projectController.settingsManager.tracingEnabled = checked
                // }
            }
        }

        // Button
        // {
        //     text: "Настройки"
        //     onClicked: settingsMenu.popup()
        //     Menu {
        //         id: settingsMenu
        //         MenuItem { text: "Изменить пути ресурсных файлов"; onTriggered: settingsDialog.open() }
        //     }
        // }

        Button {
            text: "Помощь"
            onClicked: helpMenu.popup()
            Menu {
                id: helpMenu
                MenuItem { text: "Справка" }
            }
        }

        Button {
            text: "О программе"
            onClicked: aboutMenu.popup()
            Menu {
                id: aboutMenu
                MenuItem { text: "О программе" }
            }
        }

        // ToolButton {
        //     width: 30
        //     height: 30
        //     checkable: true
        //     checked: projectController ? projectController.settingsManager.editingLocked : false
        //     onCheckedChanged: if(projectController) projectController.settingsManager.editingLocked = checked
        //     contentItem: Text {
        //         text: checked ? "🔒" : "🔓"
        //         font.pixelSize: 16
        //         horizontalAlignment: Text.AlignHCenter
        //         verticalAlignment: Text.AlignVCenter
        //     }
        // }
    }
}