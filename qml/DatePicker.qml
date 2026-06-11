import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Rectangle {
    id: root
    property string title: "Дата"
    property date selectedDate: new Date()
    signal dateSelected()
    height: 40
    color: "transparent"
    
    // Внутренние переменные (не свойства)
    property int _calendarYear: selectedDate.getFullYear()
    property int _calendarMonth: selectedDate.getMonth()
    property var _calendarModel: []
    
    function updateTextField() {
        dateField.text = Qt.formatDateTime(root.selectedDate, "dd.MM.yyyy")
    }
    
    function updateCalendarModel() {
        var firstDay = new Date(_calendarYear, _calendarMonth, 1)
        var startDay = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1
        var daysInMonth = new Date(_calendarYear, _calendarMonth + 1, 0).getDate()
        var result = []
        
        for (var i = 0; i < startDay; i++) result.push("")
        for (var i = 1; i <= daysInMonth; i++) result.push(i)
        
        _calendarModel = result
    }
    
    function updateCalendar() {
        _calendarYear = selectedDate.getFullYear()
        _calendarMonth = selectedDate.getMonth()
        updateCalendarModel()
    }
    
    Component.onCompleted: {
        updateCalendar()
        updateTextField()
    }
    
    onSelectedDateChanged: {
        updateCalendar()
        updateTextField()
        dateSelected()
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 10
        
        Label { 
            text: root.title + ":" 
            font.bold: true
            Layout.preferredWidth: 80
        }
        
        TextField {
            id: dateField
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhDate
            validator: RegularExpressionValidator { regularExpression: /^\d{2}\.\d{2}\.\d{4}$/ }
            
            onTextChanged: {
                if (activeFocus) {
                    var parts = text.split(".")
                    if (parts.length === 3) {
                        var newDate = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
                        if (!isNaN(newDate.getTime()) && newDate.toDateString() !== root.selectedDate.toDateString()) {
                            root.selectedDate = newDate
                        }
                    }
                }
            }
        }
        
        Button {
            text: "📅"
            onClicked: calendarPopup.open()
        }
    }
    
    Popup {
        id: calendarPopup
        width: 250
        height: 220
        x: parent.width - width
        y: parent.height
        modal: true
        focus: true
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 5
            anchors.margins: 5
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "<"
                    onClicked: {
                        var newDate = new Date(_calendarYear, _calendarMonth - 1, 1)
                        _calendarYear = newDate.getFullYear()
                        _calendarMonth = newDate.getMonth()
                        updateCalendarModel()
                    }
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var months = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", 
                                     "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
                        return months[_calendarMonth] + " " + _calendarYear
                    }
                }
                Button {
                    text: ">"
                    onClicked: {
                        var newDate = new Date(_calendarYear, _calendarMonth + 1, 1)
                        _calendarYear = newDate.getFullYear()
                        _calendarMonth = newDate.getMonth()
                        updateCalendarModel()
                    }
                }
            }
            
            GridView {
                id: calendarGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: 30
                cellHeight: 25
                
                property var dayNames: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                
                header: Row {
                    spacing: 5
                    Repeater {
                        model: calendarGrid.dayNames
                        Label {
                            width: 30
                            height: 20
                            text: modelData
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
                
                model: _calendarModel
                delegate: Rectangle {
                    width: 28
                    height: 22
                    color: {
                        if (modelData === "") return "transparent"
                        var cellDate = new Date(_calendarYear, _calendarMonth, modelData)
                        if (cellDate.toDateString() === root.selectedDate.toDateString()) return "#0078d7"
                        return "transparent"
                    }
                    radius: 3
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: parent.color === "#0078d7" ? "white" : "black"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData !== "") {
                                var newDate = new Date(_calendarYear, _calendarMonth, modelData)
                                root.selectedDate = newDate
                                calendarPopup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
