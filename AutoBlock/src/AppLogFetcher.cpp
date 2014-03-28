#include "AppLogFetcher.h"
#include "Logger.h"
#include "Persistance.h"

#include <sys/utsname.h>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include <bb/system/SystemProgressToast>

#include <bb/device/HardwareInfo>

namespace {

QHttpPart fetchFile(QString const& name, QString const& filePath, QObject* parent)
{
    QHttpPart uilog;
    uilog.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("plain/text"));
    uilog.setHeader(QNetworkRequest::ContentDispositionHeader, QString("form-data; name=\"%1\"").arg(name) );

    QFile* file = new QFile(filePath, parent); // delete file with its parent
    file->open(QIODevice::ReadOnly);
    uilog.setBodyDevice(file);

    return uilog;
}

}

namespace canadainc {

using namespace bb::system;
using namespace bb::device;

AppLogFetcher::AppLogFetcher() : m_networkManager(NULL), m_progress(NULL)
{
}


void AppLogFetcher::submitLogs(bool silent)
{
    deregisterLogging();

    if (!silent)
    {
        if (!m_progress) {
            m_progress = new SystemProgressToast(this);
            m_progress->setBody( tr("Collecting logs...") );
            m_progress->setAutoUpdateEnabled(true);
        }

        m_progress->setState(SystemUiProgressState::Active);
        m_progress->setStatusMessage( tr("Generating...") );
        m_progress->show();
    }

    QString logID = QString::number( QDateTime::currentMSecsSinceEpoch() );

    struct utsname udata;
    uname(&udata);

    HardwareInfo hw;

    QStringList deviceInfo;
    deviceInfo << QString("Device Name: %1").arg( hw.deviceName() );
    deviceInfo << QString("Hardware ID: %1").arg( hw.hardwareId() );
    deviceInfo << QString("Machine: %1").arg(udata.machine);
    deviceInfo << QString("ModelName: %1").arg( hw.modelName() );
    deviceInfo << QString("ModelNumber: %1").arg( hw.modelNumber() );
    deviceInfo << QString("NodeName: %1").arg(udata.nodename);
    deviceInfo << QString("OS Creation: %1").arg(udata.version);
    deviceInfo << QString("PhysicalKeyboard: %1").arg( hw.isPhysicalKeyboardDevice() );
    deviceInfo << QString("Release: %1").arg(udata.release);
    deviceInfo << QString("SysName: %1").arg(udata.sysname);

    QHttpMultiPart* multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    QHttpPart textPart;
    textPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"info\""));
    textPart.setBody( deviceInfo.join("\n").toUtf8() );

    QHttpPart idPart;
    idPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"logID\""));
    idPart.setBody( logID.toUtf8() );

    multiPart->append(idPart);
    multiPart->append(textPart);
    multiPart->append( fetchFile( "uilog", QDir::currentPath()+"/logs/ui.log", multiPart ) );
    //multiPart->append( fetchFile( "servicelog", QDir::currentPath()+"/logs/service.log", multiPart ) );

    if (!m_networkManager) {
        m_networkManager = new QNetworkAccessManager(this);
        connect( m_networkManager, SIGNAL( finished(QNetworkReply*) ), this, SLOT( onNetworkReply(QNetworkReply*) ) );
    }

    QObject* reply = m_networkManager->post( QNetworkRequest( QUrl( QString("http://bb10:bangladesh@canadainc.org/diagnostic/submit.php?id=%1").arg(logID) ) ), multiPart );
    reply->setProperty("id", logID);
    multiPart->setParent(reply); // delete the multiPart with

    if (m_progress) {
        connect( reply, SIGNAL( uploadProgress(qint64,qint64) ), this, SLOT( uploadProgress(qint64,qint64) ) );
        m_progress->setStatusMessage( tr("Submitting...") );
    }
}


void AppLogFetcher::onNetworkReply(QNetworkReply* reply)
{
    QString message = tr("Could not submit logs! Please try again...");

    if ( reply->error() == QNetworkReply::NoError && reply->isReadable() ) {
        message = tr("Logs have been submitted. Please provide the support team the following ID: %1").arg( reply->property("id").toString() );
    }

    if (m_progress)
    {
        m_progress->setState(SystemUiProgressState::Inactive);
        m_progress->cancel();

        Persistance::showBlockingToast( message, tr("OK"), "asset:///images/ic_bugs.png" );
    }

    reply->deleteLater();

    registerLogging();
}


void AppLogFetcher::uploadProgress(qint64 bytesSent, qint64 bytesTotal)
{
    if (bytesTotal != 0 && m_progress)
    {
        int progress = (double)bytesSent/(double)bytesTotal;
        m_progress->setProgress(progress);
    }
}


AppLogFetcher::~AppLogFetcher()
{
}

} /* namespace canadainc */
