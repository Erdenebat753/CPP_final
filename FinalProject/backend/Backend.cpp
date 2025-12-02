#include "Backend.h"

#include "../shared/DatabaseUtils.h"

#include <QDebug>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <memory>
#include <utility>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QString>
#include <QSqlError>
#include <QUrl>
#include <QDate>

namespace
{
QString copyMediaFile(const QString &sourcePath, const QString &targetDir, const QString &prefix)
{
    const QString trimmed = sourcePath.trimmed();
    if (trimmed.isEmpty())
    {
        return QString();
    }

    const QUrl url(trimmed);
    const QString localPath = url.isLocalFile() ? url.toLocalFile() : trimmed;

    QFileInfo info(localPath);
    if (!info.exists() || !info.isFile())
    {
        return QString();
    }

    QDir dir(targetDir);
    if (!dir.exists() && !dir.mkpath(QStringLiteral(".")))
    {
        return QString();
    }

    const QString ext = info.suffix().isEmpty() ? QStringLiteral("dat") : info.suffix();
    const QString baseName = info.completeBaseName().isEmpty() ? prefix : info.completeBaseName();
    const QString stamp = QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMddHHmmsszzz"));
    const QString fileName = QStringLiteral("%1_%2.%3").arg(baseName).arg(stamp).arg(ext);
    const QString destination = dir.filePath(fileName);
    QFile::remove(destination);
    if (!QFile::copy(info.absoluteFilePath(), destination))
    {
        return QString();
    }

    const QString projectRoot = QDir(DatabaseUtils::projectRoot()).filePath(QStringLiteral("FinalProject"));
    return QDir(projectRoot).relativeFilePath(destination);
}

class QtSqlDataProvider : public IDataProvider
{
public:
    QtSqlDataProvider()
    {
        DatabaseUtils::ensureDatabase();
        m_db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-backend"));
    }

    std::optional<RawMediaItem> fetchFeatured() override
    {
        if (!m_db.isOpen())
        {
            return std::nullopt;
        }

        QSqlQuery query(m_db);
        const QString heroSql = QStringLiteral(
            "SELECT t.id, t.type, t.name, t.description, t.age_rating, t.runtime_min, t.accent_color, "
            "IFNULL(m.thumbnail_url, '') AS thumbnail_url, IFNULL(m.video_url, '') AS video_url, "
            "IFNULL((SELECT g.name FROM genres g JOIN title_genres tg ON tg.genre_id = g.id "
            "WHERE tg.title_id = t.id ORDER BY g.name LIMIT 1), '') AS primary_genre "
            "FROM titles t LEFT JOIN media_files m ON m.title_id = t.id "
            "ORDER BY t.created_at DESC LIMIT 1");

        if (!query.exec(heroSql) || !query.next())
        {
            return std::nullopt;
        }

        return buildItem(query, query.value(8).toString().toStdString());
    }

    std::vector<CategoryWithItems> fetchCategories() override
    {
        std::vector<CategoryWithItems> result;
        if (!m_db.isOpen())
        {
            return result;
        }

        QSqlQuery genresQuery(m_db);
        if (!genresQuery.exec(QStringLiteral("SELECT id, name FROM genres ORDER BY name")))
        {
            return result;
        }

        while (genresQuery.next())
        {
            CategoryWithItems item;
            item.category.id = genresQuery.value(0).toInt();
            item.category.name = genresQuery.value(1).toString().toStdString();
            item.items = itemsForGenre(item.category.id, item.category.name);
            if (!item.items.empty())
            {
                result.push_back(std::move(item));
            }
        }

        return result;
    }

private:
    QSqlDatabase m_db;

    std::vector<RawMediaItem> itemsForGenre(int genreId, const std::string &genreName)
    {
        std::vector<RawMediaItem> items;
        QSqlQuery query(m_db);
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
            items.push_back(buildItem(query, genreName));
        }

        return items;
    }

    RawMediaItem buildItem(const QSqlQuery &query, const std::string &genreName)
    {
        RawMediaItem item;
        item.type = query.value(1).toString().toStdString();
        item.title = query.value(2).toString().toStdString();
        item.genre = genreName;
        item.description = query.value(3).toString().toStdString();
        item.rating = query.value(4).toString().toStdString();
        item.durationMinutes = query.value(5).toInt();
        item.accentColor = query.value(6).toString().toStdString();
        item.thumbnailUrl = DatabaseUtils::toFileUrl(query.value(7).toString()).toStdString();
        item.videoUrl = DatabaseUtils::toFileUrl(query.value(8).toString()).toStdString();
        return item;
    }
};

class QtAuthRepository : public IAuthRepository
{
public:
    QtAuthRepository()
    {
        DatabaseUtils::ensureDatabase();
        m_db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-auth"));
        ensureRoleColumn();
        ensureAdminUser("admin", "admin1234");
    }

    bool ensureAdminUser(const std::string &identifier, const std::string &password) override
    {
        if (!ensureOpen())
        {
            return false;
        }
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("SELECT id FROM users WHERE email = ? LIMIT 1"));
        query.addBindValue(QString::fromStdString(identifier));
        if (query.exec() && query.next())
        {
            return true;
        }

        QSqlQuery insert(m_db);
        insert.prepare(QStringLiteral("INSERT INTO users (email, password, role) VALUES (?, ?, 'admin')"));
        insert.addBindValue(QString::fromStdString(identifier));
        insert.addBindValue(QString::fromStdString(password));
        return insert.exec();
    }

    std::optional<AuthUser> findUser(const std::string &identifier, const std::string &password) override
    {
        std::optional<AuthUser> result;
        if (!ensureOpen())
        {
            return result;
        }

        QSqlQuery query(m_db);
        query.prepare(QStringLiteral("SELECT role FROM users WHERE email = ? AND password = ? LIMIT 1"));
        query.addBindValue(QString::fromStdString(identifier));
        query.addBindValue(QString::fromStdString(password));

        if (query.exec() && query.next())
        {
            AuthUser user;
            user.identifier = identifier;
            user.role = query.value(0).toString().toStdString();
            result = user;
        }
        return result;
    }

    std::optional<AuthUser> createUser(const std::string &identifier, const std::string &password) override
    {
        std::optional<AuthUser> result;
        if (!ensureOpen())
        {
            return result;
        }

        if (identifier == "admin")
        {
            return result;
        }

        QSqlQuery exists(m_db);
        exists.prepare(QStringLiteral("SELECT id FROM users WHERE email = ? LIMIT 1"));
        exists.addBindValue(QString::fromStdString(identifier));
        if (exists.exec() && exists.next())
        {
            return result;
        }

        QSqlQuery insert(m_db);
        insert.prepare(QStringLiteral("INSERT INTO users (email, password, role) VALUES (?, ?, 'user')"));
        insert.addBindValue(QString::fromStdString(identifier));
        insert.addBindValue(QString::fromStdString(password));
        if (insert.exec())
        {
            AuthUser user;
            user.identifier = identifier;
            user.role = "user";
            result = user;
        }
        return result;
    }

private:
    QSqlDatabase m_db;

    bool ensureOpen()
    {
        return m_db.isOpen() || m_db.open();
    }

    void ensureRoleColumn()
    {
        if (!ensureOpen())
        {
            return;
        }

        QSqlQuery infoQuery(m_db);
        if (!infoQuery.exec(QStringLiteral("PRAGMA table_info(users)")))
        {
            return;
        }

        bool hasRole = false;
        while (infoQuery.next())
        {
            if (infoQuery.value(1).toString() == QStringLiteral("role"))
            {
                hasRole = true;
                break;
            }
        }

        if (!hasRole)
        {
            QSqlQuery alter(m_db);
            alter.exec(QStringLiteral("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user'"));
        }
    }
};

QVariantMap makeVariantItem(const MediaItem &item)
{
    QVariantMap map;
    map.insert(QStringLiteral("type"), QString::fromStdString(item.type));
    map.insert(QStringLiteral("title"), QString::fromStdString(item.title));
    map.insert(QStringLiteral("genre"), QString::fromStdString(item.genre));
    map.insert(QStringLiteral("duration"), QString::fromStdString(item.duration));
    map.insert(QStringLiteral("rating"), QString::fromStdString(item.rating));
    map.insert(QStringLiteral("description"), QString::fromStdString(item.description));
    map.insert(QStringLiteral("accentColor"), QString::fromStdString(item.accentColor));
    map.insert(QStringLiteral("thumbnailUrl"), QString::fromStdString(item.thumbnailUrl));
    map.insert(QStringLiteral("videoUrl"), QString::fromStdString(item.videoUrl));
    return map;
}
} // namespace

Backend::Backend(std::unique_ptr<IDataProvider> provider, QObject *parent)
    : QObject(parent)
    , m_service(std::move(provider))
    , m_authRepository(std::make_unique<QtAuthRepository>())
    , m_authService(m_authRepository.get())
{
}

void Backend::reload()
{
    m_service.reload();
    emit dataChanged();
}

QVariantMap Backend::heroItem() const
{
    return toVariant(m_service.featuredItem());
}

QVariantList Backend::categories() const
{
    return toVariant(m_service.categories());
}

QVariantMap Backend::authenticate(const QString &mode,
                                  const QString &role,
                                  const QString &identifier,
                                  const QString &password,
                                  const QString &confirmPassword)
{
    const auto result = m_authService.authenticate(mode.toStdString(),
                                                   role.toStdString(),
                                                   identifier.toStdString(),
                                                   password.toStdString(),
                                                   confirmPassword.toStdString());

    QVariantMap map;
    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("message"), QString::fromStdString(result.message));
    map.insert(QStringLiteral("role"), QString::fromStdString(result.role.empty() ? "user" : result.role));
    return map;
}

QVariantList Backend::listUsers() const
{
    QVariantList users;
    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-admin-list"));
    if (!db.isOpen())
    {
        return users;
    }

    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT email, role, created_at FROM users ORDER BY created_at DESC")))
    {
        return users;
    }

    while (query.next())
    {
        QVariantMap user;
        user.insert(QStringLiteral("email"), query.value(0).toString());
        user.insert(QStringLiteral("role"), query.value(1).toString());
        user.insert(QStringLiteral("createdAt"), query.value(2).toString());
        users.append(user);
    }
    return users;
}

QVariantList Backend::listGenres() const
{
    QVariantList genres;
    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-admin-genres"));
    if (!db.isOpen())
    {
        return genres;
    }

    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT name FROM genres ORDER BY name")))
    {
        return genres;
    }

    while (query.next())
    {
        genres.append(query.value(0).toString());
    }
    return genres;
}

QVariantMap Backend::addGenre(const QString &name)
{
    QVariantMap result;
    result.insert(QStringLiteral("success"), false);

    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-admin-add-genre"));
    if (!db.isOpen())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Database unavailable"));
        return result;
    }

    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Genre name is required"));
        return result;
    }

    QSqlQuery exists(db);
    exists.prepare(QStringLiteral("SELECT id FROM genres WHERE lower(name) = lower(?) LIMIT 1"));
    exists.addBindValue(trimmed);
    if (exists.exec() && exists.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Genre already exists"));
        return result;
    }

    QSqlQuery insert(db);
    insert.prepare(QStringLiteral("INSERT INTO genres (name) VALUES (?)"));
    insert.addBindValue(trimmed);
    if (!insert.exec())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Failed to add genre"));
        return result;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("message"), QStringLiteral("Genre added"));
    return result;
}

QVariantMap Backend::addMovie(const QString &name,
                              const QString &description,
                              const QString &genre,
                              int runtimeMinutes,
                              const QString &thumbnailPath,
                              const QString &videoPath)
{
    QVariantMap result;
    result.insert(QStringLiteral("success"), false);

    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-admin-add"));
    if (!db.isOpen())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Database unavailable"));
        return result;
    }

    const QString trimmedName = name.trimmed();
    if (trimmedName.isEmpty())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Name is required"));
        return result;
    }

    const QString trimmedGenre = genre.trimmed();
    if (trimmedGenre.isEmpty())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Genre is required"));
        return result;
    }

    DatabaseUtils::ensureStorageDirectories();

    QSqlQuery genreQuery(db);
    genreQuery.prepare(QStringLiteral("SELECT id FROM genres WHERE name = ? LIMIT 1"));
    genreQuery.addBindValue(trimmedGenre);

    int genreId = -1;
    if (genreQuery.exec() && genreQuery.next())
    {
        genreId = genreQuery.value(0).toInt();
    }
    else
    {
        QSqlQuery insertGenre(db);
        insertGenre.prepare(QStringLiteral("INSERT INTO genres (name) VALUES (?)"));
        insertGenre.addBindValue(trimmedGenre);
        if (insertGenre.exec())
        {
            genreId = insertGenre.lastInsertId().toInt();
        }
    }

    QSqlQuery titleQuery(db);
    titleQuery.prepare(QStringLiteral(
        "INSERT INTO titles (type, name, description, age_rating, runtime_min, accent_color) "
        "VALUES ('movie', ?, ?, 'PG', ?, ?)"));
    titleQuery.addBindValue(trimmedName);
    titleQuery.addBindValue(description.trimmed());
    titleQuery.addBindValue(runtimeMinutes);
    titleQuery.addBindValue(QStringLiteral("#4F46E5"));

    if (!titleQuery.exec())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Failed to insert title"));
        return result;
    }

    const int titleId = titleQuery.lastInsertId().toInt();

    if (genreId > 0)
    {
        QSqlQuery linkQuery(db);
        linkQuery.prepare(QStringLiteral("INSERT INTO title_genres (title_id, genre_id) VALUES (?, ?)"));
        linkQuery.addBindValue(titleId);
        linkQuery.addBindValue(genreId);
        linkQuery.exec();
    }

    const QString storedVideoPath = copyMediaFile(videoPath, DatabaseUtils::videosDirectory(), QStringLiteral("video"));
    const QString storedThumbnailPath = copyMediaFile(thumbnailPath, DatabaseUtils::imagesDirectory(), QStringLiteral("thumb"));

    QSqlQuery mediaQuery(db);
    mediaQuery.prepare(QStringLiteral(
        "INSERT INTO media_files (title_id, video_url, thumbnail_url) VALUES (?, ?, ?)"));
    mediaQuery.addBindValue(titleId);
    mediaQuery.addBindValue(storedVideoPath);
    mediaQuery.addBindValue(storedThumbnailPath);
    mediaQuery.exec();

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("message"), QStringLiteral("Movie added"));

    // refresh cache for UI
    m_service.reload();
    emit dataChanged();
    return result;
}

QVariantMap Backend::userProfile(const QString &identifier) const
{
    QVariantMap result;
    result.insert(QStringLiteral("success"), false);

    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-user-profile"));
    if (!db.isOpen())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Database unavailable"));
        return result;
    }

    const QString email = identifier.trimmed();
    if (email.isEmpty())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Identifier is required"));
        return result;
    }

    QSqlQuery userQuery(db);
    userQuery.prepare(QStringLiteral("SELECT id, email, created_at, role FROM users WHERE email = ? LIMIT 1"));
    userQuery.addBindValue(email);
    if (!userQuery.exec() || !userQuery.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("User not found"));
        return result;
    }

    const int userId = userQuery.value(0).toInt();
    QVariantMap userInfo;
    userInfo.insert(QStringLiteral("email"), userQuery.value(1).toString());
    userInfo.insert(QStringLiteral("createdAt"), userQuery.value(2).toString());
    userInfo.insert(QStringLiteral("role"), userQuery.value(3).toString());
    result.insert(QStringLiteral("user"), userInfo);

    QVariantMap subscription;
    QSqlQuery subQuery(db);
    subQuery.prepare(QStringLiteral(
        "SELECT sp.name, sp.price_month, sp.duration_days, sp.max_quality, "
        "us.start_date, us.end_date, us.is_active "
        "FROM user_subscriptions us "
        "JOIN subscription_plans sp ON sp.id = us.plan_id "
        "WHERE us.user_id = ? "
        "ORDER BY us.created_at DESC LIMIT 1"));
    subQuery.addBindValue(userId);
    if (subQuery.exec() && subQuery.next())
    {
        subscription.insert(QStringLiteral("planName"), subQuery.value(0).toString());
        subscription.insert(QStringLiteral("priceMonth"), subQuery.value(1).toDouble());
        subscription.insert(QStringLiteral("durationDays"), subQuery.value(2).toInt());
        subscription.insert(QStringLiteral("maxQuality"), subQuery.value(3).toString());
        subscription.insert(QStringLiteral("startDate"), subQuery.value(4).toString());
        subscription.insert(QStringLiteral("endDate"), subQuery.value(5).toString());
        subscription.insert(QStringLiteral("active"), subQuery.value(6).toInt() != 0);
    }
    result.insert(QStringLiteral("subscription"), subscription);

    QVariantList profiles;
    QSqlQuery profilesQuery(db);
    profilesQuery.prepare(QStringLiteral(
        "SELECT id, name, avatar_url, is_kid, created_at FROM profiles "
        "WHERE user_id = ? ORDER BY created_at DESC"));
    profilesQuery.addBindValue(userId);
    if (profilesQuery.exec())
    {
        while (profilesQuery.next())
        {
            QVariantMap p;
            p.insert(QStringLiteral("id"), profilesQuery.value(0).toInt());
            p.insert(QStringLiteral("name"), profilesQuery.value(1).toString());
            p.insert(QStringLiteral("avatarUrl"), DatabaseUtils::toFileUrl(profilesQuery.value(2).toString()));
            p.insert(QStringLiteral("isKid"), profilesQuery.value(3).toInt() != 0);
            p.insert(QStringLiteral("createdAt"), profilesQuery.value(4).toString());
            profiles.append(p);
        }
    }
    result.insert(QStringLiteral("profiles"), profiles);

    QVariantList history;
    QSqlQuery historyQuery(db);
    historyQuery.prepare(QStringLiteral(
        "SELECT t.name, t.runtime_min, IFNULL(m.thumbnail_url, ''), IFNULL(m.video_url, ''), "
        "wh.position_sec, wh.is_finished, wh.updated_at "
        "FROM watch_history wh "
        "JOIN titles t ON t.id = wh.title_id "
        "LEFT JOIN media_files m ON m.title_id = t.id "
        "WHERE wh.profile_id IN (SELECT id FROM profiles WHERE user_id = ?) "
        "ORDER BY wh.updated_at DESC LIMIT 15"));
    historyQuery.addBindValue(userId);
    if (historyQuery.exec())
    {
        while (historyQuery.next())
        {
            QVariantMap h;
            h.insert(QStringLiteral("title"), historyQuery.value(0).toString());
            h.insert(QStringLiteral("runtime"), historyQuery.value(1).toInt());
            h.insert(QStringLiteral("thumbnailUrl"), DatabaseUtils::toFileUrl(historyQuery.value(2).toString()));
            h.insert(QStringLiteral("videoUrl"), DatabaseUtils::toFileUrl(historyQuery.value(3).toString()));
            h.insert(QStringLiteral("positionSec"), historyQuery.value(4).toInt());
            h.insert(QStringLiteral("finished"), historyQuery.value(5).toInt() != 0);
            h.insert(QStringLiteral("updatedAt"), historyQuery.value(6).toString());
            history.append(h);
        }
    }
    result.insert(QStringLiteral("history"), history);

    QVariantList myList;
    QSqlQuery listQuery(db);
    listQuery.prepare(QStringLiteral(
        "SELECT t.name, IFNULL(m.thumbnail_url, ''), IFNULL(m.video_url, ''), "
        "t.runtime_min, t.accent_color, l.added_at "
        "FROM my_list l "
        "JOIN titles t ON t.id = l.title_id "
        "LEFT JOIN media_files m ON m.title_id = t.id "
        "WHERE l.profile_id IN (SELECT id FROM profiles WHERE user_id = ?) "
        "ORDER BY l.added_at DESC LIMIT 20"));
    listQuery.addBindValue(userId);
    if (listQuery.exec())
    {
        while (listQuery.next())
        {
            QVariantMap item;
            item.insert(QStringLiteral("title"), listQuery.value(0).toString());
            item.insert(QStringLiteral("thumbnailUrl"), DatabaseUtils::toFileUrl(listQuery.value(1).toString()));
            item.insert(QStringLiteral("videoUrl"), DatabaseUtils::toFileUrl(listQuery.value(2).toString()));
            item.insert(QStringLiteral("runtime"), listQuery.value(3).toInt());
            item.insert(QStringLiteral("accentColor"), listQuery.value(4).toString());
            item.insert(QStringLiteral("addedAt"), listQuery.value(5).toString());
            myList.append(item);
        }
    }
    result.insert(QStringLiteral("myList"), myList);

    QVariantMap counts;
    counts.insert(QStringLiteral("profiles"), profiles.size());
    counts.insert(QStringLiteral("history"), history.size());
    counts.insert(QStringLiteral("myList"), myList.size());
    result.insert(QStringLiteral("counts"), counts);

    result.insert(QStringLiteral("success"), true);
    return result;
}

QVariantMap Backend::addToMyList(const QString &identifier, const QString &title) const
{
    QVariantMap result;
    result.insert(QStringLiteral("success"), false);

    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-mylist-add"));
    if (!db.isOpen())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Database unavailable"));
        return result;
    }

    const QString email = identifier.trimmed();
    const QString titleName = title.trimmed();
    if (email.isEmpty() || titleName.isEmpty())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("User and title are required"));
        return result;
    }

    QSqlQuery userQuery(db);
    userQuery.prepare(QStringLiteral("SELECT id FROM users WHERE email = ? LIMIT 1"));
    userQuery.addBindValue(email);
    if (!userQuery.exec() || !userQuery.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("User not found"));
        return result;
    }
    const int userId = userQuery.value(0).toInt();

    int profileId = -1;
    QSqlQuery profileQuery(db);
    profileQuery.prepare(QStringLiteral("SELECT id FROM profiles WHERE user_id = ? ORDER BY created_at LIMIT 1"));
    profileQuery.addBindValue(userId);
    if (profileQuery.exec() && profileQuery.next())
    {
        profileId = profileQuery.value(0).toInt();
    }
    else
    {
        QSqlQuery createProfile(db);
        createProfile.prepare(QStringLiteral("INSERT INTO profiles (user_id, name, avatar_url, is_kid) VALUES (?, ?, '', 0)"));
        createProfile.addBindValue(userId);
        createProfile.addBindValue(QStringLiteral("Profile 1"));
        if (!createProfile.exec())
        {
            result.insert(QStringLiteral("message"), QStringLiteral("Failed to create profile"));
            return result;
        }
        profileId = createProfile.lastInsertId().toInt();
    }

    QSqlQuery titleQuery(db);
    titleQuery.prepare(QStringLiteral("SELECT id FROM titles WHERE lower(name) = lower(?) ORDER BY created_at DESC LIMIT 1"));
    titleQuery.addBindValue(titleName);
    if (!titleQuery.exec() || !titleQuery.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Title not found"));
        return result;
    }
    const int titleId = titleQuery.value(0).toInt();

    QSqlQuery exists(db);
    exists.prepare(QStringLiteral("SELECT 1 FROM my_list WHERE profile_id = ? AND title_id = ? LIMIT 1"));
    exists.addBindValue(profileId);
    exists.addBindValue(titleId);
    if (exists.exec() && exists.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Already in My List"));
        return result;
    }

    QSqlQuery insert(db);
    insert.prepare(QStringLiteral("INSERT INTO my_list (profile_id, title_id) VALUES (?, ?)"));
    insert.addBindValue(profileId);
    insert.addBindValue(titleId);
    if (!insert.exec())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Failed to add to My List"));
        return result;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("message"), QStringLiteral("Added to My List"));
    return result;
}

QVariantList Backend::listPlans() const
{
    QVariantList plans;
    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-plans"));
    if (!db.isOpen())
    {
        return plans;
    }

    QSqlQuery seed(db);
    if (seed.exec(QStringLiteral("SELECT COUNT(1) FROM subscription_plans")) && seed.next())
    {
        if (seed.value(0).toInt() == 0)
        {
            QSqlQuery insert(db);
            insert.prepare(QStringLiteral(
                "INSERT INTO subscription_plans (name, price_month, duration_days, max_profiles, max_quality) "
                "VALUES "
                "('Basic', 9.99, 30, 1, 'HD'),"
                "('Standard', 14.99, 30, 2, 'Full HD'),"
                "('Premium', 19.99, 30, 4, '4K')"));
            insert.exec();
        }
    }

    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, name, price_month, duration_days, max_profiles, max_quality FROM subscription_plans ORDER BY price_month ASC")))
    {
        return plans;
    }

    while (query.next())
    {
        QVariantMap plan;
        plan.insert(QStringLiteral("id"), query.value(0).toInt());
        plan.insert(QStringLiteral("name"), query.value(1).toString());
        plan.insert(QStringLiteral("priceMonth"), query.value(2).toDouble());
        plan.insert(QStringLiteral("durationDays"), query.value(3).toInt());
        plan.insert(QStringLiteral("maxProfiles"), query.value(4).toInt());
        plan.insert(QStringLiteral("maxQuality"), query.value(5).toString());
        plans.append(plan);
    }
    return plans;
}

QVariantMap Backend::subscribePlan(const QString &identifier, int planId) const
{
    QVariantMap result;
    result.insert(QStringLiteral("success"), false);

    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-plans-subscribe"));
    if (!db.isOpen())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Database unavailable"));
        return result;
    }

    const QString email = identifier.trimmed();
    if (email.isEmpty() || planId <= 0)
    {
        result.insert(QStringLiteral("message"), QStringLiteral("User and plan are required"));
        return result;
    }

    QSqlQuery userQuery(db);
    userQuery.prepare(QStringLiteral("SELECT id FROM users WHERE email = ? LIMIT 1"));
    userQuery.addBindValue(email);
    if (!userQuery.exec() || !userQuery.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("User not found"));
        return result;
    }
    const int userId = userQuery.value(0).toInt();

    QSqlQuery planQuery(db);
    planQuery.prepare(QStringLiteral("SELECT id, duration_days FROM subscription_plans WHERE id = ? LIMIT 1"));
    planQuery.addBindValue(planId);
    if (!planQuery.exec() || !planQuery.next())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Plan not found"));
        return result;
    }
    const int durationDays = planQuery.value(1).toInt();

    // deactivate previous
    QSqlQuery deactivate(db);
    deactivate.prepare(QStringLiteral("UPDATE user_subscriptions SET is_active = 0 WHERE user_id = ?"));
    deactivate.addBindValue(userId);
    deactivate.exec();

    const QDate startDate = QDate::currentDate();
    const QDate endDate = startDate.addDays(durationDays > 0 ? durationDays : 30);

    QSqlQuery insert(db);
    insert.prepare(QStringLiteral(
        "INSERT INTO user_subscriptions (user_id, plan_id, start_date, end_date, is_active) "
        "VALUES (?, ?, ?, ?, 1)"));
    insert.addBindValue(userId);
    insert.addBindValue(planId);
    insert.addBindValue(startDate.toString(Qt::ISODate));
    insert.addBindValue(endDate.toString(Qt::ISODate));
    if (!insert.exec())
    {
        result.insert(QStringLiteral("message"), QStringLiteral("Failed to subscribe"));
        return result;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("message"), QStringLiteral("Subscription activated"));
    return result;
}

void Backend::logPlayback(const QString &identifier, const QString &title, int positionSec, bool finished) const
{
    auto db = DatabaseUtils::openDatabase(QStringLiteral("finalproject-playback"));
    if (!db.isOpen())
    {
        return;
    }

    const QString email = identifier.trimmed();
    const QString titleName = title.trimmed();
    if (email.isEmpty() || titleName.isEmpty())
    {
        return;
    }

    QSqlQuery userQuery(db);
    userQuery.prepare(QStringLiteral("SELECT id FROM users WHERE email = ? LIMIT 1"));
    userQuery.addBindValue(email);
    if (!userQuery.exec() || !userQuery.next())
    {
        return;
    }
    const int userId = userQuery.value(0).toInt();

    int profileId = -1;
    QSqlQuery profileQuery(db);
    profileQuery.prepare(QStringLiteral("SELECT id FROM profiles WHERE user_id = ? ORDER BY created_at LIMIT 1"));
    profileQuery.addBindValue(userId);
    if (profileQuery.exec() && profileQuery.next())
    {
        profileId = profileQuery.value(0).toInt();
    }
    else
    {
        QSqlQuery createProfile(db);
        createProfile.prepare(QStringLiteral("INSERT INTO profiles (user_id, name, avatar_url, is_kid) VALUES (?, ?, '', 0)"));
        createProfile.addBindValue(userId);
        createProfile.addBindValue(QStringLiteral("Profile 1"));
        if (!createProfile.exec())
        {
            return;
        }
        profileId = createProfile.lastInsertId().toInt();
    }

    QSqlQuery titleQuery(db);
    titleQuery.prepare(QStringLiteral("SELECT id FROM titles WHERE lower(name) = lower(?) ORDER BY created_at DESC LIMIT 1"));
    titleQuery.addBindValue(titleName);
    if (!titleQuery.exec() || !titleQuery.next())
    {
        return;
    }
    const int titleId = titleQuery.value(0).toInt();

    QSqlQuery insert(db);
    insert.prepare(QStringLiteral(
        "INSERT INTO watch_history (profile_id, title_id, position_sec, is_finished, updated_at) "
        "VALUES (?, ?, ?, ?, datetime('now'))"));
    insert.addBindValue(profileId);
    insert.addBindValue(titleId);
    insert.addBindValue(positionSec);
    insert.addBindValue(finished ? 1 : 0);
    insert.exec();
}

std::unique_ptr<IDataProvider> Backend::createSqlProvider()
{
    return std::make_unique<QtSqlDataProvider>();
}

QVariantMap Backend::toVariant(const MediaItem &item) const
{
    return makeVariantItem(item);
}

QVariantList Backend::toVariant(const std::vector<MediaCategory> &categories) const
{
    QVariantList list;
    list.reserve(static_cast<int>(categories.size()));
    for (const auto &category : categories)
    {
        QVariantMap map;
        map.insert(QStringLiteral("name"), QString::fromStdString(category.name));

        QVariantList items;
        items.reserve(static_cast<int>(category.items.size()));
        for (const auto &item : category.items)
        {
            items.append(makeVariantItem(item));
        }

        map.insert(QStringLiteral("items"), items);
        list.append(map);
    }
    return list;
}
