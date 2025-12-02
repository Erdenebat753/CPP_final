#pragma once

#include <string>

struct AuthResult
{
    bool success{};
    std::string message;
    std::string role;
};

class IAuthRepository;

class AuthService
{
public:
    explicit AuthService(IAuthRepository *repository = nullptr);

    void setRepository(IAuthRepository *repository);

    AuthResult authenticate(const std::string &mode,
                            const std::string &role,
                            const std::string &identifier,
                            const std::string &password,
                            const std::string &confirmPassword) const;

private:
    IAuthRepository *m_repository;
};
