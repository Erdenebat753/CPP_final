#pragma once

#include <optional>
#include <string>

struct AuthUser
{
    std::string identifier;
    std::string role;
};

class IAuthRepository
{
public:
    virtual ~IAuthRepository() = default;

    virtual bool ensureAdminUser(const std::string &identifier, const std::string &password) = 0;
    virtual std::optional<AuthUser> findUser(const std::string &identifier, const std::string &password) = 0;
    virtual std::optional<AuthUser> createUser(const std::string &identifier, const std::string &password) = 0;
};
