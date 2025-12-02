#pragma once

#include <string>
#include <vector>

struct MediaItem
{
    std::string type;
    std::string title;
    std::string genre;
    std::string duration;
    std::string rating;
    std::string description;
    std::string accentColor;
    std::string thumbnailUrl;
    std::string videoUrl;
};

struct MediaCategory
{
    std::string name;
    std::vector<MediaItem> items;
};
