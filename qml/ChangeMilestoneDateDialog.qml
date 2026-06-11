import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Перенос даты вехи"
    width: 350
    height: 180
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    property string milestoneId: ""
    property date newDate: new Date()
    
    ColumnLayout
    {
        anchors.fill: parent
        spacing: 15
        
        DatePicker
        {
            id: datePicker
            title: "Новая дата прохождения"
            Layout.fillWidth: true
            selectedDate: root.newDate
            onDateSelected: root.newDate = selectedDate
        }
    }
    
    onAccepted:
    {
        projectController.projectData.milestoneModel.rescheduleMilestone(root.milestoneId, root.newDate)
    }
    
    function open(milestoneId, currentDate)
    {
        root.milestoneId = milestoneId
        root.newDate = currentDate
        root.open()
    }
}
