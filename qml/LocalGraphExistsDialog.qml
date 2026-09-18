import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Локальный график уже существует"
    width: 500
    height: 220
    modal: true
    standardButtons: Dialog.NoButton
    anchors.centerIn: Overlay.overlay

    property string taskId: ""

    function openForTask(tId)
    {
        taskId = tId
        open()
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label
        {
            text: "Файл локального графика для этой задачи уже существует."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 14
        }

        Label
        {
            text: "Использовать его как источник прогноза или перезаписать новым пустым файлом?"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 13
            color: "#555555"
        }

        Item { Layout.fillHeight: true }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 10

            Button
            {
                text: "Использовать существующий"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                onClicked:
                {
                    if (projectController && root.taskId)
                        projectController.attachExistingLocalGraph(root.taskId)
                    root.close()
                }
            }

            Button
            {
                text: "Перезаписать"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                onClicked:
                {
                    if (projectController && root.taskId)
                        projectController.createLocalGraphOverwrite(root.taskId)
                    root.close()
                }
            }

            Button
            {
                text: "Отмена"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                onClicked: root.close()
            }
        }
    }
}
