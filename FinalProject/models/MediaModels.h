#pragma once

#include <QString>
#include <QVector>

struct MediaItem
{
    QString title;
    QString genre;
    QString duration;
    QString rating;
    QString description;
    QString accentColor;
    QString thumbnailUrl;
    QString videoUrl;
};

struct MediaCategory
{
    QString name;
    QVector<MediaItem> items;
};
