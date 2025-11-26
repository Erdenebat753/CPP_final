#include "DatabaseUtils.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QTextStream>
#include <QUrl>

namespace
{
static const char *kDefaultConnectionName = "nebula-shared";

QString findProjectRoot()
{
    QDir dir(QCoreApplication::applicationDirPath());
    for (int i = 0; i < 6; ++i)
    {
        if (dir.exists(QStringLiteral("FinalProject.sln")))
        {
            return dir.absolutePath();
        }
        if (!dir.cdUp())
        {
            break;
        }
    }
    return QCoreApplication::applicationDirPath();
}

bool executeSqlScript(const QString &path, QSqlDatabase &db)
{
    QFile file(path);
    if (!file.exists())
    {
        return false;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        return false;
    }

    QTextStream stream(&file);
    QString statement;

    auto executeStatement = [&db](QString stmt) -> bool {
        stmt = stmt.trimmed();
        if (stmt.isEmpty())
        {
            return true;
        }

        if (stmt.endsWith(QLatin1Char(';')))
        {
            stmt.chop(1);
        }

        QSqlQuery query(db);
        if (!query.exec(stmt))
        {
            qWarning() << "SQL error:" << query.lastError().text() << "while executing" << stmt;
            return false;
        }
        return true;
    };

    while (!stream.atEnd())
    {
        const QString line = stream.readLine();
        const QString trimmed = line.trimmed();

        if (trimmed.startsWith(QStringLiteral("--")) || trimmed.startsWith(QStringLiteral("//")))
        {
            continue;
        }

        statement += line;
        statement.append(QLatin1Char('\n'));

        if (trimmed.endsWith(QLatin1Char(';')))
        {
            if (!executeStatement(statement))
            {
                return false;
            }
            statement.clear();
        }
    }

    if (!statement.trimmed().isEmpty())
    {
        if (!executeStatement(statement))
        {
            return false;
        }
    }

    return true;
}
} // namespace

namespace DatabaseUtils
{
QString projectRoot()
{
    static const QString root = findProjectRoot();
    return root;
}

QString schemaFilePath()
{
    return QDir(projectRoot()).filePath(QStringLiteral("AdminDashboard/sourcefiles/.sql"));
}

QString databaseFilePath()
{
    QDir root(projectRoot());
    return root.filePath(QStringLiteral("FinalProject/data/streaming.db"));
}

QString imagesDirectory()
{
    QDir root(projectRoot());
    return root.filePath(QStringLiteral("FinalProject/images"));
}

QString videosDirectory()
{
    QDir root(projectRoot());
    return root.filePath(QStringLiteral("FinalProject/videos"));
}

QString toAbsoluteMediaPath(const QString &relativePath)
{
    if (relativePath.isEmpty())
    {
        return QString();
    }

    if (QDir::isAbsolutePath(relativePath))
    {
        return relativePath;
    }

    QDir base(QDir(projectRoot()).filePath(QStringLiteral("FinalProject")));
    return base.filePath(relativePath);
}

QString toFileUrl(const QString &relativePath)
{
    const QString absolute = toAbsoluteMediaPath(relativePath);
    if (absolute.isEmpty())
    {
        return QString();
    }
    return QUrl::fromLocalFile(absolute).toString();
}

bool ensureStorageDirectories()
{
    bool ok = true;
    for (const QString &path : {QFileInfo(databaseFilePath()).absolutePath(), imagesDirectory(), videosDirectory()})
    {
        QDir dir(path);
        if (!dir.exists())
        {
            ok &= dir.mkpath(QStringLiteral("."));
        }
    }
    return ok;
}

bool ensureDatabase()
{
    if (!ensureStorageDirectories())
    {
        return false;
    }

    auto db = openDatabase(QStringLiteral("initializer"));
    if (!db.isValid())
    {
        return false;
    }

    if (!db.isOpen() && !db.open())
    {
        qWarning() << "Unable to open SQLite database" << db.lastError().text();
        return false;
    }

    const QString schemaPath = schemaFilePath();
    if (!executeSqlScript(schemaPath, db))
    {
        qWarning() << "Failed to execute schema" << schemaPath;
        return false;
    }

    return true;
}

QSqlDatabase openDatabase(const QString &connectionName)
{
    const QString name = connectionName.isEmpty() ? QString::fromLatin1(kDefaultConnectionName) : connectionName;

    QSqlDatabase db;
    if (QSqlDatabase::contains(name))
    {
        db = QSqlDatabase::database(name);
    }
    else
    {
        db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), name);
    }

    db.setDatabaseName(databaseFilePath());
    if (!db.isOpen())
    {
        if (!db.open())
        {
            qWarning() << "Failed to open database" << db.lastError().text();
        }
    }
    return db;
}
}
