#include "precompiled.h"

#include "QueryHelper.h"
#include "AppLogFetcher.h"
#include "BlockUtils.h"
#include "CommonConstants.h"
#include "Logger.h"
#include "Persistance.h"
#include "TextUtils.h"

#define PLACEHOLDER "?"
#define MAX_TRANSACTION_SIZE 50
#define MAX_LOG_SIZE 300

namespace autoblock {

using namespace canadainc;

QueryHelper::QueryHelper(Persistance* persist) :
        m_sql(DATABASE_PATH), m_persist(persist), m_ms(NULL),
        m_lastUpdate( QDateTime::currentMSecsSinceEpoch() ),
        m_logSearchMode(false)
{
}



void QueryHelper::lazyInit()
{
    connect( &m_updateWatcher, SIGNAL( directoryChanged(QString const&) ), this, SLOT( checkDatabase(QString const&) ) );
    setActive(true);

#ifdef DEBUG_RELEASE
    connect( &m_sql, SIGNAL( error(QString const&) ), AppLogFetcher::getInstance(), SLOT( onError(QString const&) ) );
#else
    connect( &m_sql, SIGNAL( error(QString const&) ), &m_persist, SLOT( onError(QString const&) ) );
#endif
}


void QueryHelper::onDataLoaded(QVariant idV, QVariant data)
{
    int id = idV.toInt();

    LOGGER(id/* << data*/);

    if (id == QueryId::AttachReportedDatabase) {
        m_sql.executeQuery(this, QString("SELECT address AS %1,'%2' AS %3 FROM reported_addresses UNION SELECT term AS %1,'%4' AS %3 FROM reported_keywords").arg(FIELD_VALUE).arg(TYPE_ADDRESS).arg(FIELD_TYPE).arg(TYPE_KEYWORD), QueryId::FetchAllReported);
    } else if (id == QueryId::FetchAllReported) {
        m_sql.executeQuery(this, "DETACH DATABASE reported", QueryId::DetachReportedDatabase);
        emit dataReady(id, data);
    }
}


void QueryHelper::fetchAllBlockedKeywords(QObject* caller, QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql.executeQuery(caller, "SELECT term,count FROM inbound_keywords ORDER BY term", QueryId::FetchBlockedKeywords);
    } else {
        m_sql.executeQuery(caller, "SELECT term,count FROM inbound_keywords WHERE term LIKE '%' || ? || '%' ORDER BY term", QueryId::FetchBlockedKeywords, QVariantList() << filter);
    }
}


void QueryHelper::fetchExcludedWords(QObject* caller, QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql.executeQuery(caller, "SELECT word FROM skip_keywords ORDER BY word", QueryId::FetchExcludedWords);
    } else {
        m_sql.executeQuery(caller, "SELECT word FROM skip_keywords WHERE word LIKE '%' || ? || '%' ORDER BY word", QueryId::FetchExcludedWords, QVariantList() << filter);
    }
}


void QueryHelper::fetchAllBlockedSenders(QObject* caller, QString const& filter)
{
    if ( filter.isNull() ) {
        m_sql.executeQuery(caller, "SELECT address,count FROM inbound_blacklist ORDER BY address", QueryId::FetchBlockedSenders);
    } else {
        m_sql.executeQuery(caller, "SELECT address,count FROM inbound_blacklist WHERE address LIKE '%' || ? || '%' ORDER BY address", QueryId::FetchBlockedSenders, QVariantList() << filter);
    }
}


void QueryHelper::clearBlockedSenders()
{
    m_sql.executeClear(this, "inbound_blacklist", QueryId::UnblockSenders);
    emit refreshNeeded(QueryId::UnblockSenders);
}


void QueryHelper::clearBlockedKeywords(QObject* caller)
{
    m_sql.executeClear(caller, "inbound_keywords", QueryId::ClearKeywords);
    emit refreshNeeded(QueryId::FetchBlockedKeywords);
}


void QueryHelper::cleanInvalidEntries() {
    m_sql.executeQuery(this, "DELETE FROM inbound_blacklist WHERE address IS NULL OR trim(address) = ''", QueryId::UnblockKeywords);
}


void QueryHelper::clearLogs()
{
    m_sql.executeClear(this, "logs", QueryId::ClearLogs);
    emit refreshNeeded(QueryId::FetchAllLogs);
}


QStringList QueryHelper::blockKeywords(QObject* caller, QVariantList const& keywords)
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
        prepareTransaction(caller, "INSERT OR IGNORE INTO inbound_keywords (term) VALUES(%1)", keywords, QueryId::BlockKeywords, QueryId::BlockKeywordChunk);
    }

    return keywordsList;
}


QStringList QueryHelper::block(QObject* caller, QVariantList const& messages)
{
    LOGGER( messages.size() );

    QStringList all;
    QVariantList numbers;
    QStringList numbersList;
    QStringList placeHolders;

    if (!m_ms) {
        m_ms = new MessageService(this);
    }

    bool moveToTrash = m_persist->getValueFor("moveToTrash") == 1;

    foreach (QVariant q, messages)
    {
        QVariantMap current = q.toMap();
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
        prepareTransaction(caller, "INSERT OR IGNORE INTO inbound_blacklist (address) VALUES(%1)", numbers, QueryId::BlockSenders, QueryId::BlockSenderChunk);
    } else {
        LOGGER("[ERROR_001: No sender addresses found!]");
    }

    return numbersList;
}


void QueryHelper::prepareTransaction(QObject* caller, QString const& query, QVariantList const& elements, QueryId::Type qid, QueryId::Type chunkId)
{
    QString maxPlaceHolders = DatabaseHelper::getPlaceHolders(MAX_TRANSACTION_SIZE);

    m_sql.startTransaction(caller, chunkId);

    QVariantList chunk;

    for (int i = elements.size()-1; i >= 0; i--)
    {
        chunk << elements[i];

        if ( chunk.size() >= MAX_TRANSACTION_SIZE )
        {
            m_sql.executeQuery( caller, query.arg(maxPlaceHolders), chunkId, chunk );
            chunk.clear();
        }
    }

    int remaining = chunk.size();

    if (remaining > 0 && remaining < MAX_TRANSACTION_SIZE) {
        m_sql.executeQuery( caller, query.arg( DatabaseHelper::getPlaceHolders(remaining) ), chunkId, chunk );
    }

    m_sql.endTransaction(caller, qid);

    emit refreshNeeded(qid);
}


QStringList QueryHelper::unblockKeywords(QObject* caller, QVariantList const& keywords)
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

    m_sql.executeQuery( caller, QString("DELETE FROM inbound_keywords WHERE term IN (%1)").arg( placeHolders.join(",") ), QueryId::UnblockKeywords, keywordsVariants);
    emit refreshNeeded(QueryId::UnblockKeywords);

    return keywordsList;
}


QStringList QueryHelper::unblock(QObject* caller, QVariantList const& senders)
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

    m_sql.executeQuery( caller, QString("DELETE FROM inbound_blacklist WHERE address IN (%1)").arg( placeHolders.join(",") ), QueryId::UnblockSenders, keywordsVariants);
    emit refreshNeeded(QueryId::UnblockSenders);

    return keywordsList;
}


void QueryHelper::fetchAllLogs(QObject* caller, QString const& filter)
{
    LOGGER(filter);
    m_logSearchMode = !filter.isNull();

    if (!m_logSearchMode)
    {
        m_lastUpdate = QDateTime::currentMSecsSinceEpoch();

        m_sql.executeQuery(caller, "SELECT address,message,timestamp FROM logs ORDER BY timestamp DESC", QueryId::FetchAllLogs);
    } else {
        m_sql.executeQuery( caller, "SELECT address,message,timestamp FROM logs WHERE address LIKE '%' || ? || '%' ORDER BY timestamp DESC", QueryId::FetchAllLogs, QVariantList() << filter );
    }
}


void QueryHelper::attachReportedDatabase(QString const& tempDatabase) {
    m_sql.executeQuery( this, QString("ATTACH DATABASE '%1' AS reported").arg(tempDatabase), QueryId::AttachReportedDatabase );
}


void QueryHelper::fetchLatestLogs(QObject* caller)
{
    if (!m_logSearchMode)
    {
        m_sql.executeQuery( caller, QString("SELECT address,message,timestamp FROM logs WHERE timestamp > %1 ORDER BY timestamp").arg(m_lastUpdate), QueryId::FetchLatestLogs );
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

        disconnect( &m_updateWatcher, SIGNAL( directoryChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );

        if ( m_updateWatcher.directories().contains( QDir::homePath() ) ) {
            m_updateWatcher.removePath( QDir::homePath() );
        }

        if ( !m_updateWatcher.files().contains(DATABASE_PATH) ) {
            m_updateWatcher.addPath(DATABASE_PATH);
        }

        emit readyChanged();

        return true;
    } else {
        LOGGER("wait...");
        m_updateWatcher.addPath( QDir::homePath() );

        return false;
    }
}


void QueryHelper::optimize(QObject* caller) {
    m_sql.executeQuery(caller, "VACUUM", QueryId::Optimize);
}


void QueryHelper::databaseUpdated(QString const& path)
{
    Q_UNUSED(path);

    LOGGER("DatabaseUpdated!");
    emit refreshNeeded(QueryId::FetchLatestLogs);
}


void QueryHelper::setActive(bool active)
{
    if (active) {
        connect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
    } else {
        disconnect( &m_updateWatcher, SIGNAL( directoryChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
        disconnect( &m_updateWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( databaseUpdated(QString const&) ) );
    }
}


bool QueryHelper::ready() const {
    return QFile::exists(SETUP_FILE_PATH);
}


Persistance* QueryHelper::getPersist() {
    return m_persist;
}


QueryHelper::~QueryHelper()
{
}

} /* namespace oct10 */
