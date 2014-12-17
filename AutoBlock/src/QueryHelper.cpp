#include "precompiled.h"

#include "QueryHelper.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "customsqldatasource.h"
#include "Logger.h"
#include "Persistance.h"

#define PLACEHOLDER "?"
#define MAX_TRANSACTION_SIZE 50
#define MAX_LOG_SIZE 300

namespace {

QString getPlaceHolders(int n)
{
    QStringList placeHolders;

    for (int i = 0; i < n; i++) {
        placeHolders << PLACEHOLDER;
    }

    return placeHolders.join("),(");
}

}

namespace autoblock {

using namespace canadainc;

QueryHelper::QueryHelper(CustomSqlDataSource* sql, Persistance* persist) :
        m_sql(sql), m_persist(persist), m_ms(NULL),
        m_lastUpdate( QDateTime::currentMSecsSinceEpoch() ),
        m_logSearchMode(false)
{
    connect( sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ) );
    connect( sql, SIGNAL( error(QString const&) ), this, SLOT( onError(QString const&) ) );
    connect( &m_updateWatcher, SIGNAL( directoryChanged(QString const&) ), this, SLOT( checkDatabase(QString const&) ) );
    setActive(true);
}


void QueryHelper::onError(QString const& errorMessage)
{
    LOGGER(errorMessage);

#if defined(QT_NO_DEBUG)
    AppLogFetcher::getInstance()->submitLogs("[AutoBlock]: queryError");
#endif
}


void QueryHelper::dataLoaded(int id, QVariant const& data)
{
    LOGGER(id/* << data*/);

    if (id == QueryId::UnblockKeywords || id == QueryId::BlockKeywords) {
        fetchAllBlockedKeywords();
    } else if (id == QueryId::AttachReportedDatabase) {
        m_sql->setQuery("SELECT address AS value FROM reported_addresses");
        m_sql->load(QueryId::FetchAllReported);
    } else if (id == QueryId::FetchAllReported) {
        m_sql->setQuery("DETACH DATABASE reported");
        m_sql->load(QueryId::DetachReportedDatabase);
        emit dataReady(id, data);
    } else {
        if (id == QueryId::UnblockSenders || id == QueryId::BlockSenders) {
            fetchAllBlockedSenders();
        }

        emit dataReady(id, data);
    }
}


void QueryHelper::fetchAllBlockedKeywords(QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql->setQuery("SELECT term,count FROM inbound_keywords ORDER BY term");
        m_sql->load(QueryId::FetchBlockedKeywords);
    } else {
        m_sql->setQuery("SELECT term,count FROM inbound_keywords WHERE term LIKE '%' || ? || '%' ORDER BY term");
        m_sql->executePrepared( QVariantList() << filter, QueryId::FetchBlockedKeywords );
    }
}


void QueryHelper::fetchExcludedWords(QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql->setQuery("SELECT word FROM skip_keywords ORDER BY word");
        m_sql->load(QueryId::FetchExcludedWords);
    } else {
        m_sql->setQuery("SELECT word FROM skip_keywords WHERE word LIKE '%' || ? || '%' ORDER BY word");
        m_sql->executePrepared( QVariantList() << filter, QueryId::FetchExcludedWords );
    }
}


void QueryHelper::fetchAllBlockedSenders(QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql->setQuery("SELECT address,count FROM inbound_blacklist ORDER BY address");
        m_sql->load(QueryId::FetchBlockedSenders);
    } else {
        m_sql->setQuery("SELECT address,count FROM inbound_blacklist WHERE address LIKE '%' || ? || '%' ORDER BY address");
        m_sql->executePrepared( QVariantList() << filter, QueryId::FetchBlockedSenders );
    }
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


void QueryHelper::cleanInvalidEntries()
{
    m_sql->setQuery("DELETE FROM inbound_blacklist WHERE address IS NULL OR trim(address) = ''");
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

    QStringList keywordsList;

    for (int i = keywords.size()-1; i >= 0; i--)
    {
        QString current = keywords[i].toString().trimmed();

        if ( !current.isEmpty() ) {
            keywordsList << current;
        }
    }

    if ( !keywordsList.isEmpty() ) {
        prepareTransaction("INSERT OR IGNORE INTO inbound_keywords (term) VALUES(%1)", keywords, QueryId::BlockKeywords, QueryId::BlockKeywordChunk);
    }

    return keywordsList;
}


QStringList QueryHelper::block(QVariantList const& addresses)
{
    LOGGER( addresses.size() << addresses );

    QStringList all;
    QVariantList numbers;
    QStringList numbersList;
    QStringList placeHolders;

    if (!m_ms) {
        m_ms = new MessageService(this);
    }

    bool moveToTrash = m_persist->getValueFor("moveToTrash") == 1;

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

        if ( !replyTo.isEmpty() && replyTo.compare(address, Qt::CaseInsensitive) != 0 )
        {
            numbers << replyTo;
            numbersList << replyTo;
            placeHolders << PLACEHOLDER;
        }

        if ( current.contains("aid") )
        {
            qint64 aid = current.value("aid").toLongLong();
            qint64 mid = current.value("id").toLongLong();

            if ( !moveToTrash || !BlockUtils::moveToTrash(aid, mid, m_ms, m_accountToTrash) )
            {
                m_ms->remove(aid, mid);
                m_ms->remove( aid, current.value("cid").toString() );
            }
        }
    }

    if ( !numbers.isEmpty() ) {
        prepareTransaction("INSERT OR IGNORE INTO inbound_blacklist (address) VALUES(%1)", numbers, QueryId::BlockSenders, QueryId::BlockSenderChunk);
    } else {
        LOGGER("[ERROR_001: No sender addresses found!]");
    }

    return numbersList;
}


void QueryHelper::prepareTransaction(QString const& query, QVariantList const& elements, QueryId::Type qid, QueryId::Type chunkId)
{
    static QString maxPlaceHolders = getPlaceHolders(MAX_TRANSACTION_SIZE);

    m_sql->startTransaction(chunkId);

    QVariantList chunk;

    for (int i = elements.size()-1; i >= 0; i--)
    {
        chunk << elements[i];

        if ( chunk.size() >= MAX_TRANSACTION_SIZE )
        {
            m_sql->setQuery( query.arg(maxPlaceHolders) );
            m_sql->executePrepared(chunk, chunkId);
            chunk.clear();
        }
    }

    int remaining = chunk.size();

    if (remaining < MAX_TRANSACTION_SIZE)
    {
        m_sql->setQuery( query.arg( getPlaceHolders(remaining) ) );
        m_sql->executePrepared(chunk, chunkId);
    }

    m_sql->endTransaction(qid);
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

    return keywordsList;
}


void QueryHelper::fetchAllLogs(QString const& filter)
{
    LOGGER(filter);
    m_logSearchMode = !filter.isNull();

    if (!m_logSearchMode)
    {
        m_lastUpdate = QDateTime::currentMSecsSinceEpoch();

        m_sql->setQuery("SELECT address,message,timestamp FROM logs ORDER BY timestamp DESC");
        m_sql->load(QueryId::FetchAllLogs);
    } else {
        m_sql->setQuery("SELECT address,message,timestamp FROM logs WHERE address LIKE '%' || ? || '%' ORDER BY timestamp DESC");
        m_sql->executePrepared( QVariantList() << filter, QueryId::FetchAllLogs );
    }
}


void QueryHelper::attachReportedDatabase(QString const& tempDatabase)
{
    m_sql->setQuery( QString("ATTACH DATABASE '%1' AS reported").arg(tempDatabase) );
    m_sql->load(QueryId::AttachReportedDatabase);
}


void QueryHelper::fetchLatestLogs()
{
    if (!m_logSearchMode)
    {
        m_sql->setQuery( QString("SELECT address,message,timestamp FROM logs WHERE timestamp > %1 ORDER BY timestamp").arg(m_lastUpdate) );
        m_sql->load(QueryId::FetchLatestLogs);

        m_lastUpdate = QDateTime::currentMSecsSinceEpoch();
    }
}


bool QueryHelper::checkDatabase(QString const& path)
{
    Q_UNUSED(path);

    LOGGER("checking");

    if ( ready() )
    {
        LOGGER("ready...");
        m_sql->setSource( BlockUtils::databasePath() );

        m_updateWatcher.removePath( QDir::homePath() );
        m_updateWatcher.addPath( BlockUtils::databasePath() );

        emit readyChanged();

        return true;
    } else {
        LOGGER("wait...");
        m_updateWatcher.addPath( QDir::homePath() );

        return false;
    }
}


void QueryHelper::optimize()
{
    m_sql->setQuery("VACUUM");
    m_sql->load(QueryId::Optimize);
}


void QueryHelper::databaseUpdated(QString const& path)
{
    Q_UNUSED(path);

    LOGGER("DatabaseUpdated!");
    fetchLatestLogs();
}


void QueryHelper::setActive(bool active)
{
    if (active) {
        connect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
    } else {
        disconnect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
    }
}


bool QueryHelper::ready() const {
    return QFile::exists( BlockUtils::setupFilePath() );
}


Persistance* QueryHelper::getPersist() {
    return m_persist;
}


QueryHelper::~QueryHelper()
{
}

} /* namespace oct10 */
