#pragma once

#include "../core/AuthService.h"
#include "../core/AuthRepository.h"
#include "../core/StreamingService.h"

#include <QObject>
#include <QVariant>

class Backend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap heroItem READ heroItem NOTIFY dataChanged)
    Q_PROPERTY(QVariantList categories READ categories NOTIFY dataChanged)

public:
    explicit Backend(std::unique_ptr<IDataProvider> provider, QObject *parent = nullptr);

    Q_INVOKABLE void reload();
    Q_INVOKABLE QVariantMap heroItem() const;
    Q_INVOKABLE QVariantList categories() const;
    Q_INVOKABLE QVariantMap authenticate(const QString &mode,
                                         const QString &role,
                                         const QString &identifier,
                                         const QString &password,
                                         const QString &confirmPassword);
    Q_INVOKABLE QVariantList listUsers() const;
    Q_INVOKABLE QVariantList listGenres() const;
    Q_INVOKABLE QVariantMap addGenre(const QString &name);
    Q_INVOKABLE QVariantMap addMovie(const QString &name,
                                     const QString &description,
                                     const QString &genre,
                                     int runtimeMinutes,
                                     const QString &thumbnailPath,
                                     const QString &videoPath);
    Q_INVOKABLE QVariantMap userProfile(const QString &identifier) const;
    Q_INVOKABLE QVariantMap addToMyList(const QString &identifier, const QString &title) const;
    Q_INVOKABLE QVariantList listPlans() const;
    Q_INVOKABLE QVariantMap subscribePlan(const QString &identifier, int planId) const;
    Q_INVOKABLE void logPlayback(const QString &identifier, const QString &title, int positionSec, bool finished) const;

    static std::unique_ptr<IDataProvider> createSqlProvider();

signals:
    void dataChanged();

private:
    StreamingService m_service;
    std::unique_ptr<IAuthRepository> m_authRepository;
    AuthService m_authService;

    QVariantMap toVariant(const MediaItem &item) const;
    QVariantList toVariant(const std::vector<MediaCategory> &categories) const;
};
