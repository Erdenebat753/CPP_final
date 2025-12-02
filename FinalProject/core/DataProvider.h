#pragma once

#include "MediaModels.h"

#include <optional>
#include <vector>

struct RawMediaItem
{
    std::string type;
    std::string title;
    std::string genre;
    int durationMinutes{};
    std::string rating;
    std::string description;
    std::string accentColor;
    std::string thumbnailUrl;
    std::string videoUrl;
};

struct RawCategory
{
    int id{};
    std::string name;
};

struct CategoryWithItems
{
    RawCategory category;
    std::vector<RawMediaItem> items;
};

class IDataProvider
{
public:
    virtual ~IDataProvider() = default;

    virtual std::optional<RawMediaItem> fetchFeatured() = 0;
    virtual std::vector<CategoryWithItems> fetchCategories() = 0;
};
