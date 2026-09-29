import QtQuick 6.0

Rectangle
{
    id: root
    width: 2
    height: parent ? parent.height : 100
    color: "#2266cc"   // синий
    visible: false
    z: 9

    // Показать стрелки сверху и снизу
    property bool showArrows: false
    // Направление стрелки: "right" (->) или "left" (<-)
    property string arrowDirection: "right"

    // Верхняя стрелка
    Rectangle
    {
        visible: root.showArrows
        width: 12
        height: 2
        color: root.color
        x: root.arrowDirection === "right" ? 0 : -10
        y: 6

        // Наконечник
        Rectangle
        {
            width: 6
            height: 6
            color: root.color
            rotation: 45
            x: root.arrowDirection === "right" ? 8 : -2
            y: -2
        }
    }

    // Нижняя стрелка
    Rectangle
    {
        visible: root.showArrows
        width: 12
        height: 2
        color: root.color
        x: root.arrowDirection === "right" ? 0 : -10
        y: root.height - 8

        Rectangle
        {
            width: 6
            height: 6
            color: root.color
            rotation: 45
            x: root.arrowDirection === "right" ? 8 : -2
            y: -2
        }
    }
}
