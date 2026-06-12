import QtQuick 6.0
import QtQuick.Controls 6.0

Rectangle
{
    id: root
    color: "#f0f0f0"
    border.color: "#aaaaaa"
    border.width: 1

    property var milestonesModel: null
    property date startDate: new Date()
    property int dayWidth: 30
    property var milestones: []

    function updateMilestones()
    {
        if (milestonesModel)
        {
            milestones = milestonesModel.getAllMilestones()
        }
        else
        {
            milestones = []
        }
    }

    Component.onCompleted: updateMilestones()

    Connections
    {
        target: milestonesModel || null
        enabled: milestonesModel !== null
        function onModelReset() { updateMilestones() }
        function onDataChanged() { updateMilestones() }
        function onMilestonesChanged() { updateMilestones() }
        function onMilestoneStatusChanged() { updateMilestones() }
    }

    Repeater
    {
        model: milestones
        delegate: Item
        {
            id: milestoneDelegate
            x:
            {
                var plannedDate = new Date(modelData.plannedDate)
                var daysDiff = Math.floor((plannedDate - startDate) / (1000 * 60 * 60 * 24))
                return daysDiff * dayWidth + dayWidth / 2 - width / 2
            }
            width: 24
            height: parent.height

            Rectangle
            {
                id: diamond
                width: 12
                height: 12
                rotation: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 5
                color:
                {
                    if (milestonesModel)
                    {
                        var ms = milestonesModel.getMilestone(modelData.milestoneId)
                        if (ms)
                        {
                            switch(ms.status)
                            {
                                case 0: return "#FFD700"
                                case 1: return "#32CD32"
                                case 2: return "#888888"
                                default: return "#FFD700"
                            }
                        }
                    }
                    return modelData.color || "#FFD700"
                }
            }

            Text
            {
                text: modelData.abbreviation || ""
                font.pixelSize: 10
                font.bold: true
                anchors.top: diamond.bottom
                anchors.topMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ToolTip
            {
                visible: mouseArea.containsMouse
                text:
                {
                    var info = ""
                    if (modelData.fullName) info += modelData.fullName + "\n"
                    if (modelData.tooltip) info += modelData.tooltip + "\n"
                    info += "Дата: " + Qt.formatDateTime(modelData.plannedDate, "dd.MM.yyyy")
                    return info
                }
                delay: 500
            }

            MouseArea
            {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.RightButton
                onClicked:
                {
                    milestoneContextMenu.milestoneId = modelData.milestoneId
                    milestoneContextMenu.currentDate = modelData.plannedDate
                    milestoneContextMenu.currentStatus = modelData.status
                    milestoneContextMenu.currentAbbreviation = modelData.abbreviation
                    milestoneContextMenu.currentFullName = modelData.fullName
                    milestoneContextMenu.currentActualDate = modelData.actualDate
                    milestoneContextMenu.popup()
                }
            }
        }
    }

    Dialog
    {
        id: confirmMilestoneDialog
        title: "Подтверждение изменения статуса вехи"
        width: 400
        height: 150
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay

        property string milestoneId: ""
        property string milestoneName: ""

        Column
        {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            Label
            {
                width: parent.width
                text: "Вы действительно хотите изменить статус вехи \"" + confirmMilestoneDialog.milestoneName + "\" на \"Пройдено\"?"
                wrapMode: Text.WordWrap
            }
        }

        onAccepted:
        {
            if (milestoneId && milestonesModel)
            {
                milestonesModel.setMilestoneCompleted(milestoneId)
                updateMilestones()
            }
        }
    }

    Dialog
    {
        id: infoMilestoneDialog
        title: "Информация о вехе"
        width: 400
        height: 250
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay

        property string milestoneId: ""
        property string milestoneName: ""
        property string milestoneAbbr: ""
        property int milestoneStatus: 0
        property date milestoneDate: new Date()
        property date milestoneActualDate: new Date()

        Column
        {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12
            Label { text: "Название: " + infoMilestoneDialog.milestoneName }
            Label { text: "Аббревиатура: " + infoMilestoneDialog.milestoneAbbr }
            Label { text: "Статус: " + (infoMilestoneDialog.milestoneStatus === 0 ? "Запланирована" : (infoMilestoneDialog.milestoneStatus === 1 ? "Пройдена" : "Перенесена")) }
            Label { text: "Плановая дата: " + Qt.formatDateTime(infoMilestoneDialog.milestoneDate, "dd.MM.yyyy") }
            Label
            {
                visible: infoMilestoneDialog.milestoneStatus === 1
                text: "Дата прохождения: " + Qt.formatDateTime(infoMilestoneDialog.milestoneActualDate, "dd.MM.yyyy")
            }
        }
    }

    Menu
    {
        id: milestoneContextMenu
        property string milestoneId: ""
        property date currentDate: new Date()
        property int currentStatus: 0
        property string currentAbbreviation: ""
        property string currentFullName: ""
        property date currentActualDate: new Date()

        MenuItem
        {
            text: "Веха пройдена"
            enabled: milestoneContextMenu.currentStatus !== 1
            onTriggered:
            {
                confirmMilestoneDialog.milestoneId = milestoneId
                confirmMilestoneDialog.milestoneName = currentAbbreviation
                confirmMilestoneDialog.open()
            }
        }
        MenuItem
        {
            text: "Перенести дату прохождения"
            onTriggered:
            {
                if (milestoneId && milestonesModel)
                    changeMilestoneDateDialog.open(milestoneId, currentDate)
            }
        }
        MenuSeparator {}
        MenuItem
        {
            text: "Показать информацию"
            onTriggered:
            {
                infoMilestoneDialog.milestoneId = milestoneId
                infoMilestoneDialog.milestoneName = currentFullName
                infoMilestoneDialog.milestoneAbbr = currentAbbreviation
                infoMilestoneDialog.milestoneStatus = currentStatus
                infoMilestoneDialog.milestoneDate = currentDate
                infoMilestoneDialog.milestoneActualDate = currentActualDate
                infoMilestoneDialog.open()
            }
        }
    }
}
