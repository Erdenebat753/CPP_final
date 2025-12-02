#include "StreamingDataModel.h"

#include "../shared/DatabaseUtils.h"

#include <QSqlDatabase>
#include <QSqlQuery>

StreamingDataModel::StreamingDataModel()
{
    loadData();
}

const MediaItem &StreamingDataModel::featuredItem() const
{
    return m_featured;
}

const QVector<MediaCategory> &StreamingDataModel::categories() const
{
    return m_categories;
}

void StreamingDataModel::loadData()
{
    m_categories.clear();
    m_featured = {};

    if (!DatabaseUtils::ensureDatabase())
    {
        return;
    }

    QSqlDatabase db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-model"));
    if (!db.isOpen())
    {
        return;
    }

    QSqlQuery heroQuery(db);
    const QString heroSql = QStringLiteral(
        "SELECT t.id, t.type, t.name, t.description, t.age_rating, t.runtime_min, t.accent_color, "
        "IFNULL(m.thumbnail_url, '') AS thumbnail_url, IFNULL(m.video_url, '') AS video_url, "
        "IFNULL((SELECT g.name FROM genres g JOIN title_genres tg ON tg.genre_id = g.id "
        "WHERE tg.title_id = t.id ORDER BY g.name LIMIT 1), '') AS primary_genre "
        "FROM titles t LEFT JOIN media_files m ON m.title_id = t.id "
        "ORDER BY t.created_at DESC LIMIT 1"
    );
    if (heroQuery.exec(heroSql) && heroQuery.next())
    {
        m_featured = buildItemFromQuery(heroQuery, heroQuery.value(8).toString());
    }

    QSqlQuery genresQuery(db);
    if (!genresQuery.exec(QStringLiteral("SELECT id, name FROM genres ORDER BY name")))
    {
        return;
    }

    while (genresQuery.next())
    {
        MediaCategory category;
        const int genreId = genresQuery.value(0).toInt();
        category.name = genresQuery.value(1).toString();
        category.items = itemsForGenre(genreId, category.name, db);
        if (!category.items.isEmpty())
        {
            m_categories.append(category);
        }
    }

    if (m_featured.title.isEmpty() && !m_categories.isEmpty() && !m_categories.first().items.isEmpty())
    {
        m_featured = m_categories.first().items.first();
    }
}

MediaItem StreamingDataModel::buildItemFromQuery(const QSqlQuery &query, const QString &genreName) const
{
    MediaItem item;
    item.type = query.value(1).toString();
    item.title = query.value(2).toString();
    item.genre = genreName;
    item.description = query.value(3).toString();
    item.rating = query.value(4).toString();
    item.duration = formatDuration(query.value(5).toInt());
    item.accentColor = query.value(6).toString();
    item.thumbnailUrl = query.value(7).toString();
    item.videoUrl = query.value(8).toString();
    return item;
}

QVector<MediaItem> StreamingDataModel::itemsForGenre(int genreId, const QString &genreName, QSqlDatabase &db) const
{
    QVector<MediaItem> items;
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT t.id, t.type, t.name, t.description, t.age_rating, t.runtime_min, t.accent_color, "
        "IFNULL(m.thumbnail_url, ''), IFNULL(m.video_url, '') "
        "FROM titles t "
        "JOIN title_genres tg ON tg.title_id = t.id "
        "LEFT JOIN media_files m ON m.title_id = t.id "
        "WHERE tg.genre_id = ? ORDER BY t.created_at DESC"));
    query.addBindValue(genreId);

    if (!query.exec())
    {
        return items;
    }

    while (query.next())
    {
        items.append(buildItemFromQuery(query, genreName));
    }
    return items;
}

QString StreamingDataModel::formatDuration(int minutes) const
{
    if (minutes <= 0)
    {
        return QString();
    }

    const int hours = minutes / 60;
    const int mins = minutes % 60;
    if (hours == 0)
    {
        return QStringLiteral("%1m").arg(minutes);
    }

    return mins > 0 ? QStringLiteral("%1h %2m").arg(hours).arg(mins)
                    : QStringLiteral("%1h").arg(hours);
}
