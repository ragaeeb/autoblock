#include "precompiled.h"

#include "service.hpp"
#include "BlockUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "MessageManager.h"
#include "PimUtil.h"
#include "QueryId.h"

#define MAX_BODY_LENGTH 160

namespace autoblock {

using namespace bb::multimedia;
using namespace bb::platform;
using namespace bb::system;
using namespace canadainc;

Service::Service(bb::Application * app)	:
        QObject(app), m_sound(false), m_threshold(3)
{
	QSettings s;

	if ( !QFile::exists( s.fileName() ) )
	{
		s.setValue( "init", QDateTime::currentMSecsSinceEpoch() );
		s.sync();
	}

	LOGGER("Constructed");

	connect( this, SIGNAL( initialize() ), this, SLOT( init() ), Qt::QueuedConnection ); // async startup

	emit initialize();
}


void Service::init()
{
    QSettings s;
	m_settingsWatcher.addPath( s.fileName() );

	connect( &m_invokeManager, SIGNAL( invoked(const bb::system::InvokeRequest&) ), this, SLOT( handleInvoke(const bb::system::InvokeRequest&) ) );
	connect( &m_settingsWatcher, SIGNAL( fileChanged(QString const&) ), this, SLOT( settingChanged(QString const&) ) );
	connect( &m_sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ) );
    connect( &m_manager, SIGNAL( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ), this, SLOT( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ) );

	QString database = BlockUtils::databasePath();
	m_sql.setSource(database);

	if ( !QFile(database).exists() )
	{
		QStringList qsl;
		qsl << "CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT NOT NULL, message TEXT, timestamp INTEGER NOT NULL)";
		qsl << "CREATE TABLE inbound_blacklist (address TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
		qsl << "CREATE TABLE inbound_keywords (term TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
		qsl << "CREATE TABLE outbound_blacklist (address TEXT PRIMARY KEY, count INTEGER DEFAULT 0)";
		m_sql.initSetup(qsl, QueryId::Setup);
	}

	settingChanged();

    Notification::clearEffectsForAll();
    Notification::deleteAllFromInbox();
}


void Service::dataLoaded(int id, QVariant const& data)
{
    LOGGER("Data loaded" << id << data);

    if (id == QueryId::LookupSender) {
        LOGGER("LookupSender");
        processSenders( data.toList() );
    } else if (QueryId::LookupKeyword) {
        LOGGER("LookupKeyword");
        processKeywords( data.toList() );
    }
}


void Service::processKeywords(QVariantList result)
{
    LOGGER("Process keywords result" << result.size() << m_threshold << m_keywordQueue.size());

    if ( !m_keywordQueue.isEmpty() )
    {
        LOGGER("Spam matched!");
        Message m = m_keywordQueue.dequeue();

        if ( result.size() >= m_threshold )
        {
            spamDetected(m);

            QStringList placeHolders;

            for (int i = result.size()-1; i >= 0; i--) {
                result[i] = result[i].toMap().value("term");
                placeHolders << "?";
            }

            m_sql.setQuery( QString("UPDATE inbound_keywords SET count=count+1 WHERE term IN (%1)").arg( placeHolders.join(",") ) );
            m_sql.executePrepared(result, QueryId::BlockKeywords);
        }
    }
}


void Service::spamDetected(Message const& m)
{
    QString body = PimUtil::extractText(m);

    if ( body.isEmpty() ) {
        body = m.subject().trimmed();
    }

    LOGGER("Matches found, deleting messages");
    m_manager.remove( m.accountId(), m.id() );
    m_manager.remove( m.accountId(), m.conversationId() );
    LOGGER("Matches found, deleted");

    if (m_sound) {
        SystemSound::play(SystemSound::RecordingStartEvent);
    }

    QVariantList params = QVariantList() << m.sender().address();

    if ( body.length() > MAX_BODY_LENGTH ) {
        params << QString("%1...").arg( body.left(MAX_BODY_LENGTH) );
    } else {
        params << body;
    }

    m_sql.setQuery( QString("INSERT INTO logs (address,message,timestamp) VALUES (?,?,%1)").arg( QDateTime::currentMSecsSinceEpoch() ) );
    m_sql.executePrepared(params, QueryId::LogTransaction);
}


void Service::processSenders(QVariantList result)
{
    LOGGER("Process senders" << result << m_senderQueue.size());

    if ( !m_senderQueue.isEmpty() )
    {
        Message m = m_senderQueue.dequeue();

        if ( !result.isEmpty() ) {
            spamDetected(m);

            QStringList placeHolders;

            for (int i = result.size()-1; i >= 0; i--) {
                result[i] = result[i].toMap().value("address");
                placeHolders << "?";
            }

            m_sql.setQuery( QString("UPDATE inbound_blacklist SET count=count+1 WHERE address IN (%1)").arg( placeHolders.join(",") ) );
            m_sql.executePrepared(result, QueryId::BlockSenders);

        } else {
            QString subjectBody = m.accountId() == MessageManager::account_key_sms ? PimUtil::extractText(m) : m.subject();
            QStringList subjectTokens = subjectBody.trimmed().toLower().split(" ");
            LOGGER("SubjectTokens" << subjectTokens);
            QVariantList keywords;
            QStringList placeHolders;

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
                m_keywordQueue << m;

                m_sql.setQuery( QString("SELECT term FROM inbound_keywords WHERE term IN (%1) COLLATE NOCASE").arg( placeHolders.join(",") ) );
                m_sql.executePrepared(keywords, QueryId::LookupKeyword);
            }
        }
    }
}


void Service::settingChanged(QString const& path)
{
	LOGGER("Recalculate!" << path);

	QSettings q;

	m_sound = q.value("sound").toInt() == 1;
	m_threshold = q.value("keywordThreshold").toInt();

	LOGGER("sound: " << m_sound << "threshold" << m_threshold);
}


void Service::handleInvoke(const bb::system::InvokeRequest & request)
{
	LOGGER("Invoekd" << request.action() );

	if ( request.action().compare("com.canadainc.AutoBlockService.KILL") == 0 ) {
	    bb::Application::instance()->quit();
	}
}


void Service::messageAdded(bb::pim::account::AccountKey ak, bb::pim::message::ConversationKey ck, bb::pim::message::MessageKey mk)
{
	Q_UNUSED(ck);

	Message m = m_manager.message(ak, mk);
    LOGGER("======== NEW MESSAGE" << ak << "message id" << m.subject() << "message id" << m.id() << "senderid" << m.sender().id() );

	if ( !m.sender().id() && m.isInbound() ) // is not a contact
	{
	    QString sender = m.sender().address();
	    QString replyTo = m.replyTo().address();

	    QStringList placeHolders("?");

	    QVariantList addresses;
	    addresses << sender;

	    if ( !replyTo.isEmpty() && sender.compare(replyTo, Qt::CaseInsensitive) != 0 ) {
	        addresses << replyTo;
	        placeHolders << "?";
	    }

	    m_senderQueue << m;

	    m_sql.setQuery( QString("SELECT address FROM inbound_blacklist WHERE address IN (%1) COLLATE NOCASE").arg( placeHolders.join(",") ) );
	    m_sql.executePrepared(addresses, QueryId::LookupSender);
	}
}

}
