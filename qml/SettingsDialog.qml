import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import Qt.labs.platform 1.1 as Labs

Dialog {
    id: root
    title: "Настройки"
    width: 500; height: 200; modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    property string resourcesPath: projectController.settingsManager.resourcesPath
    
    ColumnLayout {
        anchors.fill: parent; spacing: 15
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Label { text: "Путь к ресурсным файлам:"; Layout.fillWidth: true }
            TextField { id: pathField; text: root.resourcesPath; Layout.fillWidth: true; onTextChanged: root.resourcesPath = text }
            Button { text: "Обзор..."; onClicked: folderDialog.open() }
        }
        Label { 
            text: "Примечание: ресурсные файлы (типологии, шаблоны задач, вехи) загружаются из указанной директории"
            wrapMode: Text.WordWrap; font.pixelSize: 11; color: "gray"; Layout.fillWidth: true
        }
        
        Labs.FolderDialog {
            id: folderDialog
            onAccepted: pathField.text = folder
        }
    }
    
    onAccepted: {
        projectController.settingsManager.resourcesPath = root.resourcesPath
        projectController.resourceManager.resourcesPath = root.resourcesPath
    }
    
    onOpened: { root.resourcesPath = projectController.settingsManager.resourcesPath }
}
