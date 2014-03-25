#include "MessageManager.h"

#include <bb/pim/message/MessageBuilder>
#include <bb/pim/message/MessageFilter>
#include <bb/pim/message/MessageService>

namespace canadainc {

using namespace bb::pim::account;
using namespace bb::pim::message;

#if !defined(QT_NO_DEBUG)
#include <QDebug>

#define LOGGER(a) qDebug() << "==============" << __TIME__ << __FILE__ << __LINE__ << __FUNCTION__ << a
#else
#define LOGGER(a)
#endif

const int MessageManager::account_key_sms = 23;

MessageManager::MessageManager(qint64 accountKey, QObject* parent) :
		QObject(parent), m_ms(NULL), m_accountKey(accountKey), m_connected(false)
{
}


void MessageManager::initService()
{
	if (m_ms == NULL) {
		m_ms = new MessageService(this);
	}
}


bool MessageManager::setMonitoring(bool monitor)
{
	initService();

	if (monitor && !m_connected)
	{
    	LOGGER("Connecting to messageAdded signal");
    	m_connected = connect( m_ms, SIGNAL( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ), this, SLOT( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ) );
    	m_connected = connect( m_ms, SIGNAL( messageUpdated(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey, bb::pim::message::MessageUpdate) ), this, SLOT( messageUpdated(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey, bb::pim::message::MessageUpdate) ) );
    	emit monitoringStateChanged();
	} else if (!monitor & m_connected) {
		LOGGER("Disconnected");
		disconnect( m_ms, SIGNAL( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ), this, SLOT( messageAdded(bb::pim::account::AccountKey, bb::pim::message::ConversationKey, bb::pim::message::MessageKey) ) );
		m_connected = false;
		emit monitoringStateChanged();
	}

	return m_connected;
}


bool MessageManager::monitoring() const {
	return m_connected;
}


void MessageManager::remove(QString const& ck, qint64 mk)
{
	LOGGER("REMOVING >>>>>>>" << ck << mk << m_accountKey);
	initService();

	m_ms->remove(m_accountKey, mk);
	m_ms->remove(m_accountKey, ck);
}


qint64 MessageManager::sendMessage(Message const& m, QString text, QList<Attachment> const& attachments, bool replyPrefix)
{
	QString ck = m.conversationId();
	LOGGER("==========" << m.sender().address() << ck << text << m_accountKey);
	initService();

	const MessageContact from = m.sender();

	MessageBuilder* mb = MessageBuilder::create(m_accountKey);
	mb->conversationId(ck);

	if (m_accountKey != account_key_sms) {
		LOGGER("ADDING BODY TEXT" << text);
	    const MessageContact mc = MessageContact( from.id(), MessageContact::To, from.name(), from.address() );
		mb->addRecipient(mc);
		mb->subject( replyPrefix ? tr("RE: %1").arg( m.subject() ) : m.subject() );
		mb->body( MessageBody::Html, text.replace("\n", "<br>").toUtf8() );
	} else {
		mb->addRecipient(from);

		LOGGER("ADDING ATTACHMENT TEXT" << text);
		mb->addAttachment( Attachment("text/plain", "<primary_text.txt>", text) );
	}

	for (int i = attachments.size()-1; i >= 0; i--) {
		mb->addAttachment( attachments[i] );
	}

	LOGGER("Replying with" << m.sender().displayableName() << ck << text);

	Message reply = *mb;
	LOGGER("======== USING ACCOUNT KEY" << m_accountKey );
	MessageKey mk = m_ms->send(m_accountKey, reply);

	LOGGER("Sent, now deleting messagebuilder" << mk );

	delete mb;

	return mk;
}


void MessageManager::messageAdded(bb::pim::account::AccountKey ak, bb::pim::message::ConversationKey ck, bb::pim::message::MessageKey mk)
{
	Q_UNUSED(ck);

	LOGGER("messageAdded()" << ak << m_accountKey);

	if (!m_accountKey || m_accountKey == ak)
	{
		LOGGER("New messageAdded()");

		Message m = m_ms->message(ak, mk);

		if ( m.isInbound() ) {
			emit messageReceived(m, ak, ck);
		}
	}
}


void MessageManager::messageUpdated(bb::pim::account::AccountKey ak, bb::pim::message::ConversationKey ck, bb::pim::message::MessageKey mk, bb::pim::message::MessageUpdate data)
{
	Q_UNUSED(data);

	LOGGER(ak << ck << mk);

	if (!m_accountKey || m_accountKey == ak)
	{
		Message m = getMessage(mk);

		if ( m.status().testFlag(MessageStatus::Sent) ) {
			emit messageSent(m, ak, ck);
		}
	}
}


Message MessageManager::getMessage(qint64 mk)
{
	LOGGER("fetch" << m_accountKey << mk);
	initService();
	return m_ms->message(m_accountKey, mk);
}


void MessageManager::setAccountKey(qint64 accountKey) {
	LOGGER("Setting account" << accountKey);
	m_accountKey = accountKey;
}


MessageManager::~MessageManager()
{
}

} /* namespace canadainc */
