import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog {
    id: root
    title: "Справка"
    width: 1100
    height: 950
    modal: true
    standardButtons: Dialog.Ok
    anchors.centerIn: Overlay.overlay

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        clip: true

        Column {
            width: parent.width - 40
            spacing: 25

            Text { 
                text: "Мастерграфик – программа для создания и редактирования диаграмм Ганта"
                wrapMode: Text.WordWrap
                font.pixelSize: 28
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            Text { 
                text: "Горячие клавиши"
                font.pixelSize: 32
                font.bold: true
            }
            
            Column { 
                spacing: 12
                Row { 
                    spacing: 80
                    Column { 
                        spacing: 12
                        Text { text: "Ctrl+N"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+O"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+S"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+Shift+S"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "F1"; font.bold: true; font.pixelSize: 24 }
                    }
                    Column { 
                        spacing: 12
                        Text { text: "Создать новый график"; font.pixelSize: 24; wrapMode: Text.WordWrap; width: 400 }
                        Text { text: "Открыть график"; font.pixelSize: 24 }
                        Text { text: "Сохранить график"; font.pixelSize: 24 }
                        Text { text: "Сохранить как"; font.pixelSize: 24 }
                        Text { text: "Полноэкранный режим"; font.pixelSize: 24 }
                    }
                }
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            Text { 
                text: "Управление диаграммой"
                font.pixelSize: 32
                font.bold: true
            }
            
            Text { 
                text: "• Перетаскивание полосы Ганта – изменение сроков задачи\n• Изменение правого края полосы – изменение длительности\n• Правый клик по задаче – контекстное меню\n• Правый клик по группе – управление группой\n• Правый клик по вехе – управление вехой\n• Ctrl + колесо мыши – масштабирование календаря"
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            Text { 
                text: "Ресурсные файлы"
                font.pixelSize: 32
                font.bold: true
            }
            
            Text { 
                text: "Программа использует JSON-файлы для хранения типологий проектов и шаблонов задач. Путь к ресурсам можно изменить в меню Настройки → Изменить пути ресурсных файлов."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }
        }
    }
}
