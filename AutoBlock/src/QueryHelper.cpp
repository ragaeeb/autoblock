#include "precompiled.h"

#include "QueryHelper.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "customsqldatasource.h"
#include "Logger.h"
#include "MessageManager.h"
#include "Persistance.h"
#include "QueryId.h"

#define PLACEHOLDER "?"

namespace autoblock {

using namespace canadainc;

QueryHelper::QueryHelper(CustomSqlDataSource* sql, AppLogFetcher* reporter) :
        m_reporter(reporter), m_sql(sql), m_ms(NULL), m_lastUpdate( QDateTime::currentMSecsSinceEpoch() )
{
    connect( sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ), Qt::QueuedConnection );
    connect( sql, SIGNAL( error(QString const&) ), this, SLOT( onError(QString const&) ) );
}


void QueryHelper::onError(QString const& errorMessage)
{
    LOGGER(errorMessage);
    m_reporter->submitLogs(true);
}


void QueryHelper::dataLoaded(int id, QVariant const& data)
{
    LOGGER("Data loaded" << id << data);

    if (id == QueryId::UnblockKeywords || id == QueryId::BlockKeywords) {
        fetchAllBlockedKeywords();
    } else if (id == QueryId::UnblockSenders || id == QueryId::BlockSenders) {
        fetchAllBlockedSenders();
    } else {
        emit dataReady(id, data);
    }
}


void QueryHelper::fetchAllBlockedKeywords()
{
    m_sql->setQuery("SELECT term,count FROM inbound_keywords ORDER BY term");
    m_sql->load(QueryId::FetchBlockedKeywords);
}


void QueryHelper::fetchAllBlockedSenders()
{
    m_sql->setQuery("SELECT address,count FROM inbound_blacklist ORDER BY address");
    m_sql->load(QueryId::FetchBlockedSenders);
}


void QueryHelper::clearBlockedSenders()
{
    m_sql->setQuery("DELETE FROM inbound_blacklist");
    m_sql->load(QueryId::UnblockSenders);
}


void QueryHelper::clearBlockedKeywords()
{
    m_sql->setQuery("DELETE FROM inbound_keywords");
    m_sql->load(QueryId::UnblockKeywords);
}


void QueryHelper::clearLogs()
{
    m_sql->setQuery("DELETE FROM logs");
    m_sql->load(QueryId::ClearLogs);
}


QStringList QueryHelper::blockKeywords(QVariantList const& keywords)
{
    LOGGER("BlockKeywords" << keywords);

    QStringList all;
    QStringList keywordsList;
    all << QString("INSERT OR REPLACE INTO inbound_keywords (term) SELECT ? AS 'address'");
    QString addition = QString("UNION SELECT ?");

    for (int i = keywords.size()-1; i >= 0; i--)
    {
        all << addition;
        keywordsList << keywords[i].toString();
    }

    all.removeLast();

    m_sql->setQuery( all.join(" ") );
    m_sql->executePrepared(keywords, QueryId::BlockKeywords);

    validateResult(keywordsList);

    return keywordsList;
}


QStringList QueryHelper::block(QVariantList const& addresses)
{
    LOGGER(addresses);

    QStringList all;
    QVariantList numbers;
    QStringList numbersList;
    QStringList placeHolders;

    if (!m_ms) {
        m_ms = new MessageService(this);
    }

    for (int i = addresses.size()-1; i >= 0; i--)
    {
        QVariantMap current = addresses[i].toMap();
        QString address = current.value("senderAddress").toString().toLower();

        if ( !address.trimmed().isEmpty() )
        {
            numbers << address;
            numbersList << address;
            placeHolders << PLACEHOLDER;
        }

        QString replyTo = current.value("replyTo").toString().trimmed().toLower();

        LOGGER("Reply vs address" << replyTo << address);

        if ( !replyTo.isEmpty() && replyTo.compare(address, Qt::CaseInsensitive) != 0 )
        {
            numbers << replyTo;
            numbersList << replyTo;
            placeHolders << PLACEHOLDER;
        }

        if ( current.contains("aid") )
        {
            qint64 aid = current.value("aid").toLongLong();
            m_ms->remove( aid, current.value("id").toLongLong() );
            m_ms->remove( aid, current.value("cid").toString() );
        }
    }

    LOGGER(">>> NUMBERs" << numbers << placeHolders );

    m_sql->setQuery( QString("INSERT OR REPLACE INTO inbound_blacklist (address) VALUES(%1)").arg( placeHolders.join("),(") ) );
    m_sql->executePrepared(numbers, QueryId::BlockSenders);

    validateResult(numbersList);

    return numbersList;
}


QStringList QueryHelper::unblockKeywords(QVariantList const& keywords)
{
    LOGGER("unblockKeywords" << keywords);

    QStringList keywordsList;
    QVariantList keywordsVariants;
    QStringList placeHolders;

    for (int i = keywords.size()-1; i >= 0; i--)
    {
        QString current = keywords[i].toMap().value("term").toString();
        keywordsVariants << current;
        keywordsList << current;
        placeHolders << PLACEHOLDER;
    }

    m_sql->setQuery( QString("DELETE FROM inbound_keywords WHERE term IN (%1)").arg( placeHolders.join(",") ) );
    m_sql->executePrepared(keywordsVariants, QueryId::UnblockKeywords);

    validateResult(keywordsList);

    return keywordsList;
}


QStringList QueryHelper::unblock(QVariantList const& senders)
{
    LOGGER(senders);

    QStringList keywordsList;
    QVariantList keywordsVariants;
    QStringList placeHolders;

    for (int i = senders.size()-1; i >= 0; i--)
    {
        QString current = senders[i].toMap().value("address").toString();
        keywordsVariants << current;
        keywordsList << current;
        placeHolders << PLACEHOLDER;
    }

    m_sql->setQuery( QString("DELETE FROM inbound_blacklist WHERE address IN (%1)").arg( placeHolders.join(",") ) );
    m_sql->executePrepared(keywordsVariants, QueryId::UnblockSenders);

    validateResult(keywordsList);

    return keywordsList;
}


void QueryHelper::fetchAllLogs()
{
    m_lastUpdate = QDateTime::currentMSecsSinceEpoch();

    m_sql->setQuery("SELECT address,message,timestamp FROM logs ORDER BY timestamp DESC");
    m_sql->load(QueryId::FetchAllLogs);
}


void QueryHelper::fetchLatestLogs()
{
    m_sql->setQuery( QString("SELECT address,message,timestamp FROM logs WHERE timestamp > %1 ORDER BY timestamp").arg(m_lastUpdate) );
    m_sql->load(QueryId::FetchLatestLogs);

    m_lastUpdate = QDateTime::currentMSecsSinceEpoch();
}


void QueryHelper::validateResult(QStringList const& list)
{
    if ( list.isEmpty() ) {
        m_reporter->submitLogs(true);
    }
}


void QueryHelper::checkDatabase()
{
    QString database = BlockUtils::databasePath();

    if ( QFile::exists(database) )
    {
        m_sql->setSource(database);

        connect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
        m_updateWatcher.addPath(database);
    } else {
        LOGGER("Database does not exist");
        static int count = 0;
        recheck( count, SLOT( checkDatabase() ) );
    }
}


void QueryHelper::recheck(int &count, const char* slotName)
{
    LOGGER("Database does not exist");
    ++count;

    if (count < 5) {
        LOGGER("Retrying" << count);
        QTimer::singleShot(2000*count, this, slotName);
    } else {
        LOGGER("Can't connect...");
        Persistance::showBlockingToast( tr("Error initializing link with service. Please restart your device..."), "", "asset:///images/title_text.png" );
    }
}


void QueryHelper::databaseUpdated(QString const& path)
{
    Q_UNUSED(path);

    LOGGER("Database updated!");
    fetchLatestLogs();
}


QueryHelper::~QueryHelper()
{
}

} /* namespace oct10 */
