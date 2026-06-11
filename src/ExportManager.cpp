#include "ExportManager.h"
#include "ProjectData.h"
#include <QImage>
#include <QPixmap>
#include <QPainter>
#include <QPrinter>
#include <QPainterPath>

ExportManager::ExportManager(QObject *parent) : QObject(parent) {}

bool ExportManager::exportToPng(ProjectData* project, const QString& filePath, int width, int height) {
    Q_UNUSED(project)
    QImage image(width, height, QImage::Format_ARGB32);
    image.fill(Qt::white);
    
    QPainter painter(&image);
    painter.setPen(Qt::black);
    painter.drawText(QRect(0, 0, width, height), Qt::AlignCenter, 
                     "Gantt Chart Export - Demo");
    painter.end();
    
    bool result = image.save(filePath, "PNG");
    emit exportFinished(result, result ? "Экспорт в PNG выполнен" : "Ошибка экспорта в PNG");
    return result;
}

bool ExportManager::exportToPdf(ProjectData* project, const QString& filePath, const QDate& exportDate) {
    Q_UNUSED(project)
    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(filePath);
    printer.setPageSize(QPageSize(QPageSize::A4));
    printer.setPageOrientation(QPageLayout::Landscape);
    
    QPainter painter(&printer);
    if (!painter.isActive()) {
        emit exportFinished(false, "Ошибка инициализации PDF");
        return false;
    }
    
    int pageWidth = printer.width();
    int pageHeight = printer.height();
    
    painter.setPen(Qt::black);
    QFont titleFont = painter.font();
    titleFont.setPointSize(16);
    titleFont.setBold(true);
    painter.setFont(titleFont);
    painter.drawText(QRect(0, 0, pageWidth, 80), Qt::AlignCenter,
                     (project ? project->get_projectName() : "Проект") + " - Диаграмма Ганта");
    
    QFont dateFont = painter.font();
    dateFont.setPointSize(10);
    painter.setFont(dateFont);
    painter.drawText(QRect(pageWidth - 150, 10, 140, 30), Qt::AlignRight, 
                     "Экспорт: " + exportDate.toString("dd.MM.yyyy"));
    
    int legendY = 90;
    painter.drawText(QRect(20, legendY, 200, 30), "Легенда:");
    
    QStringList legendItems;
    legendItems << "Жёлтый - Запланировано";
    legendItems << "Зелёный - Выполнено";
    legendItems << "Оранжевый - Имеются риски";
    legendItems << "Красный - Блокировано";
    legendItems << "Ромб (жёлтый) - Веха запланирована";
    legendItems << "Ромб (зелёный) - Веха пройдена";
    legendItems << "Ромб (серый) - Веха перенесена";
    
    painter.setFont(dateFont);
    for (int i = 0; i < legendItems.size(); ++i) {
        painter.drawText(QRect(20, legendY + 25 + i * 20, 400, 20), legendItems[i]);
    }
    
    painter.drawText(QRect(0, pageHeight/2, pageWidth, 50), Qt::AlignCenter, 
                     "Диаграмма Ганта будет отображена здесь");
    
    painter.end();
    emit exportFinished(true, "Экспорт в PDF выполнен");
    return true;
}
