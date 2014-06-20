#include "precompiled.h"

#include "service.hpp"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "LogMonitor.h"
#include "PimUtil.h"

#include "bbndk.h"

#define MAX_BODY_LENGTH 160

namespace {

QStringList createSkipKeywords()
{
    QStringList qsl;
    qsl << "CREATE TABLE IF NOT EXISTS skip_keywords (word TEXT PRIMARY KEY)";
    qsl << "INSERT OR REPLACE INTO skip_keywords (word) VALUES ('able'),('after'),('from'),('have'),('into'),('over'),('same'),('that'),('their'),('there'),('these'),('they'),('thing'),('this'),('will'),('with'),('would')";
    return qsl;
}

}

namespace autoblock {

using namespace bb::multimedia;
using namespace bb::platform;
using namespace bb::system;
using namespace bb::system::phone;
using namespace canadainc;

Service::Service(bb::Application* app) : QObject(app), m_logMonitor(NULL)
{
    connect( &m_invokeManager, SIGNAL( invoked(const bb::system::InvokeRequest&) ), this, SLOT( handleInvoke(const bb::system::InvokeRequest&) ) );
    connect( &m_sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ) );

    QString database = BlockUtils::databasePath();
    m_sql.setSource(database);

    if ( !QFile(database).exists() )
    {
        QStringList qsl;
        qsl << "CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT NOT NULL, message TEXT, timestamp INTEGER NOT NULL)";
        qsl << "CREATE TABLE IF NOT EXISTS inbound_blacklist (address TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
        qsl << "CREATE TABLE IF NOT EXISTS inbound_keywords (term TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
        qsl << "CREATE TABLE IF NOT EXISTS outbound_blacklist (address TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
        qsl << createSkipKeywords();
        m_sql.initSetup(qsl, QueryId::Setup);
    }

	connect( this, SIGNAL( initialize() ), this, SLOT( init() ), Qt::QueuedConnection ); // async startup
	emit initialize();
}


void Service::init()
{
    QSettings s;

    if ( !QFile::exists( s.fileName() ) )
    {
        s.setValue( "init", QDateTime::currentMSecsSinceEpoch() );
        s.sync();
    }

    m_settingsWatcher.addPath( s.fileName() );

    if ( !s.contains("v3.0") ) {
        m_sql.executeTransaction( createSkipKeywords(), QueryId::Setup );
        s.setValue("v3.0", 1);
    }

    m_logMonitor = new LogMonitor(SERVICE_KEY, SERVICE_LOG_FILE, this);

    connect( &m_settingsWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( settingChanged(QString const&) ), Qt::QueuedConnection );
    connect( &m_manager, SIGNAL( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ), this, SLOT( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ) );
    connect( &m_phone, SIGNAL( callUpdated(const bb::system::phone::Call&) ), this, SLOT( callUpdated(const bb::system::phone::Call&) ) );

	settingChanged();

    Notification::clearEffectsForAll();
    Notification::deleteAllFromInbox();
}


void Service::dataLoaded(int id, QVariant const& data)
{
    LOGGER(id << data);

    if (id == QueryId::LookupSender) {
        LOGGER("LookupSender");
        processSenders( data.toList() );
    } else if (id == QueryId::LookupKeyword) {
        LOGGER("LookupKeyword");
        processKeywords( data.toList() );
    } else if (id == QueryId::Setup) {
        IOUtils::writeFile( BlockUtils::setupFilePath() );
    } else if (id == QueryId::LookupCaller) {
        processCalls( data.toList() );
    }
}


void Service::processKeywords(QVariantList result)
{
    LOGGER( result.size() << m_options.threshold << m_queue.keywordQueue.size() );

    if ( !m_queue.keywordQueue.isEmpty() )
    {
        Message m = m_queue.keywordQueue.dequeue();

        if ( result.size() >= m_options.threshold )
        {
            LOGGER("KeywordSpamMatched!");
            spamDetected(m);
            updateCount(result, "term", "inbound_keywords", QueryId::BlockKeywords);
        }
    }
}


void Service::processCalls(QVariantList result)
{
    LOGGER( result.size() << m_queue.callQueue.size() );

    if ( !m_queue.callQueue.isEmpty() )
    {
        Call c = m_queue.callQueue.dequeue();
        m_queue.phoneToPending.remove( c.phoneNumber() );
        LOGGER("CallSpamMached");

        bool ended = m_phone.endCall( c.callId() );

        updateLog( c.phoneNumber(), ended ? tr("Successfully terminated call") : tr("Could not terminate call") );
        updateCount(result, "address", "inbound_blacklist", QueryId::BlockSenders);
    }
}


void Service::updateLog(QString const& address, QString const& message)
{
    if (m_options.sound) {
        SystemSound::play(SystemSound::RecordingStartEvent);
    }

    m_sql.setQuery( QString("INSERT INTO logs (address,message,timestamp) VALUES (?,?,%1)").arg( QDateTime::currentMSecsSinceEpoch() ) );
    m_sql.executePrepared( QVariantList() << address << message, QueryId::LogTransaction );
}


void Service::spamDetected(Message const& m)
{
    QString body = PimUtil::extractText(m);

    if ( body.isEmpty() ) {
        body = m.subject().trimmed();
    }

    if (m_options.moveToTrash)
    {
        if ( !BlockUtils::moveToTrash( m.accountId(), m.id(), &m_manager, m_accountToTrash) ) {
            forceDelete(m);
        } else {
            LOGGER("MovedToTrash!");
        }
    } else {
        forceDelete(m);
    }

    if ( body.length() > MAX_BODY_LENGTH ) {
        body = QString("%1...").arg( body.left(MAX_BODY_LENGTH) );
    }

    updateLog( m.sender().address(), body );
}


void Service::forceDelete(Message const& m)
{
    m_manager.remove( m.accountId(), m.id() );
    m_manager.remove( m.accountId(), m.conversationId() );
    LOGGER("deleted");
}


void Service::updateCount(QVariantList result, QString const& field, QString const& table, QueryId::Type t)
{
    QStringList placeHolders;

    for (int i = result.size()-1; i >= 0; i--) {
        result[i] = result[i].toMap().value(field);
        placeHolders << "?";
    }

    m_sql.setQuery( QString("UPDATE %3 SET count=count+1 WHERE %2 IN (%1)").arg( placeHolders.join(",") ).arg(field).arg(table) );
    m_sql.executePrepared(result, t);
}


void Service::processSenders(QVariantList result)
{
    LOGGER( result << m_queue.senderQueue.size() );

    if ( !m_queue.senderQueue.isEmpty() )
    {
        Message m = m_queue.senderQueue.dequeue();

        if ( !result.isEmpty() )
        {
            spamDetected(m);
            updateCount(result, "address", "inbound_blacklist", QueryId::BlockSenders);
        } else {
            QString subjectBody = m.accountId() == ACCOUNT_KEY_SMS ? PimUtil::extractText(m) : m.subject();
            QStringList subjectTokens = subjectBody.trimmed().toLower().split(" ");
            LOGGER("SubjectTokens" << subjectTokens);
            QVariantList keywords;
            QStringList placeHolders;

            if (m_options.scanName) {
                subjectTokens << m.sender().name().trimmed().toLower().split(" ");
            }

            for (int i = subjectTokens.size()-1; i >= 0; i--)
            {
                QString current = BlockUtils::isValidKeyword(subjectTokens[i]);

                if ( !current.isNull() ) {
                    keywords << current;
                    placeHolders << "?";
                }
            }

            LOGGER("KeywordsCheck" << keywords);

            if ( !keywords.isEmpty() )
            {
                m_queue.keywordQueue << m;

                QString keywordQuery = QString("SELECT term FROM inbound_keywords WHERE term IN (%1)").arg( placeHolders.join(",") );

                if (m_options.scanAddress)
                {
                    QString senderAddress = m.sender().address().trimmed().toLower();

                    if ( !senderAddress.isEmpty() ) {
                        keywordQuery = QString("%1 OR '%2' LIKE '%' || term || '%'").arg(keywordQuery).arg(senderAddress);
                    }
                }

                m_sql.setQuery(keywordQuery);
                m_sql.executePrepared(keywords, QueryId::LookupKeyword);
            }
        }
    }
}


void Service::settingChanged(QString const& path)
{
    Q_UNUSED(path);

	QSettings q;
	m_options.blockStrangers = q.value("blockStrangers").toInt() == 1;
	m_options.moveToTrash = q.value("moveToTrash").toInt() == 1;
	m_options.scanName = q.value("scanName").toInt() == 1;
	m_options.scanAddress = q.value("scanAddress").toInt() == 1;
    m_options.sound = q.value("sound").toInt() == 1;
    m_options.threshold = q.value("keywordThreshold").toInt();
    m_options.whitelistContacts = q.value("whitelistContacts").toInt() == 1;
}


void Service::handleInvoke(const bb::system::InvokeRequest & request)
{
    if ( !request.data().isNull() )
    {
        QString command = QString( request.data() );

        if ( command.compare("terminate", Qt::CaseInsensitive) == 0 ) {
            LOGGER("Kill switch! Terminating service...");
            bb::Application::instance()->quit();
        }
    }
}


void Service::callUpdated(bb::system::phone::Call const& call)
{
    LOGGER( call.callId() << call.phoneNumber() << call.callType() << call.callState() );

    if ( call.callType() == CallType::Incoming && call.callState() == CallState::Incoming && !call.phoneNumber().isEmpty() )
    {
#if BBNDK_VERSION_AT_LEAST(10,3,0)
        QString phoneNumber = call.phoneNumber();

        if ( !m_queue.phoneToPending.contains(phoneNumber) )
        {
            m_queue.callQueue << call;
            m_queue.phoneToPending.insert(phoneNumber, true);

            m_sql.setQuery( QString("SELECT address FROM inbound_blacklist WHERE address='%1'").arg(phoneNumber) );
            m_sql.load(QueryId::LookupCaller);
        }
#endif
    }
}


void Service::messageAdded(bb::pim::account::AccountKey ak, bb::pim::message::ConversationKey ck, bb::pim::message::MessageKey mk)
{
	Q_UNUSED(ck);

	Message m = m_manager.message(ak, mk);
    LOGGER( m.subject() << "[message_id]" << m.id() << "[sender_id]" << m.sender().id() );

    bool stranger = !m.sender().id();

    if ( m_options.blockStrangers && stranger && m.isInbound() ) {
        LOGGER("blocking non-contact!");
        spamDetected(m);
    } else if ( (!m_options.whitelistContacts || stranger) && m.isInbound() ) { // is not a contact, or contacts are not whitelisted so force look up
	    QString sender = m.sender().address().toLower();
	    QString replyTo = m.replyTo().address().toLower();

	    QStringList placeHolders("?");

	    QVariantList addresses;
	    addresses << sender;

	    if ( !replyTo.isEmpty() && sender.compare(replyTo, Qt::CaseInsensitive) != 0 ) {
	        addresses << replyTo;
	        placeHolders << "?";
	    }

	    m_queue.senderQueue << m;

	    m_sql.setQuery( QString("SELECT address FROM inbound_blacklist WHERE address IN (%1)").arg( placeHolders.join(",") ) );
	    m_sql.executePrepared(addresses, QueryId::LookupSender);
	}
}

}
