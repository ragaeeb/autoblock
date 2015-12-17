#include "precompiled.h"

#include "service.hpp"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "PimUtil.h"

#include "bbndk.h"

#define MAX_BODY_LENGTH 160

namespace autoblock {

using namespace bb::pim::account;
using namespace bb::multimedia;
using namespace bb::platform;
using namespace bb::pim::message;
using namespace bb::system;
using namespace bb::system::phone;
using namespace canadainc;

Service::Service(bb::Application* app) : QObject(app)
{
	connect( this, SIGNAL( initialize() ), this, SLOT( init() ), Qt::QueuedConnection ); // async startup
	emit initialize();
}


void Service::setup(bool replace)
{
    QStringList qsl;
    qsl << "CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT NOT NULL, message TEXT, timestamp INTEGER NOT NULL)";
    qsl << "CREATE TABLE IF NOT EXISTS inbound_blacklist ( address TEXT PRIMARY KEY, count INTEGER DEFAULT 0, CHECK(address <> '') )";
    qsl << "CREATE TABLE IF NOT EXISTS inbound_keywords ( term TEXT PRIMARY KEY, count INTEGER DEFAULT 0, CHECK(term <> '') )";
    qsl << "CREATE TABLE IF NOT EXISTS outbound_blacklist ( address TEXT PRIMARY KEY, count INTEGER DEFAULT 0, CHECK(address <> '') )";
    qsl << "CREATE TABLE IF NOT EXISTS skip_keywords ( word TEXT PRIMARY KEY, CHECK(word <> '') )";
    qsl << "INSERT OR IGNORE INTO skip_keywords (word) VALUES ('and'),('able'),('after'),('but'),('can'),('did'),('for'),('from'),('had'),('have'),('into'),('not'),('over'),('same'),('see'),('the'),('that'),('this'),('their'),('there'),('these'),('they'),('thing'),('this'),('was'),('will'),('with'),('would')";
    qsl << "DELETE FROM inbound_blacklist WHERE address IS NULL OR trim(address) = ''";
    qsl << "DELETE FROM inbound_keywords WHERE term IS NULL OR trim(term) = ''";

    if ( !QFile::exists(DATABASE_PATH) )
    {
        bool result = IOUtils::writeFile(DATABASE_PATH);
        LOGGER("WroteDatabase" << result);
    }

    m_sql.startTransaction(QueryId::SettingUp);

    foreach (QString const& query, qsl) {
        m_sql.execute(query, QueryId::SettingUp);
    }

    m_sql.endTransaction(QueryId::Setup);
}


void Service::init()
{
    m_sql.setSource(DATABASE_PATH);

    if ( !QFile::exists( m_settings.fileName() ) )
    {
        m_settings.setValue("days", 3);
        m_settings.sync();
    }

    m_settingsWatcher.addPath( m_settings.fileName() );

    connect( &m_invokeManager, SIGNAL( invoked(const bb::system::InvokeRequest&) ), this, SLOT( handleInvoke(const bb::system::InvokeRequest&) ) );
    connect( &m_sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ) );
    connect( &m_settingsWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( settingChanged(QString const&) ), Qt::QueuedConnection );
    connect( &m_manager, SIGNAL( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ), this, SLOT( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ) );
    connect( &m_phone, SIGNAL( callUpdated(const bb::system::phone::Call&) ), this, SLOT( callUpdated(const bb::system::phone::Call&) ) );

    setup();
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
        IOUtils::writeFile(SETUP_FILE_PATH);
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
#if BBNDK_VERSION_AT_LEAST(10,3,0)
    if ( !m_queue.callQueue.isEmpty() )
    {
        Call c = m_queue.callQueue.dequeue();
        m_queue.phoneToPending.remove( c.phoneNumber() );
        LOGGER("CallSpamMatched");

        if ( !result.isEmpty() )
        {
            bool ended = m_phone.endCall( c.callId() );

            updateLog( c.phoneNumber(), ended ? tr("Successfully terminated call") : tr("Could not terminate call") );
            updateCount(result, "address", "inbound_blacklist", QueryId::BlockSenders);
        }
    }
#endif
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
            subjectBody = subjectBody.trimmed().toLower();

            if (m_options.ignorePunctuation) {
                subjectBody.remove(PUNCTUATION);
            }

            QStringList subjectTokens = subjectBody.split(" ");
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
    if ( !path.isEmpty() ) {
        m_settings.sync();
    }

	m_options.blockStrangers = m_settings.value("blockStrangers").toInt() == 1;
	m_options.ignorePunctuation = m_settings.value("ignorePunctuation").toInt() == 1;
	m_options.moveToTrash = m_settings.value("moveToTrash").toInt() == 1;
	m_options.scanName = m_settings.value("scanName").toInt() == 1;
	m_options.scanAddress = m_settings.value("scanAddress").toInt() == 1;
    m_options.sound = m_settings.value("sound").toInt() == 1;
    m_options.threshold = m_settings.value("keywordThreshold").toInt();
    m_options.whitelistContacts = m_settings.value("whitelistContacts").toInt() == 1;
}


void Service::handleInvoke(bb::system::InvokeRequest const& request)
{
    if ( !request.data().isNull() )
    {
        QString command = QString( request.data() );

        if (command == "terminate") {
            LOGGER("Kill switch! Terminating service...");
            bb::Application::instance()->quit();
        } else if (command == "setup") {
            LOGGER("Force setup...");
            setup(false);
        } else if (command == "test") {
            QVariantMap data = request.metadata();
            LOGGER("Testing" << data);

            QDateTime now = QDateTime::currentDateTime();
            QString body = data["body"].toString();

            MessageBuilder* mb = MessageBuilder::create( AccountService().defaultAccount(bb::pim::account::Service::Messages).id() );
            mb->inbound(true);
            mb->deviceTimestamp(now);
            mb->serverTimestamp(now);
            mb->subject(body);
            mb->body( MessageBody::PlainText, body.toAscii() );
            mb->sender( MessageContact( 0, MessageContact::From, data["name"].toString(), data["address"].toString() ) );
            process( *mb );
            delete mb;
        }
    }
}


void Service::callUpdated(bb::system::phone::Call const& call)
{
#if BBNDK_VERSION_AT_LEAST(10,3,0)
    int callId = call.callId();
    QString phoneNumber = call.phoneNumber();
    CallType::Type t = call.callType();
    CallState::Type s = call.callState();

    LOGGER(callId << phoneNumber << t << s);

    if ( t == CallType::Incoming && s == CallState::Incoming && !phoneNumber.isEmpty() )
    {
        if ( !m_queue.phoneToPending.contains(phoneNumber) && m_queue.lastCallId != callId )
        {
            m_queue.callQueue << call;
            m_queue.phoneToPending.insert(phoneNumber, true);
            m_queue.lastCallId = callId;

            m_sql.setQuery( QString("SELECT address FROM inbound_blacklist WHERE address='%1'").arg(phoneNumber) );
            m_sql.load(QueryId::LookupCaller);
        }
    }
#else
    Q_UNUSED(call);
#endif
}


void Service::messageAdded(bb::pim::account::AccountKey ak, bb::pim::message::ConversationKey ck, bb::pim::message::MessageKey mk)
{
	Q_UNUSED(ck);

	process( m_manager.message(ak, mk) );
}


void Service::process(Message const& m)
{
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


Service::~Service() {
    QFile::remove(SETUP_FILE_PATH);
}

}
