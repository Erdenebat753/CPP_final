#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QVariant>

#include "models/StreamingDataModel.h"
#include "shared/DatabaseUtils.h"

namespace
{
QVariantMap toVariantMap(const MediaItem &item)
{
    QVariantMap map;
    map.insert(QStringLiteral("title"), item.title);
    map.insert(QStringLiteral("genre"), item.genre);
    map.insert(QStringLiteral("duration"), item.duration);
    map.insert(QStringLiteral("rating"), item.rating);
    map.insert(QStringLiteral("description"), item.description);
    map.insert(QStringLiteral("accentColor"), item.accentColor);
    map.insert(QStringLiteral("thumbnailUrl"), DatabaseUtils::toFileUrl(item.thumbnailUrl));
    map.insert(QStringLiteral("videoUrl"), DatabaseUtils::toFileUrl(item.videoUrl));
    return map;
}

QVariantList toVariantList(const QVector<MediaItem> &items)
{
    QVariantList list;
    list.reserve(items.size());
    for (const auto &item : items)
    {
        list.append(toVariantMap(item));
    }
    return list;
}

QVariantList buildCategories(const QVector<MediaCategory> &categories)
{
    QVariantList list;
    list.reserve(categories.size());
    for (const auto &category : categories)
    {
        QVariantMap map;
        map.insert(QStringLiteral("name"), category.name);
        map.insert(QStringLiteral("items"), toVariantList(category.items));
        list.append(map);
    }
    return list;
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    StreamingDataModel dataModel;
    const QVariantMap heroItem = toVariantMap(dataModel.featuredItem());
    const QVariantList categories = buildCategories(dataModel.categories());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("heroItem"), heroItem);
    engine.rootContext()->setContextProperty(QStringLiteral("categoriesModel"), categories);

    const QUrl url(QStringLiteral("qrc:/qt/qml/finalproject/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
