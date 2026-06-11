import QtQuick 6.0
import QtQuick.Controls 6.0

Button {
    property Menu menu: null
    flat: true
    onClicked: { if (menu) menu.popup(root.x, root.y + root.height) }
}
