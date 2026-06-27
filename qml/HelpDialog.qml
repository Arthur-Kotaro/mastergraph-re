import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0

Dialog
{
    id: root
    title: "Справка"
    width: 1100
    height: 950
    modal: true
    standardButtons: Dialog.Ok
    anchors.centerIn: Overlay.overlay

    ScrollView
    {
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        Column
        {
            width: parent.width - 5
            spacing: 25

            Text
            {
                text: "Мастерграфик – программа для создания и редактирования диаграмм Ганта"
                wrapMode: Text.WordWrap
                font.pixelSize: 28
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 1. Начало работы ──
            Text
            {
                text: "1. Начало работы"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "При запуске программы открывается экран приветствия с двумя кнопками:\n" +
                      "• «Создать новый график» – открывает диалог создания проекта.\n" +
                      "• «Открыть график» – позволяет выбрать сохранённый файл проекта (.gantt).\n\n" +
                      "В диалоге создания проекта необходимо:\n" +
                      "– Ввести название проекта.\n" +
                      "– Выбрать типологию (набор вех) из выпадающего списка.\n" +
                      "– Указать дату начала проекта.\n" +
                      "– Выбрать путь для сохранения файла.\n" +
                      "– Отметить типовые группы задач, которые будут добавлены в график."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 2. Интерфейс редактора ──
            Text
            {
                text: "2. Интерфейс редактора"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "После создания проекта открывается окно редактора, разделённое на области:\n\n" +
                      "Левая панель:\n" +
                      "• Сверху – название проекта и подписи календарных строк.\n" +
                      "• Далее – список групп задач. Каждую группу можно развернуть/свернуть.\n" +
                      "• Внутри группы отображаются задачи с названием, ответственным, датами начала и завершения.\n\n" +
                      "Правая панель:\n" +
                      "• Календарная полоса – годы, месяцы, недели, дни, вехи.\n" +
                      "• Сетка Ганта – полосы задач, цвет которых зависит от статуса:\n" +
                      "  жёлтый – запланирована, зелёный – выполнена, оранжевый – риски, красный – заблокирована.\n" +
                      "• Красная вертикальная линия – текущая дата."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 3. Горячие клавиши ──
            Text
            {
                text: "3. Горячие клавиши"
                font.pixelSize: 32
                font.bold: true
            }

            Column
            {
                spacing: 12
                Row
                {
                    spacing: 80
                    Column
                    {
                        spacing: 12
                        Text { text: "Ctrl+N"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+O"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+S"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+Shift+S"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "F11"; font.bold: true; font.pixelSize: 24 }
                        Text { text: "Ctrl+колесо"; font.bold: true; font.pixelSize: 24 }
                    }
                    Column
                    {
                        spacing: 12
                        Text { text: "Создать новый график"; font.pixelSize: 24; wrapMode: Text.WordWrap; width: 500 }
                        Text { text: "Открыть график"; font.pixelSize: 24 }
                        Text { text: "Сохранить график"; font.pixelSize: 24 }
                        Text { text: "Сохранить как"; font.pixelSize: 24 }
                        Text { text: "Полноэкранный режим"; font.pixelSize: 24 }
                        Text { text: "Масштаб день/неделя"; font.pixelSize: 24 }
                    }
                }
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 4. Работа с задачами ──
            Text
            {
                text: "4. Работа с задачами"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "Добавление одиночной задачи:\n" +
                      "• Правый клик по группе → «Добавить задачу». Откроется диалог ввода названия, ответственного, дат и комментария.\n\n" +
                      "Добавление каскада задач:\n" +
                      "• Кнопка «Добавить каскад» на панели инструментов.\n" +
                      "• Введите количество задач и дату начала первой задачи.\n" +
                      "• Нажмите «Построить» – появится список задач с настройками.\n" +
                      "• Для каждой задачи можно выбрать группу, изменить название, ответственного, длительность и комментарий.\n" +
                      "• Каждая следующая задача автоматически становится зависимой от предыдущей.\n" +
                      "• Нажмите ОК – все задачи создадутся с зависимостями.\n\n" +
                      "Добавление списка задач:\n" +
                      "• Кнопка «Добавить список» на панели инструментов.\n" +
                      "• Введите количество задач и нажмите «Построить».\n" +
                      "• Для каждой задачи настройте группу, название, ответственного, дату начала, длительность и комментарий.\n" +
                      "• Задачи создаются независимо (без зависимостей).\n\n" +
                      "Редактирование задачи:\n" +
                      "• Правый клик по задаче → «Изменить сроки» – диалог с календарём.\n" +
                      "• Перетаскивание полосы Ганта влево/вправо – изменение дат.\n" +
                      "• Перетаскивание правого края полосы – изменение длительности.\n" +
                      "• Правый клик → «Изменить статус» – выбор статуса задачи.\n" +
                      "• При смене статуса на «Выполнено» открывается диалог с датой завершения.\n\n" +
                      "Удаление задачи:\n" +
                      "• Правый клик по задаче → «Удалить»."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 5. Работа с вехами ──
            Text
            {
                text: "5. Работа с вехами"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "Вехи отображаются в календарной полосе цветными ромбами с подписью.\n\n" +
                      "• Наведение мыши на веху – всплывающая подсказка с названием, статусом и датой.\n" +
                      "• Правый клик по вехе – контекстное меню:\n" +
                      "  – «Пройти веху» – подтверждение с кнопками Да/Нет.\n" +
                      "  – «Перенести веху» – диалог ввода новой даты.\n" +
                      "  – «Подробнее» – информация о вехе и список переносов.\n\n" +
                      "• При переносе вехи на старом месте остаётся серая веха.\n" +
                      "• Кнопка «Переносы» на панели инструментов показывает/скрывает серые вехи и историю задач."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 6. Зависимости ──
            Text
            {
                text: "6. Зависимости между задачами"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "Зависимости отображаются фиолетовыми стрелками от конца одной задачи к началу другой.\n\n" +
                      "• Правый клик по задаче → «Изменить зависимости»:\n" +
                      "  – «Добавить нисходящую зависимость» – текущая задача станет предшественником выбранной.\n" +
                      "  – «Добавить восходящую зависимость» – текущая задача станет зависимой от выбранной.\n" +
                      "  – «Удалить нисходящую/восходящую зависимость» – удаление связи.\n\n" +
                      "• Кнопка «Зависимости» на панели инструментов показывает/скрывает стрелки."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 7. Комментарии ──
            Text
            {
                text: "7. Комментарии к задачам"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "• Правый клик по задаче → «Изменить комментарий» – открывает диалог ввода текста.\n" +
                      "• Комментарий отображается справа от полосы Ганта и во всплывающей подсказке.\n" +
                      "• Кнопка «Комментарии» на панели инструментов показывает/скрывает текст комментариев."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 8. Панель инструментов ──
            Text
            {
                text: "8. Кнопки панели инструментов"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "• Блокировка – включение/выключение режима запрета редактирования.\n" +
                      "  В режиме блокировки нельзя перетаскивать полосы, менять сроки, добавлять/удалять задачи.\n\n" +
                      "• Зависимости – отображение/скрытие стрелок зависимостей.\n\n" +
                      "• Переносы – отображение/скрытие истории переносов задач и вех (серые полосы и ромбы).\n\n" +
                      "• Комментарии – отображение/скрытие текста комментариев рядом с полосами Ганта.\n\n" +
                      "• 🔄 (Обновить) – принудительная перерисовка графика.\n" +
                      "  Полезна, если после масштабирования вехи или полосы отображаются некорректно."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 9. Масштабирование ──
            Text
            {
                text: "9. Масштабирование"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "• Меню Вид → «Масштаб: День» / «Масштаб: Неделя» – переключение режима.\n" +
                      "• Ctrl + колесо мыши – быстрое переключение масштаба.\n" +
                      "• В режиме «Неделя» подписи дней скрываются для экономии места.\n" +
                      "• При смене масштаба нажмите кнопку 🔄 для полной перерисовки графика."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 10. Группы задач ──
            Text
            {
                text: "10. Управление группами задач"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "• Правый клик по группе → контекстное меню:\n" +
                      "  – «Добавить задачу» – создание задачи в этой группе.\n" +
                      "  – «Переименовать» – изменение названия группы.\n" +
                      "  – «Добавить группу сверху/снизу» – создание новой группы.\n" +
                      "  – «Удалить» – удаление группы и всех задач в ней."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 11. Сохранение и открытие ──
            Text
            {
                text: "11. Сохранение и открытие проектов"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "• Файл → «Сохранить» (Ctrl+S) – сохранение текущего проекта.\n" +
                      "• Файл → «Сохранить как» (Ctrl+Shift+S) – сохранение в новый файл.\n" +
                      "• Файл → «Открыть» (Ctrl+O) – открытие сохранённого проекта.\n" +
                      "• Проекты сохраняются в формате JSON с расширением .gantt.\n" +
                      "• При открытии проекта восстанавливаются все задачи, вехи, зависимости, комментарии и история переносов."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }

            Rectangle { height: 2; Layout.fillWidth: true; color: "#cccccc"; width: parent.width }

            // ── 12. Ресурсные файлы ──
            Text
            {
                text: "12. Ресурсные файлы"
                font.pixelSize: 32
                font.bold: true
            }

            Text
            {
                text: "Программа использует JSON-файлы для хранения типологий проектов и шаблонов задач. " +
                      "Путь к ресурсам можно изменить в меню Настройки → Изменить пути ресурсных файлов."
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                width: parent.width
            }
        }
    }
}
