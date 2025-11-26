#pragma once

#include "MediaModels.h"

class QSqlDatabase;
class QSqlQuery;

class StreamingDataModel
{
public:
    StreamingDataModel();

    const MediaItem &featuredItem() const;
    const QVector<MediaCategory> &categories() const;

private:
    void loadData();
    MediaItem buildItemFromQuery(const QSqlQuery &query, const QString &genreName) const;
    QVector<MediaItem> itemsForGenre(int genreId, const QString &genreName, QSqlDatabase &db) const;
    QString formatDuration(int minutes) const;

    MediaItem m_featured;
    QVector<MediaCategory> m_categories;
};
