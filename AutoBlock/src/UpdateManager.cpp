#include "precompiled.h"

#include "UpdateManager.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "JlCompress.h"
#include "Logger.h"
#include "Persistance.h"
#include "QueryHelper.h"
#include "ReportGenerator.h"

#define COOKIE_DOWNLOAD_REPORTED "download"
#define ZIP_PASSWORD "M9*13f3*3zxd3_*"
#define ZIPPED_PATH QString("%1/database.zip").arg( QDir::tempPath() )

namespace {

QUrl createRequest()
{
    QUrl q;
    q.setUserName("username");
    q.setPassword("password");
    q.setScheme("http");
    q.setHost("host.com");

    return q;
}

QString performCompression(QString const& destination)
{
    JlCompress::compressFile(destination, DATABASE_PATH, ZIP_PASSWORD);
    return destination;
}


bool performRestore(QString const& source)
{
    QStringList files = JlCompress::extractDir( source, QDir::homePath(), ZIP_PASSWORD );

    return !files.isEmpty();
}


QPair<QByteArray, QString> compressDatabase()
{
    performCompression(ZIPPED_PATH);

    QFile f(ZIPPED_PATH);
    f.open(QIODevice::ReadOnly);

    QByteArray qba = f.readAll();
    f.close();

    QString syncID = QString("%1_%2").arg( QString::number( QDateTime::currentMSecsSinceEpoch() ) ).arg( canadainc::ReportGenerator::generateRandomInt() );

    return qMakePair<QByteArray,QString>(qba, syncID);
}


QString uncompressDatabase(QByteArray const& data)
{
    canadainc::IOUtils::writeFile(ZIPPED_PATH, data);
    QStringList files = JlCompress::extractDir( ZIPPED_PATH, QDir::tempPath(), "REP_AUTO___B1L30TctK0x2" );

    if ( !files.isEmpty() ) {
        QString db = files.first();
        LOGGER("DownloadedArchive" << db);
        return db;
    } else {
        LOGGER("EmptyDownloadedArchive");
        return QString();
    }
}

}

namespace autoblock {

using namespace bb::system;

UpdateManager::UpdateManager(QueryHelper* helper) : m_helper(helper)
{
}


void UpdateManager::onDataReady(int id, QVariant const& data)
{
    if (id == QueryId::FetchAllReported) {
        emit statusUpdate( tr("Rendering results...") );
        emit updatesAvailable( data.toList() );
    }
}


void UpdateManager::lazyInit()
{
    connect( &m_network, SIGNAL( requestComplete(QVariant const&, QByteArray const&, bool) ), this, SLOT( onRequestComplete(QVariant const&, QByteArray const&, bool) ) );
    connect( &m_network, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ), this, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ) );
    connect( &m_network, SIGNAL( uploadProgress(QVariant const&, qint64, qint64) ), this, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ) );
    connect( m_helper, SIGNAL( dataReady(int, QVariant const&) ), this, SLOT( onDataReady(int, QVariant const&) ) );
}


void UpdateManager::onRequestComplete(QVariant const& cookie, QByteArray const& data, bool error)
{
    LOGGER(cookie);

    if (!error)
    {
        if (cookie == COOKIE_DOWNLOAD_REPORTED)
        {
            QFutureWatcher<QString>* qfw = new QFutureWatcher<QString>(this);
            connect( qfw, SIGNAL( finished() ), this, SLOT( onUncompressed() ) );

            QFuture<QString> future = QtConcurrent::run(uncompressDatabase, data);
            qfw->setFuture(future);

            emit statusUpdate( tr("Uncompressing data...") );
        } else {
            QVariantMap actualResult = bb::data::JsonDataAccess().loadFromBuffer(data).toMap();
            QString httpResult = actualResult.value("result").toString();

            if ( httpResult != HTTP_RESPONSE_OK ) {
                LOGGER("DownloadResult" << actualResult);
                emit updatesAvailable( QVariantList() );
            } else {
                LOGGER("StartingArchiveDownload");
                QString path = actualResult.value("path").toString();

                QUrl u = createRequest();
                u.setPath(path);
                m_network.doGet( u, COOKIE_DOWNLOAD_REPORTED);
            }
        }
    } else {
        LOGGER("RequestError");
        m_helper->getPersist()->showToast( tr("Request failed. Please try again."), "images/common/ic_offline.png" );
    }
}


void UpdateManager::onUncompressed()
{
    QFutureWatcher<QString>* qfw = static_cast< QFutureWatcher<QString>* >( sender() );
    QString result = qfw->result();

    LOGGER("UncompressedArchive" << result);

    emit statusUpdate( tr("Processing results...") );
    m_helper->attachReportedDatabase(result);

    qfw->deleteLater();
}


void UpdateManager::onCompressed()
{
    QFutureWatcher< QPair<QByteArray,QString> >* qfw = static_cast< QFutureWatcher< QPair<QByteArray,QString> >* >( sender() );
    QPair<QByteArray,QString> result = qfw->result();

    LOGGER( result.first.size() );

    QString syncID = result.second;
    QString userId = m_helper->getPersist()->getFlag(KEY_USER_ID).toString();

    if ( !userId.isEmpty() ) {
        LOGGER("StartingUpload" << userId << syncID);

        QUrl u = createRequest();
        u.setPath("auto_block/report_spammers.php");
        u.addQueryItem("syncID", syncID);
        u.addQueryItem("user_id", userId);
        u.addQueryItem("format", "json");

        m_network.upload( u, QString("%1.zip").arg(syncID), result.first, syncID);
    } else {
        LOGGER("NoDefaultAccountFound" << userId);
        m_helper->getPersist()->showToast( tr("At least one default email address must be set up to sync to the server!"), "images/menu/ic_unblock_all.png" );
        emit updatesAvailable( QVariantList() );
    }

    qfw->deleteLater();
}


void UpdateManager::submit()
{
    QFutureWatcher< QPair<QByteArray,QString> >* qfw = new QFutureWatcher< QPair<QByteArray,QString> >(this);
    connect( qfw, SIGNAL( finished() ), this, SLOT( onCompressed() ) );

    QFuture< QPair<QByteArray,QString> > future = QtConcurrent::run(compressDatabase);
    qfw->setFuture(future);
}


void UpdateManager::backup(QString const& destination)
{
    LOGGER(destination);

    QFutureWatcher<QString>* qfw = new QFutureWatcher<QString>(this);
    connect( qfw, SIGNAL( finished() ), this, SLOT( onSaved() ) );

    QFuture<QString> future = QtConcurrent::run(performCompression, destination);
    qfw->setFuture(future);
}


void UpdateManager::restore(QString const& source)
{
    LOGGER(source);

    QFutureWatcher<bool>* qfw = new QFutureWatcher<bool>(this);
    connect( qfw, SIGNAL( finished() ), this, SLOT( onRestored() ) );

    QFuture<bool> future = QtConcurrent::run(performRestore, source);
    qfw->setFuture(future);
}


void UpdateManager::onSaved()
{
    QFutureWatcher<QString>* qfw = static_cast< QFutureWatcher<QString>* >( sender() );
    QString result = qfw->result();

    LOGGER("BackupComplete" << result);

    emit backupComplete(result);

    qfw->deleteLater();
}


void UpdateManager::onRestored()
{
    QFutureWatcher<bool>* qfw = static_cast< QFutureWatcher<bool>* >( sender() );
    bool result = qfw->result();

    if (result) {
        invokeService("terminate");
    }

    LOGGER("RestoreResult" << result);
    emit restoreComplete(result);

    qfw->deleteLater();
}


void UpdateManager::invokeService(const char* data) {
    m_helper->getPersist()->invoke( "com.canadainc.AutoBlockService", "com.canadainc.AutoBlockService.RESET", "", "", data ? QString(data).toAscii() : "" );
}


UpdateManager::~UpdateManager()
{
}

} /* namespace autoblock */
