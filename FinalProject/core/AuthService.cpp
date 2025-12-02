#include "AuthService.h"
#include "AuthRepository.h"

#include <algorithm>
#include <cctype>

namespace
{
bool isEmpty(const std::string &value)
{
    return std::all_of(value.begin(), value.end(), [](unsigned char ch) { return std::isspace(ch) != 0; }) || value.empty();
}
} // namespace

AuthService::AuthService(IAuthRepository *repository)
    : m_repository(repository)
{
}

void AuthService::setRepository(IAuthRepository *repository)
{
    m_repository = repository;
}

AuthResult AuthService::authenticate(const std::string &mode,
                                     const std::string &role,
                                     const std::string &identifier,
                                     const std::string &password,
                                     const std::string &confirmPassword) const
{
    AuthResult result;

    if (isEmpty(identifier) || isEmpty(password))
    {
        result.success = false;
        result.message = "Please fill in all required fields.";
        return result;
    }

    if (mode == "signup" && password != confirmPassword)
    {
        result.success = false;
        result.message = "Passwords do not match.";
        return result;
    }

    if (!m_repository)
    {
        result.success = false;
        result.message = "Auth backend unavailable.";
        return result;
    }

    if (mode == "signup")
    {
        auto created = m_repository->createUser(identifier, password);
        if (!created.has_value())
        {
            result.success = false;
            result.message = "Unable to create account.";
            return result;
        }
        result.success = true;
        result.role = created->role;
        result.message = "Account created.";
        return result;
    }

    auto user = m_repository->findUser(identifier, password);
    if (!user.has_value())
    {
        result.success = false;
        result.message = "Invalid credentials.";
        return result;
    }

    result.success = true;
    result.role = user->role;
    result.message = "Authenticated as " + result.role;
    return result;
}
