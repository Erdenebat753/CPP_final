#include "StreamingService.h"

#include <algorithm>
#include <utility>

StreamingService::StreamingService(std::unique_ptr<IDataProvider> provider)
    : m_provider(std::move(provider))
{
    reload();
}

void StreamingService::reload()
{
    m_categories.clear();
    m_featured = {};

    if (!m_provider)
    {
        return;
    }

    const auto categories = m_provider->fetchCategories();
    m_categories.reserve(categories.size());
    for (const auto &category : categories)
    {
        MediaCategory mediaCategory;
        mediaCategory.name = category.category.name;
        mediaCategory.items.reserve(category.items.size());
        for (const auto &rawItem : category.items)
        {
            mediaCategory.items.push_back(toMediaItem(rawItem));
        }

        if (!mediaCategory.items.empty())
        {
            m_categories.push_back(std::move(mediaCategory));
        }
    }

    const auto featured = m_provider->fetchFeatured();
    if (featured.has_value())
    {
        m_featured = toMediaItem(*featured);
    }
    else if (!m_categories.empty() && !m_categories.front().items.empty())
    {
        m_featured = m_categories.front().items.front();
    }
}

const MediaItem &StreamingService::featuredItem() const
{
    return m_featured;
}

const std::vector<MediaCategory> &StreamingService::categories() const
{
    return m_categories;
}

MediaItem StreamingService::toMediaItem(const RawMediaItem &raw) const
{
    MediaItem item;
    item.type = raw.type;
    item.title = raw.title;
    item.genre = raw.genre;
    item.description = raw.description;
    item.rating = raw.rating;
    item.duration = formatDuration(raw.durationMinutes);
    item.accentColor = raw.accentColor;
    item.thumbnailUrl = raw.thumbnailUrl;
    item.videoUrl = raw.videoUrl;
    return item;
}

std::string StreamingService::formatDuration(int minutes)
{
    if (minutes <= 0)
    {
        return {};
    }

    const int hours = minutes / 60;
    const int mins = minutes % 60;
    if (hours == 0)
    {
        return std::to_string(minutes) + "m";
    }

    return mins > 0 ? std::to_string(hours) + "h " + std::to_string(mins) + "m"
                    : std::to_string(hours) + "h";
}
