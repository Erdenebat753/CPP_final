#pragma once

#include "DataProvider.h"

#include <memory>

class StreamingService
{
public:
    explicit StreamingService(std::unique_ptr<IDataProvider> provider);

    void reload();

    const MediaItem &featuredItem() const;
    const std::vector<MediaCategory> &categories() const;

private:
    std::unique_ptr<IDataProvider> m_provider;
    MediaItem m_featured;
    std::vector<MediaCategory> m_categories;

    MediaItem toMediaItem(const RawMediaItem &raw) const;
    static std::string formatDuration(int minutes);
};
