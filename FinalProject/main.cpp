#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QFile>
#include <QTextStream>
#include <QIODevice>
#include <cstdio>

#include "backend/Backend.h"

namespace
{
void logMessage(QtMsgType type, const QMessageLogContext &, const QString &msg)
{
    static QFile logFile(QCoreApplication::applicationDirPath() + QStringLiteral("/debug.log"));
    if (!logFile.isOpen())
    {
        logFile.open(QIODevice::Append | QIODevice::Text);
    }

    QTextStream stream(&logFile);
    stream << msg << Qt::endl;

    // Also mirror critical/warning to stderr for attached consoles
    if (type == QtWarningMsg || type == QtCriticalMsg || type == QtFatalMsg)
    {
        fprintf(stderr, "%s\n", msg.toLocal8Bit().constData());
        fflush(stderr);
    }
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qInstallMessageHandler(logMessage);

    Backend backend(Backend::createSqlProvider());
    backend.reload();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);

    const QUrl url(QStringLiteral("qrc:/qt/qml/finalproject/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const auto &w : warnings)
        {
            qWarning() << "QML warning:" << w.toString();
        }
    });
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(url);

    if (engine.rootObjects().isEmpty())
    {
        qCritical() << "Failed to load QML root object";
        return -1;
    }

    return app.exec();
}
#include <QFile>
#include <QTextStream>
#include <QIODevice>
#include <QCoreApplication>
