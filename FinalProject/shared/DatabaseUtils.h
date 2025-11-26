#pragma once

#include <QString>
#include <QSqlDatabase>

namespace DatabaseUtils
{
QString projectRoot();
QString schemaFilePath();
QString databaseFilePath();
QString imagesDirectory();
QString videosDirectory();
QString toAbsoluteMediaPath(const QString &relativePath);
QString toFileUrl(const QString &relativePath);

bool ensureStorageDirectories();
bool ensureDatabase();
QSqlDatabase openDatabase(const QString &connectionName = QString());
}

